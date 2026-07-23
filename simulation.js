/* Blink Comparator Simulator - accessible HTML5 port.
 *
 * Behavior is ported from the decompiled ActionScript 3 source of
 * blinkComparatorSimulator.swf:
 *   - blinkComparatorSimulator_fla/MainTimeline.as   (controller / UI wiring)
 *   - edu/unl/astro/starField/StarField.as           (noise + field pipeline)
 *   - edu/unl/astro/starField/Star.as                (constant star)
 *   - edu/unl/astro/starField/PulsatingStar.as       (Fourier-series variable)
 *   - edu/unl/astro/starField/EclipsingBinary.as     (Kepler-solved binary)
 *   - edu/unl/astro/starField/AiryDisc.as            (point-spread function)
 *   - edu/unl/astro/starField/GammaTransferFunction.as
 * All constants, tables and formulas are copied verbatim from that source.
 * Field data comes from assets/settings-data.js (SETTINGS), transcribed from
 * the original settings.xml.
 */

'use strict';

/* ===================================================================== */
/* Star field engine (port of edu.unl.astro.starField)                  */
/* ===================================================================== */

// MainTimeline.loadSettings(): starField.dimensions = {width:400, height:300}
const FIELD_W = 400;
const FIELD_H = 300;

// StarField constructor: bitDepth = 16  ->  peakValue = 2^16 - 1
const PEAK_VALUE = Math.pow(2, 16) - 1;

// GammaTransferFunction default: _gamma = 1.8 (not inverted, no highlight)
const GAMMA = 1.8;

// StarField.set dimensions:
//   _numChunks = 0.7 * _width;  _chunkSize = ceil(w*h/_numChunks), forced even
const NUM_CHUNKS = Math.trunc(0.7 * FIELD_W);                    // 280
let _chunk = Math.ceil(FIELD_W * FIELD_H / NUM_CHUNKS);          // 429
if (_chunk % 2 === 1) { _chunk += 1; }                           // 430
const CHUNK_SIZE = _chunk;
const NOISE_LEN = NUM_CHUNKS * CHUNK_SIZE;                       // 120400

const NOISE_MEAN  = SETTINGS.fieldParameters.noiseMean;          // 2300
const NOISE_SIGMA = SETTINGS.fieldParameters.noiseSigma;         // 330
const SATURATION_MAGNITUDE = SETTINGS.fieldParameters.saturationMagnitude; // 3
const PSF_RADIUS  = SETTINGS.fieldParameters.psfRadius;          // 5

/* GammaTransferFunction.refresh():
 *   grey = int(255 * (v / peakValue)^(1/gamma));  color = grey<<16|grey<<8|grey
 * updateHighlightingOfSaturatedPixels(): _normalTable[peakValue] = 0xFFFFFF
 * We store the grey byte; all three channels are equal. */
const grayTable = new Uint8Array(PEAK_VALUE + 1);
for (let v = 0; v <= PEAK_VALUE; v++) {
  grayTable[v] = Math.trunc(255 * Math.pow(v / PEAK_VALUE, 1 / GAMMA));
}
grayTable[PEAK_VALUE] = 255;

/* StarField.generateNoise(): Gaussian noise via the Marsaglia polar method
 * driven by a Park-Miller LCG (seed * 16807 % 2147483647) with a FIXED
 * starting seed of 1, so the base noise array is fully deterministic. */
const noiseData = new Float64Array(NOISE_LEN);
(function generateNoise() {
  let seed = 1;
  let i = 0;
  while (i < NOISE_LEN) {
    let u, v, s;
    do {
      u = 2 * (seed / 2147483647) - 1;
      seed = seed * 16807 % 2147483647;
      v = 2 * (seed / 2147483647) - 1;
      seed = seed * 16807 % 2147483647;
      s = u * u + v * v;
    } while (s >= 1);
    s = Math.sqrt(-2 * Math.log(s) / s);
    noiseData[i] = NOISE_MEAN + NOISE_SIGMA * u * s;
    i++;
    noiseData[i] = NOISE_MEAN + NOISE_SIGMA * v * s;
    i++;
  }
})();

/* StarField.generateNoisePixels(): clamp to [0, peakValue] (int cast first,
 * matching the AS int() truncation) and push through the transfer function. */
const noiseGray = new Uint8Array(NOISE_LEN);
for (let i = 0; i < NOISE_LEN; i++) {
  let v = Math.trunc(noiseData[i]);
  if (v < 0) { v = 0; } else if (v > PEAK_VALUE) { v = PEAK_VALUE; }
  noiseGray[i] = grayTable[v];
}

/* StarField.shuffleNoise(): Fisher-Yates-style chunk shuffle driven by the
 * same Park-Miller LCG, seeded with the observation's noiseSeed. */
const chunkTable = new Int32Array(NUM_CHUNKS);
function shuffleChunks(shuffleSeed) {
  let seed = shuffleSeed;
  for (let i = 0; i < NUM_CHUNKS; i++) { chunkTable[i] = i; }
  for (let i = 0; i < NUM_CHUNKS - 1; i++) {
    const j = i + Math.trunc((NUM_CHUNKS - i) * (seed / 2147483647));
    seed = seed * 16807 % 2147483647;
    const t = chunkTable[j];
    chunkTable[j] = chunkTable[i];
    chunkTable[i] = t;
  }
}

/* AiryDisc: PSF built from the first-order Bessel function J1.
 * intensity(r) = (2*J1(r)/r)^2, zeroed past the first minimum at
 * r = 3.831705970256774 (r^2 = 14.681970642501405). */
