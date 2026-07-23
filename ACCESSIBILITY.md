# Accessibility Notes — Blink Comparator Simulator

Target: WCAG 2.1 AA (ADA Title II). Human screen-reader QA (NVDA on
Windows/Chrome+Firefox and VoiceOver on macOS/Chrome+Safari) is still
required before release — the notes below describe what was built and the
intended announcements.

## Structure and semantics

* One `<h1>` (rendered by `<kl-unl-masthead>`); the two panels are
  `<section>`s with `<h2 class="panel__heading">` ("Blink Comparator",
  "Blinking Queue Controls") inside `<main>`.
* `<html lang="en">`.
* Every control is a native element with a real label:
  * `observations list:` / `blinking queue:` — `<label>`ed
    `<select multiple>` list boxes with `aria-describedby` usage hints.
  * `add` / `remove` / `<` / `blink` / `>` — `<button>`s; the arrow buttons
    carry clarifying `aria-label`s ("show the previous/next observation in
    the queue"); add/remove aria-labels start with their visible text.
  * `rate:` — a native `<input type="range">` (min 1, max 10, step 0.1).
  * `show crosshairs` — a native checkbox.

## Keyboard map

| Control | Keys |
| --- | --- |
| List boxes | Arrow keys move, Shift/Ctrl(Cmd) extend selection (native); **Enter** on the observations list adds the selected observations to the queue; **Enter** on the queue displays the selected observation (double-click parity) |
| epoch header buttons | Enter/Space toggles ascending/descending numeric sort |
| rate slider | Left/Down −0.1, Right/Up +0.1, PageUp/PageDown larger steps, Home/End min/max (all native to `input[type=range]`) |
| Star field canvas | Tab or click/tap to focus; **arrow keys** move the crosshair one pixel, **Shift+arrow** ten pixels, **Home/End** jump to the left/right edge; position is announced with each move |
| Masthead dialogs | Managed by the foundation component (focus trap, Escape) |

Only interactive controls are in the tab order. MathJax output, readouts,
labels, and the tooltip are not tab stops (`tabindex="-1"` is applied to
`mjx-container` elements after typesetting as a defensive measure).

## Text alternatives and live announcements

* `#bcsCanvasDesc` (visually hidden, `aria-describedby` on the canvas) is
  continuously updated from `render()`: what the field shows, the epoch, the
  queue position, or that the queue is empty.
* `#bcsLiveRegion` (`role="status"`, `aria-live="polite"`) announces state
  changes **on commit, not per tick**:
  * "Added 3 observations to the blinking queue. Epoch 1.8123 displayed,
    item 3 of 3 in the queue."
  * "Removed 1 observation from the blinking queue. …"
  * "Epoch 1.7422 displayed, item 2 of 5 in the queue." (step forward/back,
    Enter on a queue item)
  * "Blinking started at rate 5 of 10. Activate the stop button to stop." /
    "Blinking stopped. Epoch … displayed…" — individual switches during
    blinking are deliberately **not** announced (up to 20/s would flood the
    reader).
  * "Crosshair at pixel x 200, pixel y 150." (keyboard crosshair moves)
  * "Blink rate 7 of 10. One switch every 195 milliseconds." (slider commit)
  * "Simulation reset. The blinking queue is empty and all observations are
    available."
* Values are announced with their quantity names and units: pixel
  coordinates say "pixel x … pixel y …", the blink rate says "blink rate N
  of 10" (`aria-valuetext`), intervals say "milliseconds". Epochs are
  announced as "epoch N" — the original simulator does not state a unit for
  epoch anywhere, and inventing one would alter the teaching text, so the
  quantity name alone is used.
* The queue's displayed item is marked with a ● glyph and
  `aria-label="epoch …, currently displayed"` on the option; the epoch
  readout and canvas description repeat the information, so it is never
  conveyed by color alone.
* The pointer-following coordinate tooltip is `aria-hidden` (it duplicates
  the live region / keyboard announcements and follows the mouse).

## Color and contrast

* All chrome uses the KL-UNL palette custom properties; body text is
  `#1a1a1a` on `#ffffff` (≈16:1). Disabled buttons use `#f0f0f0` on
  `#8a8a8a` (≈3.4:1; disabled controls are exempt from 1.4.3 but kept
  legible).
* The displayed-item marker uses the foundation alert red `#ea351f`
  (≈4.0:1 on white, above the 3:1 graphical minimum) **plus** the ● glyph
  and bold weight, so color is never the only signal.
* The star field itself is intentionally grayscale (it simulates a CCD
  image); it encodes no color-based state.

## Motion, timing, flashing

* The only animation is the user-initiated blink cycle, started by the
  "blink" button and stopped by the same button ("stop") — a pause control
  is therefore always available (2.2.2). Reset (masthead) also stops it.
* Flash-threshold analysis (2.3.1): at the maximum rate the field switches
  20×/s, but successive frames share the same mean luminance (identical
  noise statistics; stars are point sources covering a tiny fraction of the
  image), so the switches do not constitute general or red flashes. The
  default rate (5) switches ≈3×/s.
* `prefers-reduced-motion` is honored in the sense required here: nothing
  moves without an explicit user action, and CSS transitions are suppressed
  under the media query. The blink alternation itself *is* the educational
  content and only runs on request with a stop always visible.

## Zoom / reflow

* Sim text is sized in `rem` (≥1.125rem body floor) and tracks browser font
  settings; layout uses the KL-UNL responsive grid, collapsing to one
  column below 56rem and to fully stacked lists below 40rem, with no
  horizontal scrolling at 200% zoom or on phone-portrait widths.
* The canvas keeps its original 400×300 coordinate system and scales via
  CSS with a preserved aspect ratio; pointer coordinates are mapped back
  through the scale so hit-testing matches the original math at any size.
* Known limitation: the pointer tooltip reuses the original 48px Flash
  artwork at fixed size, so its text does not scale with zoom. The identical
  information is available at any zoom level via the keyboard crosshair and
  live region, and the artwork could not be enlarged without redrawing an
  exported asset (which the pipeline forbids).

## MathJax

* The only mathematical symbols in the UI — the crosshair coordinate labels
  *x* and *y* — are typeset by the self-hosted MathJax through the
  foundation's `klunlShowEquation`, each paired with a screen-reader message
  (`#bcsEqnMsg`). The MathJax contextual menu is left enabled (right-click
  any typeset symbol → "Show Math As"); no `contextmenu` handlers intercept
  it. Typeset output receives `tabindex="-1"` so it never becomes a tab stop.

## Touch

* All targets meet the 44px (2.75rem) minimum; nothing depends on hover
  (the crosshair tooltip also appears on touch-down, and its data is
  available via keyboard); `<select multiple>` degrades to the platform's
  native multi-select UI on mobile.
