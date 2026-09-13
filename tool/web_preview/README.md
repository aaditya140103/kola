# Kola web preview harness (dev-only)

A static web app that mirrors the **current Flutter UI and reader behavior** of
Kola, so the product can be reviewed in a browser when a Flutter SDK is not
available (for example in restricted CI/sandbox environments where
`pub.dev`/Flutter storage are unreachable).

> **This is not the compiled Kola application.** It is a hand-built web mirror
> of `lib/` presentation code: the same design tokens (`kola_tokens.dart`),
> the same Material 3 seed color (`KolaColors.mint`), the same screens, copy,
> and interaction model. Rendering/search/annotation run in the browser via
> pdf.js over generated sample PDFs. It shares no code with the product and
> must never replace real Flutter verification.

## What it mirrors

- Adaptive shell: bottom NavigationBar < 600 px, NavigationRail ≥ 600 px,
  extended rail ≥ 1200 px, Kola mark, "preview harness" chip.
- Home (Continue reading / Next up / This week), Library grid (2–5 columns),
  Search (local index built on first search, snippets + page jumps), Insights
  (metrics, week chart, most-read).
- Reader: floating pill top bar (Fidelity/Flow segmented, Flow disabled),
  PDF page surface with real text selection → highlight creation, persistent
  highlights/notes/recolor/delete (localStorage), annotation panel sheet,
  in-document search sheet, contents + thumbnail sheets, Fit width/Fit page,
  two-page spread ≥ 840 px, prev/next + zoom, debounced (400 ms) position
  resume, and "Fidelity view is not available yet" notices for non-PDF
  formats imported into the demo library.
- Sample library: two generated books (real PDFs) plus four placeholder
  documents in recognized-but-unreadable formats.

## Run it

```bash
python3 tool/web_preview/fetch_vendor.py   # one-time: pdf.js, icons, fonts from npm
python3 tool/web_preview/build_preview.py  # one-time: sample PDFs + books.json
python3 tool/web_preview/serve.py          # http://0.0.0.0:8080
```

`fetch_vendor.py` and `build_preview.py` are idempotent; re-run them after
changing the sample book content. `build_preview.py` creates a local
virtualenv (`.venv/`) for `fpdf2`.

## Files

- `site/` — the harness app (`index.html`, `app.js`, `styles.css`).
- `site/vendor/`, `site/data/` — generated assets (git-ignored).
- `fetch_vendor.py` — pinned downloads from the npm registry.
- `build_preview.py` — sample book generator (fpdf2) + library metadata.
- `serve.py` — static server (`.mjs` MIME override, binds 0.0.0.0).

## Constraints

- Dev tooling only: never import from or ship in the Flutter product.
- Does not use the Kola database/Drift schema; state is localStorage.
- Importing your own PDF works for the browser session only (files are kept
  in memory, matching the demo's disposable-cache philosophy).