function airyGetJ1(x) {
  let ax, y, p1, p2, ans, z, xx;
  ax = Math.abs(x);
  if (ax < 8) {
    y = x * x;
    p1 = x * (72362614232 + y * (-7895059235 + y * (242396853.1 + y * (-2972611.439 + y * (15704.4826 + y * -30.16036606)))));
    p2 = 144725228442 + y * (2300535178 + y * (18583304.74 + y * (99447.43394 + y * (376.9991397 + y * 1))));
    ans = p1 / p2;
  } else {
    z = 8 / ax;
    y = z * z;
    xx = ax - 2.356194491;
    p1 = 1 + y * (0.00183105 + y * (-0.00003516396496 + y * (0.000002457520174 + y * -2.40337019e-7)));
    p2 = 0.04687499995 + y * (-0.0002002690873 + y * (0.000008449199096 + y * (-8.8228987e-7 + y * 1.05787412e-7)));
    ans = Math.sqrt(0.636619772 / ax) * (Math.cos(xx) * p1 - z * Math.sin(xx) * p2);
    if (x < 0) { ans = -ans; }
  }
  return ans;
}

function makeAiryDisc(radius) {
  const size = 2 * radius - 1;
  const center = radius - 1;
  const data = [];
  for (let i = 0; i < size; i++) { data[i] = []; }
  const k = 3.831705970256774 / radius;
  for (let i = 0; i < radius; i++) {
    const ri = k * i;
    for (let j = 0; j <= i; j++) {
      const rj = k * j;
      const r2 = ri * ri + rj * rj;
      let val;
      if (r2 >= 14.681970642501405) {
        val = 0;
      } else {
        const j1 = airyGetJ1(Math.sqrt(r2));
        val = 4 * j1 * j1 / r2;
      }
      data[center + i][center - j] = val;
      data[center + j][center - i] = val;
      data[center - j][center - i] = val;
      data[center - i][center - j] = val;
      data[center - i][center + j] = val;
      data[center - j][center + i] = val;
      data[center + j][center + i] = val;
      data[center + i][center + j] = val;
    }
  }
  data[center][center] = 1;
  return { data: data, width: size, height: size, x: center, y: center };
}

const PSF = makeAiryDisc(PSF_RADIUS);

/* ------------------------------------------------------------- stars --- */

/* PulsatingStar.PRESETS - copied verbatim from PulsatingStar.as.
 * magnitude(epoch) = centerMagnitude
 *                    + sum_i A_i * cos((i+1)*theta + phi_i),
 * theta = 2*pi*(epoch - phaseOffset)/period   (functionUsed is "cos" for
 * every preset; phaseOffset defaults to 0). */
const PULSATING_PRESETS = {
  del_Cep: {
    period: 5.366341, functionUsed: 'cos', actualCenterMagnitude: 3.988,
    fourierTermsList: [
      { A: 0.3496,   phi: 2.491 },
      { A: 0.1385,   phi: 3.084 },
      { A: 0.05499,  phi: 3.811 },
      { A: 0.02277,  phi: 4.083 },
      { A: 0.009765, phi: 4.709 }
    ]
  },
  RT_Mus: {
    period: 3.08617, functionUsed: 'cos', actualCenterMagnitude: 9.03,
    fourierTermsList: [
      { A: 0.331,  phi: 0.0277 },
      { A: 0.131,  phi: 4.13 },
      { A: 0.0503, phi: 2.24 },
      { A: 0.0416, phi: 6.16 }
    ]
  },
  AS_Per: {
    period: 4.972516, functionUsed: 'cos', actualCenterMagnitude: 9.76,
    fourierTermsList: [
      { A: 0.3583,  phi: 2.468 },
      { A: 0.1443,  phi: 3.084 },
      { A: 0.05731, phi: 3.65 },
      { A: 0.02603, phi: 3.695 },
      { A: 0.0211,  phi: 4.625 }
    ]
  },
  S_Nor: {
    period: 9.75411, functionUsed: 'cos', actualCenterMagnitude: 6.4354,
    fourierTermsList: [
      { A: 0.2874, phi: 3.1842 },
      { A: 0.0191, phi: 4.6142 },
      { A: 0.0296, phi: 2.7042 },
      { A: 0.0144, phi: 3.3482 },
      { A: 0.018,  phi: 3.0182 },
      { A: 0.0159, phi: 3.4322 }
    ]
  },
  PZ_Aql: {
    period: 8.7513, functionUsed: 'cos', actualCenterMagnitude: 11.7,
    fourierTermsList: [
      { A: 0.365,  phi: 4.66 },
      { A: 0.0459, phi: 1.75 },
      { A: 0.0208, phi: 2.76 },
      { A: 0.0188, phi: 5.98 }
    ]
  },
  MT_Tel: {
    period: 0.316897, functionUsed: 'cos', actualCenterMagnitude: 9.01,
    fourierTermsList: [
      { A: 0.26,    phi: 1.93 },
      { A: 0.0735,  phi: 1.89 },
      { A: 0.0166,  phi: 1.85 },
      { A: 0.01,    phi: 1.95 },
      { A: 0.0056,  phi: 1.35 },
      { A: 0.00489, phi: 1.48 },
      { A: 0.00453, phi: 1.62 },
      { A: 0.00151, phi: 1.11 }
    ]
  },
  RR_Leo: {
    period: 0.4523933, functionUsed: 'cos', actualCenterMagnitude: 10.83,
    fourierTermsList: [
      { A: 0.455,  phi: 0.691 },
      { A: 0.228,  phi: 5.16 },
      { A: 0.161,  phi: 3.69 },
      { A: 0.0991, phi: 2.33 },
      { A: 0.0779, phi: 1.02 },
      { A: 0.0491, phi: 5.81 },
      { A: 0.0327, phi: 4.45 },
      { A: 0.0314, phi: 2.97 }
    ]
  },
  VX_Her: {
    period: 0.45537282, functionUsed: 'cos', actualCenterMagnitude: 10.78,
    fourierTermsList: [
      { A: 0.458,  phi: 4.51 },
      { A: 0.212,  phi: 0.261 },
      { A: 0.164,  phi: 2.56 },
      { A: 0.106,  phi: 4.96 },
      { A: 0.0733, phi: 1.07 },
      { A: 0.0592, phi: 3.57 },
      { A: 0.0362, phi: 6.07 },
      { A: 0.027,  phi: 2.2 }
    ]
  }
};

