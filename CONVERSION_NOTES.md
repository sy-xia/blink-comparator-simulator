# Conversion Notes — Blink Comparator Simulator

## Behavior model

The simulator presents a synthetic 400×300-pixel CCD image of a star field
(drawn at stage position 14, 62 in the original). The image is 16-bit data
(peak value 65535) built from Gaussian read noise (mean 2300, sigma 330)
generated once by a deterministic Park–Miller LCG (seed 1) using the
Marsaglia polar method; each *observation* re-shuffles that fixed noise in
280 chunks of 430 pixels using its own `noiseSeed`, so every observation has
its own — but perfectly reproducible — noise realization. Twenty-six stars
(21 constant, 4 pulsating variables driven by Fourier-series light curves,
1 eclipsing binary computed by solving Kepler's equation and the star-disc
overlap geometry) are stamped onto the field through a radius-5 Airy-disc
point-spread function; a star of magnitude 3 (the saturation magnitude)
saturates the detector. Counts map to grayscale through a gamma transfer
function (γ = 1.8). The user moves observations (epoch + noiseSeed pairs,
from `settings.xml`) from the *observations list* into the *blinking queue*,
steps through the queue with `<` / `>` or lets it *blink* automatically at a
rate-controlled interval of `50 + 950·(1 − log₁₀(rate))` ms per switch;
variable stars reveal themselves by changing brightness between epochs. A
crosshair readout shows the field pixel coordinates under the pointer.

## Source → HTML5 mapping

