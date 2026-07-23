# Blink Comparator Simulator (Accessible HTML5)

**This simulation must be served over HTTP — it will not run from a
double-clicked `index.html` (`file://`) path.**

## Why

The KL-UNL masthead component (`foundation/kl-unl-masthead.js`) loads the
simulation's title, Help, and About text with
`fetch('foundation/contents.json')`. Browsers block `fetch()` of local files
under the `file://` protocol for security (same-origin policy), so opening
`index.html` directly from the file system shows an empty or broken masthead.
Served over HTTP the fetch succeeds and the simulation loads normally.

## How to run locally

Run one of these from inside the `html5/` folder, then open the printed URL:

```
# Python
python3 -m http.server 8123        # then open http://localhost:8123/

# Node
npx serve                          # or: npx http-server

# VS Code
Use the "Live Server" extension on index.html
```

Note that when you serve from inside `html5/`, the simulation is at the
server root — the URL is `http://localhost:8123/`, not `.../html5/index.html`.

## Production

When deployed to the cloud host (served over HTTP/HTTPS) it just works; the
`file://` limitation only affects local double-clicking.

## Contents

| Path | Purpose |
| --- | --- |
| `index.html` | KL-UNL scaffold (`.app-shell`, `<kl-unl-masthead>`, panels) |
| `foundation/` | KL-UNL foundation files, copied unchanged (only this sim's `contents.json` entry was edited) |
| `styles/styles.css` | Sim-specific styles layered on the foundation |
| `simulation.js` | All simulation logic, ported from the decompiled ActionScript |
| `assets/settings-data.js` | Star list / observation data (verbatim from the original `settings.xml`) |
| `assets/settings.xml` | The original runtime data file, kept for reference |
| `assets/crosshair-tooltip.svg` | Exported Flash artwork, reused as-is |
| `assets/arrows.svg` | Exported Flash artwork, reused as-is |
| `assets/mathjax/tex-svg.js` | Self-hosted MathJax (no CDN requests at runtime) |
| `CONVERSION_NOTES.md` | Behavior model, AS→HTML5 mapping, deviations |
| `ACCESSIBILITY.md` | WCAG affordances, keyboard map, screen-reader wording |

The only network requests the page makes are local:
`foundation/contents.json` (fetched by the masthead) and the page's own
scripts/styles/images. Nothing leaves the host.