/* EclipsingBinary.PRESETS - copied verbatim from EclipsingBinary.as. */
const SOLAR_MASS = 1.98892e+30;
const SOLAR_RADIUS = 695500000;
const ECLIPSING_PRESETS = {
  TW_Cas:   { argument: 0,     inclination: 74.7,   eccentricity: 0,    separation: 8.17,  mass1: 2.5,  radius1: 2,   temperature1: 10500, mass2: 1.1,  radius2: 2.6, temperature2: 5400 },
  AG_Phi:   { argument: 0,     inclination: 87.624, eccentricity: 0,    separation: 4.22,  mass1: 1.53, radius1: 1.7, temperature1: 7500,  mass2: 0.24, radius2: 1,   temperature2: 5400 },
  V477_Cyg: { argument: 162.8, inclination: 85.66,  eccentricity: 0.33, separation: 10.87, mass1: 1.9,  radius1: 1.7, temperature1: 8730,  mass2: 1.4,  radius2: 1.5, temperature2: 6530 },
  CW_CMa:   { argument: 0,     inclination: 83.3,   eccentricity: 0,    separation: 11.92, mass1: 2.6,  radius1: 2.1, temperature1: 10800, mass2: 2.5,  radius2: 1.9, temperature2: 10300 },
  EK_Cep:   { argument: 49.8,  inclination: 89.16,  eccentricity: 0.11, separation: 16.58, mass1: 2,    radius1: 1.6, temperature1: 9000,  mass2: 1.1,  radius2: 1.3, temperature2: 5690 },
  V526_Sgr: { argument: 254.8, inclination: 87.3,   eccentricity: 0.22, separation: 10.43, mass1: 2.4,  radius1: 1.9, temperature1: 10100, mass2: 1.8,  radius2: 1.6, temperature2: 8450 },
  T_LMi:    { argument: 0,     inclination: 86.3,   eccentricity: 0,    separation: 11.97, mass1: 2.3,  radius1: 1.9, temperature1: 9860,  mass2: 0.23, radius2: 2.4, temperature2: 5060 }
};

function makeConstantStar(cfg) {
  return { x: cfg.x, y: cfg.y, magnitude: function () { return cfg.magnitude; } };
}

function makePulsatingStar(cfg) {
  const preset = PULSATING_PRESETS[cfg.prototypeName];
  const centerMagnitude = cfg.centerMagnitude;
  const phaseOffset = 0;
  const period = preset.period;
  const terms = preset.fourierTermsList;
  const fn = Math[preset.functionUsed];
  return {
    x: cfg.x, y: cfg.y,
    magnitude: function (epoch) {
      const theta = 2 * Math.PI * (epoch - phaseOffset) / period;
      let mag = centerMagnitude;
      for (let i = 0; i < terms.length; i++) {
        mag += terms[i].A * fn((i + 1) * theta + terms[i].phi);
      }
      return mag;
    }
  };
}