| Original (decompiled AS3) | HTML5 port |
| --- | --- |
| `MainTimeline.as` (controller, buttons, grids, blink loop) | `simulation.js` controller section: one `state` object + `render()` |
| `StarField.as` (noise/shuffle/PSF/bitmap pipeline) | `simulation.js` star-field engine: typed arrays + `ImageData`/`putImageData` |
| `Star.as`, `PulsatingStar.as`, `EclipsingBinary.as`, `AiryDisc.as`, `GammaTransferFunction.as` | `makeConstantStar`, `makePulsatingStar`, `makeEclipsingBinary`, `makeAiryDisc`, `grayTable` — all constants/formulas verbatim |
| `fl.controls.DataGrid` (epoch column, multi-select, sortable header, `HackedCellRenderer` icons/disabled rows) | Native `<select multiple>` list boxes + an "epoch" header button per list (numeric sort, ascending/descending toggle). `inUse` rows → `disabled` options; the displayed queue row shows a red ● marker |
| `fl.controls.Button` / `CheckBox` / `Slider` | Native `<button>`, `<input type="checkbox">`, `<input type="range" min="1" max="10" step="0.1" value="5">` |
| `Event.ENTER_FRAME` + `getTimer()` | `requestAnimationFrame` + `performance.now()`, same ms constants and elapsed-time step logic (`floor(elapsed/interval)` switches per frame) |
| Coordinates tooltip (`Coordinates_42`, shape 134) | Exported SVG reused as-is (`assets/crosshair-tooltip.svg`) with dynamic x/y text overlaid; labels typeset by MathJax |
| add/remove arrows (shape 144) | Exported SVG reused as-is (`assets/arrows.svg`) as decoration beside the add/remove buttons |
| `settings.xml` loaded by `URLLoader` at runtime | Data transcribed verbatim into `assets/settings-data.js` (loaded as a script — no runtime `fetch` beyond the masthead's `contents.json`). The original XML was **not in the decompiled folder**; it was recovered from the original deployment at `https://astro.unl.edu/naap/vsp/animations/settings.xml` and its epochs match the provided screenshot (`Capture.PNG`) exactly. The recovered file ships in `assets/settings.xml` for reference |

## Assets reused vs. code-drawn

* **Reused as-is:** `shapes/134.svg` → `assets/crosshair-tooltip.svg`
  (coordinate tooltip artwork); `shapes/144.svg` → `assets/arrows.svg`
  (add/remove direction arrows, shown via `background-position` so the single
  exported file serves both arrows).
* **Code-drawn (as in the original):** the star field itself is generated at
  runtime from noise + PSF math (in the original it was a
  `BitmapData.setPixels` buffer, here an `ImageData` on `<canvas>`); it has
  no exported asset by nature.
* **Not carried over (Flash chrome replaced by the KL-UNL shell, per the
  pipeline rules):** panel background/outline shapes (130, 148), text-field
  chrome (127), all `fl` component skins (buttons, scrollbars, grid
  renderers), and the embedded Verdana fonts — KL-UNL typography and panel
  styling are used instead.

## contents.json

`foundation/` was copied unchanged into `html5/foundation/` except for
`contents.json`:

1. The `blinkComparatorSimulator` entry (already present in the shared file)
   had its About text updated per instruction: the noncommercial-permission
   sentence was replaced with the Apache License 2.0 notice (Copyright 2026
   The Board of Regents of the University of Nebraska), the NSF funding
   sentence (grants #0231270 and/or #0404988) and the astro.unl.edu link were
   kept, and `meta.version` was set to "2.0 (Accessible HTML5)".
2. **Pre-existing JSON syntax repairs (flagged for review):** the shipped
   `contents.json` was not valid JSON, which made the browser's `JSON.parse`
   fail and broke the masthead for *every* simulation using the file. Two
   kinds of purely syntactic defects were repaired, with no wording changed:
   * unescaped quotes in two entries (`<a href="../venusphases">` and
     `<a href="../ptolemaic">`) — the quotes were escaped (`\"`);
   * five raw control characters (literal line breaks) inside string
     literals (e.g. in the `ce_hc` and `eclipsingbinarysim` help texts) —
     each was replaced with a single space.
   If contents.json is instead maintained as a single shared file upstream,
   these same fixes must be applied there or every masthead will fail to
   load its data.

## Deviations from the original

* **Presentation** follows the KL-UNL shell (Goal B) rather than the Flash
  pixel layout: KL-UNL palette/typography, `<kl-unl-masthead>` with
  Reset/Help/About, larger text, responsive columns. Panel structure,
  grouping, and reading order mirror the screenshot (`Capture.PNG`).
* **List boxes instead of DataGrids.** Native `<select multiple>` provides
  keyboard and screen-reader support a canvas/`div` grid cannot. Differences:
  observations already in use are `disabled` options and cannot be selected
  (in the original the grayed rows could still be clicked, but adding them
  was a no-op — net behavior identical); the sortable "epoch" column header
  is a separate button above each list; the red "displayed" dot is a text
  glyph (●) prefixed to the epoch rather than an icon.
* **Sorting edge case:** as in the original, sorting does not remap
  `displayedItemQueueIndex` or the stored `observationsIndex` values, so the
  quirky interactions of the Flash version (e.g. the displayed marker
  landing on whichever item now occupies the displayed index) reproduce.
  One subtle difference: the original only refreshed the row icons on the
  next `updateStarField()` call; this port re-renders immediately.
* **`removeFromQueue` selection anchor:** `fl` `selectedIndex` semantics with
  multi-selection are ambiguous in the decompiled code; this port uses the
  first (lowest) selected index as the anchor when restoring the selection
  after removal.
* **Crosshair:** the original tracked the mouse over the whole stage and
  hit-tested the field; this port listens on the field canvas itself (same
  visible behavior). A keyboard path was added (focus the field, arrow keys)
  because hover-only information fails WCAG; this is an accessibility
  addition, not a behavior change.
* **Blink is pausable and user-initiated** (the original "blink"/"stop"
  button is preserved); Reset comes from the masthead `sim-reset` event
  instead of a sim-local button (the original had no Reset at all — the
  masthead provides it per the pipeline).
* **MathJax:** the foundation folder contains no MathJax include, and no CDN
  may be used, so MathJax `tex-svg` is self-hosted in `assets/mathjax/` and
  wired through the foundation's `klunlShowEquation`/`klunlInitEqn`. The only
  mathematical symbols in this sim's UI are the crosshair coordinate labels
  *x* and *y*, which are MathJax-typeset (right-click opens the MathJax menu).
* **Trace-timing instrumentation** (`trace("update: ...")` etc.) dropped.
* **Cross-browser note:** styling of `<option>` elements (the red ● color)
  is not honored by every browser (e.g. iOS Safari renders its own list
  control); the ● glyph itself and the epoch readout still convey the
  displayed item everywhere.

## Number formatting

Epochs display exactly as the AS3 `Number`→`String` conversion produced them
(`String(epoch)` in JS is identical for all values in the data set, e.g.
`2.768`, `8.92456`). The coordinate readout shows truncated integer pixel
coordinates (`int()` cast in the original).
