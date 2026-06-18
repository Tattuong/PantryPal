"""Generate PantryPal square app logo (1024x1024, sharp corners)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[1] / "assets" / "logo.png"

DEEP = (14, 107, 68)
GREEN = (27, 174, 96)
MINT = (46, 204, 113)
GOLD = (255, 193, 7)
WHITE = (255, 255, 255)
CREAM = (255, 248, 230)
WOOD = (139, 90, 43)


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def square_gradient(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            tx = x / size
            ty = y / size
            t = tx * 0.4 + ty * 0.6
            r = lerp(DEEP[0], GREEN[0], t * 0.75)
            g = lerp(DEEP[1], MINT[1], t * 0.65)
            b = lerp(DEEP[2], MINT[2], t * 0.45)
            px[x, y] = (r, g, b)
    return img


def draw_shelf(draw: ImageDraw.ImageDraw, y: int) -> None:
    draw.rectangle((120, y, 904, y + 18), fill=WOOD + (255,))
    draw.rectangle((120, y, 904, y + 6), fill=(180, 120, 60, 255))


def draw_jar(draw: ImageDraw.ImageDraw, cx: int, bottom: int, color: tuple[int, int, int]) -> None:
    w, h = 90, 120
    left, top = cx - w // 2, bottom - h
    draw.rounded_rectangle((left, top + 20, left + w, bottom), radius=16, fill=color + (255,))
    draw.rectangle((left + 18, top, left + w - 18, top + 28), fill=WHITE + (230,))
    draw.ellipse((left + 24, top - 8, left + w - 24, top + 16), fill=WHITE + (200,))


def draw_apple(draw: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    draw.ellipse((cx - 38, cy - 30, cx + 38, cy + 42), fill=(231, 76, 60, 255))
    draw.line((cx, cy - 30, cx + 8, cy - 52), fill=(101, 67, 33, 255), width=5)
    draw.ellipse((cx + 10, cy - 48, cx + 34, cy - 28), fill=(39, 174, 96, 255))


def draw_leaf(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int) -> None:
    draw.ellipse((cx - size, cy - size // 2, cx + size, cy + size // 2), fill=MINT + (220,))


def main() -> None:
    base = square_gradient(SIZE).convert("RGBA")
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    draw_shelf(draw, 620)
    draw_shelf(draw, 760)

    draw_jar(draw, 280, 620, (52, 152, 219))
    draw_jar(draw, 420, 620, (241, 196, 15))
    draw_jar(draw, 560, 620, (155, 89, 182))
    draw_jar(draw, 700, 620, (230, 126, 34))

    draw_apple(draw, 820, 590)
    draw_leaf(draw, 180, 520, 42)
    draw_leaf(draw, 860, 480, 36)

    draw.rounded_rectangle((340, 300, 684, 520), radius=28, fill=CREAM + (245,))
    draw.rounded_rectangle((340, 300, 684, 520), radius=28, outline=WHITE + (180,), width=6)
    draw.ellipse((470, 360, 554, 444), fill=GREEN + (255,))
    draw.polygon([(512, 300), (492, 340), (532, 340)], fill=GOLD + (255,))

    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((312, 280, 712, 540), fill=(255, 255, 255, 35))
    glow = glow.filter(ImageFilter.GaussianBlur(40))

    composed = Image.alpha_composite(base, glow)
    composed = Image.alpha_composite(composed, overlay)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    composed.convert("RGB").save(OUT, format="PNG", optimize=True)
    print(f"Saved PantryPal logo: {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