function makeEclipsingBinary(cfg) {
  const p = ECLIPSING_PRESETS[cfg.prototypeName];
  // Setters convert to SI (radii/separation * SOLAR_RADIUS, masses * SOLAR_MASS,
  // angles to radians), exactly as in EclipsingBinary.as.
  const argument = p.argument * (Math.PI / 180);
  const inclination = p.inclination * (Math.PI / 180);
  const eccentricity = p.eccentricity;
  const separation = p.separation * SOLAR_RADIUS;
  const mass1 = p.mass1 * SOLAR_MASS;
  const mass2 = p.mass2 * SOLAR_MASS;
  const radius1 = p.radius1 * SOLAR_RADIUS;
  const radius2 = p.radius2 * SOLAR_RADIUS;
  const temperature1 = p.temperature1;
  const temperature2 = p.temperature2;
  const peakMagnitude = cfg.peakMagnitude;
  const phaseOffset = 0;

  // EclipsingBinary.getBolometricCorrection(): piecewise 5th-order polynomial
  // in log10(T).
  function getBolometricCorrection(temp) {
    const logT = Math.log(temp) / Math.LN10;
    let c;
    if (logT > 3.9) {
      c = { a: -100139.4991, b: 116264.1842, c: -53931.97541, d: 12495.04227, e: -1445.868048, f: 66.84924471 };
    } else if (logT < 3.7) {
      c = { a: -13884.14899, b: 8595.127427, c: -488.3425525, d: -627.0092238, e: 137.4608131, f: -7.549572042 };
    } else {
      c = { a: 1439.981506, b: -151.9002581, c: -995.1089203, d: 582.5176671, e: -123.3293641, f: 9.160761128 };
    }
    return c.a + logT * (c.b + logT * (c.c + logT * (c.d + logT * (c.e + c.f * logT))));
  }

  // EclipsingBinary.calculateConstants()
  const C1 = Math.sqrt((1 + eccentricity) / (1 - eccentricity));
  const cosI = Math.cos(inclination);
  const l = separation * (1 - eccentricity * eccentricity);
  const J1c = l * l * (1 - cosI * cosI);
  const J2c = l * l * cosI * cosI;
  const J3c = 2 * eccentricity;
  const J4c = eccentricity * eccentricity;
  const R12 = radius1 * radius1;
  const R22 = radius2 * radius2;
  const Z0 = 1 / (2 * radius2);
  const Z1 = (R22 - R12) * Z0;
  const Z2 = 1 / (2 * radius1);
  const Z3 = (R12 - R22) * Z2;
  const bc1 = getBolometricCorrection(temperature1);
  const bc2 = getBolometricCorrection(temperature2);
  const H1 = 1.89553328524593e-43 * Math.pow(temperature1, 4) * Math.pow(10, bc1 / 2.5);
  const H2 = 1.89553328524593e-43 * Math.pow(temperature2, 4) * Math.pow(10, bc2 / 2.5);
  const maxVisFlux = (R12 * H1 + R22 * H2) * Math.PI;
  const minVisMag = -18.9669559998301 - 2.5 / Math.LN10 * Math.log(maxVisFlux);
  // P = sqrt(4 pi^2 a^3 / (G (m1 + m2))) / 86400  [days], G = 6.673e-11
  const period = Math.sqrt(4 * Math.PI * Math.PI * separation * separation * separation / (6.673e-11 * (mass1 + mass2))) / (24 * 60 * 60);
  const distanceModulus = peakMagnitude - minVisMag;

  return {
    x: cfg.x, y: cfg.y,
    // EclipsingBinary.get magnitude(): solve Kepler's equation for the
    // eccentric anomaly, get the projected star-disc overlap, subtract the
    // eclipsed flux, convert back to a visual magnitude.
    magnitude: function (epoch) {
      const M = 2 * Math.PI * (epoch - phaseOffset) / period;
      let Eprev = 0;
      let E = M;
      let iter = 0;
      do {
        Eprev = E;
        E = Eprev + (M + eccentricity * Math.sin(Eprev) - Eprev) / (1 - eccentricity * Math.cos(Eprev));
        iter++;
      } while (Math.abs(E - Eprev) > 0.001 && iter < 100);
      if (iter >= 100) {
        throw new Error('iteration limit reached in EclipsingBinary, maybe eccentricity is too high');
      }
      const nu = 2 * Math.atan(C1 * Math.tan(E / 2));
      const cosNu = Math.cos(nu);
      const cosNuArg = Math.cos(nu + argument);
      let rho = Math.sqrt((J1c * cosNuArg * cosNuArg + J2c) / (1 + J3c * cosNu + J4c * cosNu * cosNu));
      if (rho === 0) { rho = 1e-8; }
      let c1 = Z0 * rho + Z1 / rho;
      let c2 = Z2 * rho + Z3 / rho;
      if (c1 < -1) { c1 = -1; } else if (c1 > 1) { c1 = 1; }
      if (c2 < -1) { c2 = -1; } else if (c2 > 1) { c2 = 1; }
      const th1 = Math.acos(c1);
      const th2 = Math.acos(c2);
      const overlap = R22 * (th1 - c1 * Math.sin(th1)) + R12 * (th2 - c2 * Math.sin(th2));
      const star1InFront = ((nu + argument) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI) < Math.PI;
      const flux = star1InFront ? maxVisFlux - H1 * overlap : maxVisFlux - H2 * overlap;
      const mag = -18.9669559998301 - 2.5 / Math.LN10 * Math.log(flux);
      return distanceModulus + mag;
    }
  };
}

const stars = SETTINGS.starsList.map(function (cfg) {
  switch (cfg.type) {
    case 'constantStar':    return makeConstantStar(cfg);
    case 'pulsatingStar':   return makePulsatingStar(cfg);
    case 'eclipsingBinary': return makeEclipsingBinary(cfg);
  }
});

/* StarField.update(): compose the field for one observation.
 * Base pixels use the shuffled noise; every star then adds
 * peakValue * 10^((saturationMagnitude - m)/2.5) scaled by the PSF. */
const fieldData = new Float64Array(NOISE_LEN);
let imageData = null;   // created once the canvas context exists

function composeField(epoch, noiseSeed) {
  shuffleChunks(noiseSeed);
  const d = imageData.data;
  const nPix = FIELD_W * FIELD_H;
  for (let idx = 0; idx < nPix; idx++) {
    const chunk = (idx / CHUNK_SIZE) | 0;
    const src = (idx - chunk * CHUNK_SIZE) + CHUNK_SIZE * chunkTable[chunk];
    const g = noiseGray[src];
    const o = 4 * idx;
    d[o] = g; d[o + 1] = g; d[o + 2] = g; d[o + 3] = 255;
  }
  fieldData.set(noiseData);
  for (let s = 0; s < stars.length; s++) {
    const star = stars[s];
    const coef = PEAK_VALUE * Math.pow(10, (SATURATION_MAGNITUDE - star.magnitude(epoch)) / 2.5);
    const x0 = star.x - PSF.x;
    const y0 = star.y - PSF.y;
    for (let i = 0; i < PSF.width; i++) {
      const px = x0 + i;
      if (px < 0) { continue; }
      if (px >= FIELD_W) { break; }
      const col = PSF.data[i];
      for (let j = 0; j < PSF.height; j++) {
        const py = y0 + j;
        const val = col[j];
        if (val <= 0 || py < 0) { continue; }
        if (py >= FIELD_H) { break; }
        const idx = px + py * FIELD_W;
        const chunk = (idx / CHUNK_SIZE) | 0;
        const src = (idx - chunk * CHUNK_SIZE) + CHUNK_SIZE * chunkTable[chunk];
        let v = fieldData[src] = fieldData[src] + coef * val;
        if (v < 0) { v = 0; } else if (v > PEAK_VALUE) { v = PEAK_VALUE; }
        const g = grayTable[Math.trunc(v)];
        const o = 4 * idx;
        d[o] = g; d[o + 1] = g; d[o + 2] = g;
      }
    }
  }
}

/* ===================================================================== */
/* Controller (port of MainTimeline)                                    */
/* ===================================================================== */

