#!/usr/bin/env python3
"""chopsticksAI app icon — monochrome ◉ mark with safe-area padding baked in."""
from PIL import Image, ImageDraw

SIZE = 1024
BG = (10, 10, 12)
FG = (232, 232, 237)

img = Image.new("RGB", (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)
cx = cy = SIZE // 2
outer = int(SIZE * 0.27)
inner = int(SIZE * 0.095)
stroke = max(4, int(SIZE * 0.022))

draw.ellipse(
    (cx - outer, cy - outer, cx + outer, cy + outer),
    outline=FG,
    width=stroke,
)
draw.ellipse(
    (cx - inner, cy - inner, cx + inner, cy + inner),
    fill=FG,
)

out = __import__("pathlib").Path(__file__).resolve().parent.parent / "Sources" / "AppIcon-source.png"
img.save(out)
print(f"wrote {out}")
