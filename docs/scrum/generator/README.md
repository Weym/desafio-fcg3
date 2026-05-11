# Scrum Artifacts Generator

Generates a single-page HTML document containing all Scrum artifacts for the **Plataforma Academica** project. The HTML is designed for A4 PDF export.

## Prerequisites

```bash
pip install jinja2
# Optional — for direct PDF export:
pip install weasyprint
```

## Usage

```bash
cd scrum/generator
python generate.py
```

Output files appear in `output/`:
- `artefatos.html` — full artifact document
- `artefatos.pdf` — PDF version (only if weasyprint is installed)

## Editing Data

All content comes from `data.json`. Edit that file to update:
- Project metadata and metrics
- Epic list and story points
- Sprint burndown data points
- Kanban board tasks
- Definition of Done items
- Retrospective items

After editing, re-run `python generate.py`.

## Manual PDF Export

If weasyprint is not installed or fails:

1. Open `output/artefatos.html` in a browser (Chrome recommended)
2. Press `Ctrl+P` (or `Cmd+P` on macOS)
3. Set destination to **Save as PDF**
4. Set paper size to **A4**
5. Enable **Background graphics**
6. Save

## File Structure

```
scrum/generator/
  data.json           Single source of truth for all Scrum data
  generate.py         Main generation script
  templates/
    base.html         Jinja2 HTML template with inline CSS
  output/
    artefatos.html    Generated HTML artifact
    artefatos.pdf     Generated PDF (optional)
```