// One plain state object; render() redraws everything from it.
const state = {
  observations: [],          // {epoch, noiseSeed, inUse, id}
  queue: [],                 // {epoch, noiseSeed, observationsIndex, id}
  displayedItemQueueIndex: -1,
  animating: false,
  lastSwitchInstant: 0,
  rate: 5,                   // speedSlider: min 1, max 10, snap 0.1, value 5
  showCrosshairs: true,      // checkbox default selected
  obsSortAscending: null,    // null until the header is first clicked
  queueSortAscending: null,
  crosshair: { x: 200, y: 150, visible: false },
  keyboardCrosshair: false
};
let queueIdCounter = 0;

function initialObservations() {
  return SETTINGS.observationsList.map(function (o, i) {
    return { epoch: o.epoch, noiseSeed: o.noiseSeed, inUse: false, id: i };
  });
}

// --- DOM handles -------------------------------------------------------
let els = null;
let ctx = null;
let rafId = null;
let lastComposedKey = null;

function $(id) { return document.getElementById(id); }

function announce(text) {
  els.liveRegion.textContent = text;
}

/* MainTimeline.onEnterFrameFunc(): interval between switches is
 *   50 + (1000 - 50) * (1 - log10(rate))   milliseconds.               */
function switchInterval() {
  const min = 50;
  const max = 1000;
  return min + (max - min) * (1 - Math.log(state.rate) / Math.LN10);
}

function animationFrame() {
  rafId = requestAnimationFrame(animationFrame);
  const elapsed = performance.now() - state.lastSwitchInstant;
  const interval = switchInterval();
  const steps = Math.floor(elapsed / interval);
  if (steps === 0) { return; }
  state.displayedItemQueueIndex = (state.displayedItemQueueIndex + steps) % state.queue.length;
  state.lastSwitchInstant += interval * steps;
  render();
}

function startAnimating() {
  state.lastSwitchInstant = performance.now();
  state.animating = true;
  rafId = requestAnimationFrame(animationFrame);
  render();
  announce('Blinking started at rate ' + state.rate + ' of 10. Activate the stop button to stop.');
}

function stopAnimating() {
  if (rafId !== null) { cancelAnimationFrame(rafId); rafId = null; }
  state.animating = false;
  render();
  announce('Blinking stopped. ' + displayedStatusText());
}

function toggleAnimation() {
  if (state.animating) { stopAnimating(); } else { startAnimating(); }
}

function displayedStatusText() {
  if (state.displayedItemQueueIndex < 0 || state.queue.length === 0) {
    return 'The blinking queue is empty; no observation is displayed.';
  }
  const item = state.queue[state.displayedItemQueueIndex];
  return 'Epoch ' + item.epoch + ' displayed, item ' +
    (state.displayedItemQueueIndex + 1) + ' of ' + state.queue.length + ' in the queue.';
}

// --- selection helpers (native multi-select boxes) ---------------------

function selectedIds(selectEl) {
  const ids = [];
  for (let i = 0; i < selectEl.options.length; i++) {
    if (selectEl.options[i].selected) { ids.push(selectEl.options[i].value); }
  }
  return ids;
}

/* MainTimeline.addToQueue(): copy every selected, not-in-use observation
 * into the queue, mark it in use, select the last one added, display the
 * last queue item, then clear the observations selection. */
function addToQueue() {
  const selIds = selectedIds(els.observationsList);
  if (selIds.length === 0) { return; }
  let lastAdded = null;
  let added = 0;
  for (let k = 0; k < selIds.length; k++) {
    const index = state.observations.findIndex(function (o) { return String(o.id) === selIds[k]; });
    const obs = state.observations[index];
    if (!obs.inUse) {
      lastAdded = {
        epoch: obs.epoch,
        noiseSeed: obs.noiseSeed,
        observationsIndex: index,   // index at add time, as in the original
        id: 'q' + (queueIdCounter++)
      };
      state.queue.push(lastAdded);
      obs.inUse = true;
      added++;
    }
  }
  state.displayedItemQueueIndex = state.queue.length - 1;
  render();
  // reproduce: queue selection = last added item, observations cleared
  clearSelection(els.observationsList);
  clearSelection(els.queueList);
  if (lastAdded !== null) {
    setSelectedById(els.queueList, lastAdded.id);
  }
  scrollToIndex(els.queueList, state.displayedItemQueueIndex);
  updateButtonStates();
  announce('Added ' + added + (added === 1 ? ' observation' : ' observations') +
    ' to the blinking queue. ' + displayedStatusText());
}

/* MainTimeline.removeFromQueue(): remove all selected queue items, free
 * their observations, restore a sensible selection, keep the displayed
 * item if it survived (otherwise fall back to the selection), and stop
 * blinking when fewer than two items remain. */
function removeFromQueue() {
  const selIds = selectedIds(els.queueList);
  if (selIds.length === 0) { return; }
  const displayedItem =
    (state.displayedItemQueueIndex >= 0 && state.displayedItemQueueIndex < state.queue.length)
      ? state.queue[state.displayedItemQueueIndex] : null;
  const oldSelectedIndex = firstSelectedIndex(els.queueList);
  let removed = 0;
  for (let k = 0; k < selIds.length; k++) {
    const idx = state.queue.findIndex(function (q) { return q.id === selIds[k]; });
    if (idx === -1) { continue; }
    const item = state.queue[idx];
    state.queue.splice(idx, 1);
    const obs = state.observations[item.observationsIndex];
    if (obs) { obs.inUse = false; }
    removed++;
  }
  let newSelectedIndex;
  if (oldSelectedIndex >= state.queue.length || (oldSelectedIndex === -1 && state.queue.length > 0)) {
    newSelectedIndex = state.queue.length - 1;
  } else {
    newSelectedIndex = oldSelectedIndex;
  }
  state.displayedItemQueueIndex = displayedItem === null ? -1 : state.queue.indexOf(displayedItem);
  if (state.displayedItemQueueIndex === -1) {
    state.displayedItemQueueIndex = newSelectedIndex;
  }
  if (state.queue.length <= 1 && state.animating) {
    stopAnimating();
  }
  render();
  clearSelection(els.queueList);
  if (newSelectedIndex >= 0 && newSelectedIndex < els.queueList.options.length) {
    els.queueList.options[newSelectedIndex].selected = true;
  }
  updateButtonStates();
  announce('Removed ' + removed + (removed === 1 ? ' observation' : ' observations') +
    ' from the blinking queue. ' + displayedStatusText());
}

