#!/usr/bin/env python3
"""Scrum Artifacts Generator — reads data.json, renders HTML, optionally exports PDF."""
import json
import sys
from pathlib import Path


def main():
    base_dir = Path(__file__).parent
    data_path = base_dir / "data.json"
    template_path = base_dir / "templates" / "base.html"
    output_dir = base_dir / "output"
    output_dir.mkdir(exist_ok=True)

    # Load data
    print("[1/4] Loading data.json...")
    if not data_path.exists():
        print(f"ERROR: {data_path} not found.")
        sys.exit(1)
    with open(data_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Load and render template
    print("[2/4] Rendering template...")
    try:
        from jinja2 import Environment, FileSystemLoader
    except ImportError:
        print("ERROR: jinja2 not installed. Run: pip install jinja2")
        sys.exit(1)

    if not template_path.exists():
        print(f"ERROR: {template_path} not found.")
        sys.exit(1)

    env = Environment(loader=FileSystemLoader(str(base_dir / "templates")))
    template = env.get_template("base.html")
    html_content = template.render(**data)

    # Write HTML
    html_path = output_dir / "artefatos.html"
    print(f"[3/4] Writing HTML to {html_path}...")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html_content)

    # Try PDF
    print("[4/4] Generating PDF...")
    try:
        from weasyprint import HTML
        pdf_path = output_dir / "artefatos.pdf"
        HTML(string=html_content, base_url=str(base_dir)).write_pdf(str(pdf_path))
        print(f"  PDF saved to {pdf_path}")
    except ImportError:
        print("  weasyprint not installed. Skipping PDF generation.")
        print("  Install with: pip install weasyprint")
        print(f"  You can open {html_path} in a browser and print to PDF manually (Ctrl+P).")
    except Exception as e:
        print(f"  PDF generation failed: {e}")
        print(f"  You can open {html_path} in a browser and print to PDF manually (Ctrl+P).")

    print("\nDone!")


if __name__ == "__main__":
    main()
