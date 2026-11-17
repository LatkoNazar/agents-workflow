#!/usr/bin/env python3
"""
ui-ref.py — Reference Image Grid Overlay (0..100%) & Macro-Cluster Cropper

Usage:
  1. Overlay 0..100% coordinate grid:
     ./.agents/scripts/ui-ref.py grid <input.png> [output-grid.png]

  2. Crop macro-clusters by percentage (x1,y1,x2,y2 in 0..100):
     ./.agents/scripts/ui-ref.py crop <input.png> <out-dir> \
       sidebar=0,0,18,100 header=18,0,100,10 main=18,10,100,100
"""

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print(
        "Error: Pillow (PIL) is required for ui-ref.py. Install with: pip install Pillow",
        file=sys.stderr,
    )
    sys.exit(1)


def overlay_grid(input_path: str, output_path: str) -> None:
    base = Image.open(input_path).convert("RGBA")
    width, height = base.size
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    font = ImageFont.load_default()

    # Draw 10% major grid lines and 5% minor ticks
    for pct in range(5, 100, 5):
        x = int(width * pct / 100.0)
        y = int(height * pct / 100.0)
        is_major = pct % 10 == 0
        line_color = (255, 40, 80, 150) if is_major else (255, 40, 80, 65)
        line_w = 2 if is_major else 1

        draw.line([(x, 0), (x, height)], fill=line_color, width=line_w)
        draw.line([(0, y), (width, y)], fill=line_color, width=line_w)

        if is_major:
            label = f"{pct}%"
            # Top X-axis label
            draw.rectangle([(x + 2, 2), (x + 30, 16)], fill=(0, 0, 0, 190))
            draw.text((x + 4, 3), label, fill=(255, 255, 255, 255), font=font)
            # Left Y-axis label
            draw.rectangle([(2, y + 2), (30, y + 16)], fill=(0, 0, 0, 190))
            draw.text((4, y + 3), label, fill=(255, 255, 255, 255), font=font)

    combined = Image.alpha_composite(base, overlay).convert("RGB")
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    combined.save(output_path)
    print(f"✅ Grid overlay saved: {output_path} ({width}x{height})")


def crop_clusters(input_path: str, out_dir: str, specs: list[str]) -> None:
    img = Image.open(input_path)
    width, height = img.size
    os.makedirs(out_dir, exist_ok=True)

    for spec in specs:
        if "=" not in spec:
            print(f"❌ Invalid cluster spec '{spec}'. Expected name=x1,y1,x2,y2", file=sys.stderr)
            sys.exit(1)
        name, coords_str = spec.split("=", 1)
        parts = [float(c.strip()) for c in coords_str.split(",")]
        if len(parts) != 4:
            print(f"❌ Invalid coordinates in '{spec}'. Expected 4 numbers (0..100)", file=sys.stderr)
            sys.exit(1)

        x1_pct, y1_pct, x2_pct, y2_pct = parts
        left = max(0, min(width, int(round(width * x1_pct / 100.0))))
        top = max(0, min(height, int(round(height * y1_pct / 100.0))))
        right = max(left + 1, min(width, int(round(width * x2_pct / 100.0))))
        bottom = max(top + 1, min(height, int(round(height * y2_pct / 100.0))))

        cropped = img.crop((left, top, right, bottom))
        out_path = os.path.join(out_dir, f"crop-{name}.png")
        cropped.save(out_path)
        print(
            f"✅ Cluster '{name}' cropped [{x1_pct}%..{x2_pct}% x {y1_pct}%..{y2_pct}%] -> {out_path} ({right - left}x{bottom - top}px)"
        )


def main() -> None:
    if len(sys.argv) < 3:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    input_path = sys.argv[2]

    if not os.path.isfile(input_path):
        print(f"❌ File not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    if cmd == "grid":
        base_name, ext = os.path.splitext(input_path)
        out_path = sys.argv[3] if len(sys.argv) >= 4 else f"{base_name}-grid{ext}"
        overlay_grid(input_path, out_path)
    elif cmd == "crop":
        if len(sys.argv) < 5:
            print("Usage: ui-ref.py crop <input.png> <out-dir> <name=x1,y1,x2,y2> [...]", file=sys.stderr)
            sys.exit(1)
        out_dir = sys.argv[3]
        specs = sys.argv[4:]
        crop_clusters(input_path, out_dir, specs)
    else:
        print(f"❌ Unknown command: {cmd}. Expected 'grid' or 'crop'.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