function goForwardInQueue() {
  if (state.queue.length > 0) {
    state.displayedItemQueueIndex = (state.displayedItemQueueIndex + 1) % state.queue.length;
    render();
    announce(displayedStatusText());
  }
}

function goBackInQueue() {
  if (state.queue.length > 0) {
    state.displayedItemQueueIndex =
      (state.displayedItemQueueIndex + state.queue.length - 1) % state.queue.length;
    render();
    announce(displayedStatusText());
  }
}

/* fl.controls.DataGrid header behavior: clicking the "epoch" column sorts
 * numerically, toggling between ascending and descending. As in the
 * original, sorting does NOT remap displayedItemQueueIndex or the stored
 * observationsIndex values. */
function sortObservations() {
  state.obsSortAscending = state.obsSortAscending === true ? false : true;
  const dir = state.obsSortAscending ? 1 : -1;
  state.observations.sort(function (a, b) { return dir * (a.epoch - b.epoch); });
  render();
  updateButtonStates();
  announce('Observations list sorted by epoch, ' +
    (state.obsSortAscending ? 'ascending.' : 'descending.'));
}

function sortQueue() {
  state.queueSortAscending = state.queueSortAscending === true ? false : true;
  const dir = state.queueSortAscending ? 1 : -1;
  state.queue.sort(function (a, b) { return dir * (a.epoch - b.epoch); });
  render();
  updateButtonStates();
  announce('Blinking queue sorted by epoch, ' +
    (state.queueSortAscending ? 'ascending.' : 'descending.') + ' ' + displayedStatusText());
}

function firstSelectedIndex(selectEl) {
  for (let i = 0; i < selectEl.options.length; i++) {
    if (selectEl.options[i].selected) { return i; }
  }
  return -1;
}

function clearSelection(selectEl) {
  for (let i = 0; i < selectEl.options.length; i++) {
    selectEl.options[i].selected = false;
  }
}

function setSelectedById(selectEl, id) {
  for (let i = 0; i < selectEl.options.length; i++) {
    if (selectEl.options[i].value === String(id)) {
      selectEl.options[i].selected = true;
      return;
    }
  }
}

function scrollToIndex(selectEl, index) {
  if (index >= 0 && index < selectEl.options.length) {
    const opt = selectEl.options[index];
    if (typeof opt.scrollIntoView === 'function') {
      opt.scrollIntoView({ block: 'nearest' });
    }
  }
}

/* MainTimeline.updateButtonStates() */
function updateButtonStates() {
  els.addButton.disabled = selectedIds(els.observationsList).length === 0;
  els.removeButton.disabled = selectedIds(els.queueList).length === 0;
  const few = state.queue.length <= 1;
  els.forwardButton.disabled = few;
  els.backButton.disabled = few;
  els.playButton.disabled = few;
}

// --- rendering ---------------------------------------------------------

function syncListOptions() {
  // observations list: options are stable per observation id; rebuild in
  // current (possibly sorted) order while preserving selection.
  const obsSel = new Set(selectedIds(els.observationsList));
  els.observationsList.innerHTML = '';
  state.observations.forEach(function (obs) {
    const opt = document.createElement('option');
    opt.value = String(obs.id);
    opt.textContent = String(obs.epoch);
    opt.disabled = obs.inUse;               // HackedCellRenderer: enabled = !inUse
    if (obsSel.has(obs.id)) { opt.selected = true; }
    els.observationsList.appendChild(opt);
  });

  const queueSel = new Set(selectedIds(els.queueList).map(String));
  els.queueList.innerHTML = '';
  state.queue.forEach(function (item, i) {
    const opt = document.createElement('option');
    opt.value = String(item.id);
    const displayed = i === state.displayedItemQueueIndex;
    // red dot marks the displayed item (glyph + color, never color alone)
    opt.textContent = (displayed ? '● ' : '') + String(item.epoch);
    if (displayed) {
      opt.className = 'bcs-option--displayed';
      opt.setAttribute('aria-label', 'epoch ' + item.epoch + ', currently displayed');
    }
    if (queueSel.has(String(item.id))) { opt.selected = true; }
    els.queueList.appendChild(opt);
  });

  els.obsSortArrow.textContent =
    state.obsSortAscending === null ? '' : (state.obsSortAscending ? '▲' : '▼');
  els.queueSortArrow.textContent =
    state.queueSortAscending === null ? '' : (state.queueSortAscending ? '▲' : '▼');
}

/* MainTimeline.updateStarField(), reformulated as a single render() from
 * state: canvas, epoch readout, queue markers and the screen-reader
 * description all update together. */
function render() {
  if (state.displayedItemQueueIndex >= state.queue.length) {
    state.displayedItemQueueIndex = state.queue.length - 1;
  }
  const hasDisplay = state.displayedItemQueueIndex >= 0 && state.queue.length > 0;

  if (!hasDisplay) {
    els.stage.classList.add('bcs-stage--empty');
    els.epochField.textContent = '...';
    els.canvasDesc.textContent =
      'The blinking queue is empty, so no star field image is shown. ' +
      'Add observations from the observations list to display the field.';
    lastComposedKey = null;
  } else {
    els.stage.classList.remove('bcs-stage--empty');
    const item = state.queue[state.displayedItemQueueIndex];
    const key = item.epoch + '/' + item.noiseSeed;
    if (key !== lastComposedKey) {
      composeField(item.epoch, item.noiseSeed);
      ctx.putImageData(imageData, 0, 0);
      lastComposedKey = key;
    }
    els.epochField.textContent = String(item.epoch);
    els.canvasDesc.textContent =
      'Star field image, 400 by 300 pixels, showing the observation at epoch ' +
      item.epoch + ', item ' + (state.displayedItemQueueIndex + 1) + ' of ' +
      state.queue.length + ' in the blinking queue. Grey stars on a dark noisy ' +
      'background; blinking between observations makes the variable stars ' +
      'appear to change brightness.';
  }

  els.playButton.textContent = state.animating ? 'stop' : 'blink';
  syncListOptions();
  positionCrosshair();
}

// --- crosshair (pointer + keyboard) ------------------------------------

/* MainTimeline.onMouseMoveOverStage(): clamp to the field, show the
 * coordinate tooltip at the pointer position. */
function fieldCoordsFromPointer(event) {
  const rect = els.canvas.getBoundingClientRect();
  let x = Math.trunc((event.clientX - rect.left) * FIELD_W / rect.width);
  let y = Math.trunc((event.clientY - rect.top) * FIELD_H / rect.height);
  if (x < 0) { x = 0; } else if (x >= FIELD_W) { x = FIELD_W - 1; }
  if (y < 0) { y = 0; } else if (y >= FIELD_H) { y = FIELD_H - 1; }
  return { x: x, y: y };
}

function positionCrosshair() {
  const hasDisplay = state.displayedItemQueueIndex >= 0 && state.queue.length > 0;
  const show = state.showCrosshairs && hasDisplay && state.crosshair.visible;
  els.crosshair.hidden = !show;
  if (!show) { return; }
  const rect = els.canvas.getBoundingClientRect();
  const stageRect = els.stage.getBoundingClientRect();
  const left = rect.left - stageRect.left + (state.crosshair.x + 0.5) * rect.width / FIELD_W;
  const top = rect.top - stageRect.top + (state.crosshair.y + 0.5) * rect.height / FIELD_H;
  els.crosshair.style.left = left + 'px';
  els.crosshair.style.top = top + 'px';
  els.crosshairX.textContent = String(state.crosshair.x);
  els.crosshairY.textContent = String(state.crosshair.y);
}

function onPointerMoveOverCanvas(event) {
  const hasDisplay = state.displayedItemQueueIndex >= 0 && state.queue.length > 0;
  if (!state.showCrosshairs || !hasDisplay) {
    state.crosshair.visible = false;
    positionCrosshair();
    return;
  }
  const c = fieldCoordsFromPointer(event);
  state.crosshair.x = c.x;
  state.crosshair.y = c.y;
  state.crosshair.visible = true;
  positionCrosshair();
}

function onPointerLeaveCanvas() {
  if (!state.keyboardCrosshair) {
    state.crosshair.visible = false;
    positionCrosshair();
  }
}

function announceCrosshair() {
  announce('Crosshair at pixel x ' + state.crosshair.x + ', pixel y ' + state.crosshair.y + '.');
}

function onCanvasKeyDown(event) {
  const hasDisplay = state.displayedItemQueueIndex >= 0 && state.queue.length > 0;
  if (!hasDisplay) { return; }
  const step = event.shiftKey ? 10 : 1;
  let dx = 0;
  let dy = 0;
  switch (event.key) {
    case 'ArrowLeft':  dx = -step; break;
    case 'ArrowRight': dx = step;  break;
    case 'ArrowUp':    dy = -step; break;
    case 'ArrowDown':  dy = step;  break;
    case 'Home': state.crosshair.x = 0; break;
    case 'End':  state.crosshair.x = FIELD_W - 1; break;
    default: return;
  }
  event.preventDefault();
  state.keyboardCrosshair = true;
  let x = state.crosshair.x + dx;
  let y = state.crosshair.y + dy;
  if (x < 0) { x = 0; } else if (x >= FIELD_W) { x = FIELD_W - 1; }
  if (y < 0) { y = 0; } else if (y >= FIELD_H) { y = FIELD_H - 1; }
  state.crosshair.x = x;
  state.crosshair.y = y;
  state.crosshair.visible = state.showCrosshairs;
  positionCrosshair();
  announceCrosshair();
}

// --- reset -------------------------------------------------------------

/* Restore the exact initial state (MainTimeline.frame1 + loadSettings):
 * empty queue, all observations available, first observation selected,
 * rate 5, crosshairs on, nothing displayed, not animating. */
function resetSimulation() {
  if (state.animating) {
    if (rafId !== null) { cancelAnimationFrame(rafId); rafId = null; }
    state.animating = false;
  }
  state.observations = initialObservations();
  state.queue = [];
  state.displayedItemQueueIndex = -1;
  state.rate = 5;
  state.showCrosshairs = true;
  state.obsSortAscending = null;
  state.queueSortAscending = null;
  state.crosshair = { x: 200, y: 150, visible: false };
  state.keyboardCrosshair = false;
  els.speedSlider.value = '5';
  updateRateValuetext();
  els.showCrosshairs.checked = true;
  render();
  clearSelection(els.queueList);
  clearSelection(els.observationsList);
  if (els.observationsList.options.length > 0) {
    // loadSettings(): observationsDataGrid.selectedIndex = 0
    els.observationsList.options[0].selected = true;
  }
  updateButtonStates();
  announce('Simulation reset. The blinking queue is empty and all observations are available.');
}

// --- equations / MathJax ----------------------------------------------

function updateRateValuetext() {
  els.speedSlider.setAttribute('aria-valuetext', 'blink rate ' + state.rate + ' of 10');
}

/* Redefine the foundation's klunlInitEqn (kl-unl.js) to typeset the
 * mathematical symbols this sim displays: the crosshair coordinate labels
 * x and y. Every math symbol is MathJax-typeset so right-clicking it opens
 * the MathJax contextual menu. */
function klunlInitEqn() {
  klunlShowEquation(
    ['bcsCrosshairXLabel', '\\(x\\):'],
    ['bcsEqnMsg', 'The crosshair readout shows the pixel coordinates x and y of the pointer position on the star field image.']
  );
  klunlShowEquation(['bcsCrosshairYLabel', '\\(y\\):']);
  // Display-only math must not join the tab order (some MathJax configs make
  // output focusable); keep it readable but not tabbable.
  if (window.MathJax && MathJax.startup && MathJax.startup.promise) {
    MathJax.startup.promise.then(function () {
      document.querySelectorAll('mjx-container').forEach(function (el) {
        el.setAttribute('tabindex', '-1');
      });
    });
  }
}

// --- boot --------------------------------------------------------------

function init() {
  els = {
    stage: $('bcsStage'),
    canvas: $('bcsFieldCanvas'),
    queueEmpty: $('bcsQueueEmpty'),
    crosshair: $('bcsCrosshair'),
    crosshairX: $('bcsCrosshairXValue'),
    crosshairY: $('bcsCrosshairYValue'),
    epochField: $('bcsEpochField'),
    showCrosshairs: $('bcsShowCrosshairs'),
    observationsList: $('bcsObservationsList'),
    queueList: $('bcsQueueList'),
    obsSort: $('bcsObsSort'),
    queueSort: $('bcsQueueSort'),
    obsSortArrow: $('bcsObsSortArrow'),
    queueSortArrow: $('bcsQueueSortArrow'),
    addButton: $('bcsAddButton'),
    removeButton: $('bcsRemoveButton'),
    backButton: $('bcsBackButton'),
    forwardButton: $('bcsForwardButton'),
    playButton: $('bcsPlayButton'),
    speedSlider: $('bcsSpeedSlider'),
    liveRegion: $('bcsLiveRegion'),
    canvasDesc: $('bcsCanvasDesc')
  };

  ctx = els.canvas.getContext('2d');
  imageData = ctx.createImageData(FIELD_W, FIELD_H);

  state.observations = initialObservations();

  // wiring (MainTimeline.frame1)
  els.addButton.addEventListener('click', addToQueue);
  els.removeButton.addEventListener('click', removeFromQueue);
  els.backButton.addEventListener('click', goBackInQueue);
  els.forwardButton.addEventListener('click', goForwardInQueue);
  els.playButton.addEventListener('click', toggleAnimation);
  els.obsSort.addEventListener('click', sortObservations);
  els.queueSort.addEventListener('click', sortQueue);

  els.observationsList.addEventListener('change', updateButtonStates);
  els.queueList.addEventListener('change', updateButtonStates);

  // ITEM_DOUBLE_CLICK equivalents, plus keyboard (Enter) parity
  els.observationsList.addEventListener('dblclick', addToQueue);
  els.observationsList.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') { e.preventDefault(); addToQueue(); }
  });
  function displaySelectedQueueItem() {
    const idx = firstSelectedIndex(els.queueList);
    if (idx >= 0) {
      state.displayedItemQueueIndex = idx;
      render();
      announce(displayedStatusText());
    }
  }
  els.queueList.addEventListener('dblclick', displaySelectedQueueItem);
  els.queueList.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') { e.preventDefault(); displaySelectedQueueItem(); }
  });

  // rate slider: liveDragging = true in the original
  els.speedSlider.addEventListener('input', function () {
    state.rate = Number(els.speedSlider.value);
    updateRateValuetext();
  });
  els.speedSlider.addEventListener('change', function () {
    announce('Blink rate ' + state.rate + ' of 10. One switch every ' +
      Math.round(switchInterval()) + ' milliseconds.');
  });

  // crosshair checkbox (onShowCrosshairsToggled)
  els.showCrosshairs.addEventListener('change', function () {
    state.showCrosshairs = els.showCrosshairs.checked;
    if (!state.showCrosshairs) { state.crosshair.visible = false; }
    positionCrosshair();
    announce(state.showCrosshairs ? 'Crosshairs on.' : 'Crosshairs off.');
  });

  // pointer + keyboard crosshair on the canvas
  els.canvas.addEventListener('pointermove', onPointerMoveOverCanvas);
  els.canvas.addEventListener('pointerdown', function (event) {
    els.canvas.focus();
    onPointerMoveOverCanvas(event);
  });
  els.canvas.addEventListener('pointerleave', onPointerLeaveCanvas);
  els.canvas.addEventListener('keydown', onCanvasKeyDown);
  els.canvas.addEventListener('blur', function () {
    state.keyboardCrosshair = false;
    state.crosshair.visible = false;
    positionCrosshair();
  });
  window.addEventListener('resize', positionCrosshair);

  // masthead Reset
  document.addEventListener('sim-reset', resetSimulation);

  render();
  if (els.observationsList.options.length > 0) {
    els.observationsList.options[0].selected = true;  // loadSettings()
  }
  updateButtonStates();
  updateRateValuetext();

  // typeset math once MathJax is ready (fallback to plain text if absent)
  if (window.MathJax && MathJax.startup && MathJax.startup.promise) {
    MathJax.startup.promise.then(function () { klunlInitEqn(); });
  } else if (typeof klunlShowEquation === 'function') {
    klunlInitEqn();
  } else {
    $('bcsCrosshairXLabel').textContent = 'x:';
    $('bcsCrosshairYLabel').textContent = 'y:';
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
