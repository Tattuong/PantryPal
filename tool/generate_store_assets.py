"""Generate Google Play listing images for Random Decision."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store_assets"
SIZE = (1080, 1920)

PURPLE = (91, 33, 255)
VIOLET = (124, 58, 237)
CORAL = (255, 107, 107)
GOLD = (255, 217, 61)
WHITE = (255, 255, 255)
DEEP = (35, 18, 90)
WHEEL = [
    (91, 133, 255),
    (255, 107, 107),
    (0, 184, 148),
    (255, 142, 83),
    (116, 185, 255),
    (255, 176, 32),
]


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def gradient_bg() -> Image.Image:
    img = Image.new("RGB", SIZE)
    px = img.load()
    for y in range(SIZE[1]):
        for x in range(SIZE[0]):
            t = (x / SIZE[0] * 0.4 + y / SIZE[1] * 0.6)
            r = int(DEEP[0] + (PURPLE[0] - DEEP[0]) * t)
            g = int(DEEP[1] + (VIOLET[1] - DEEP[1]) * t)
            b = int(DEEP[2] + (CORAL[2] - DEEP[2]) * t * 0.5)
            px[x, y] = (r, g, b)
    return img


def draw_wheel(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int) -> None:
    count = len(WHEEL)
    for i, color in enumerate(WHEEL):
        start = i * 360 / count - 90
        end = start + 360 / count
        draw.pieslice((cx - radius, cy - radius, cx + radius, cy + radius), start, end, fill=color)
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=WHITE, width=8)
    draw.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=WHITE)
    pts = [(cx, cy - radius - 10), (cx - 36, cy - radius - 58), (cx + 36, cy - radius - 58)]
    draw.polygon(pts, fill=GOLD)


def header(draw: ImageDraw.ImageDraw, title: str, subtitle: str) -> None:
    draw.text((72, 120), title, fill=WHITE, font=load_font(64, bold=True))
    draw.text((72, 210), subtitle, fill=(255, 255, 255, 200), font=load_font(34))


def save(name: str, img: Image.Image) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.save(path, optimize=True)
    print(f"Saved {path}")


def shot_wheel() -> None:
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Random Decision", "Spin the wheel — let fate decide")
    draw_wheel(draw, SIZE[0] // 2, 980, 320)
    draw.rounded_rectangle((120, 1500, 960, 1620), radius=28, fill=WHITE)
    draw.text((SIZE[0] // 2 - 120, 1535), "SPIN!", fill=PURPLE, font=load_font(48, bold=True))
    save("01_wheel.png", img)


def shot_choices() -> None:
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Your choices", "Add, edit & reorder options")
    y = 360
    for label in ["Pizza", "Burger", "Sushi", "Salad", "Pasta", "Tacos"]:
        draw.rounded_rectangle((72, y, 1008, y + 110), radius=24, fill=(255, 255, 255, 28), outline=WHITE, width=2)
        draw.text((110, y + 32), label, fill=WHITE, font=load_font(38, bold=True))
        y += 130
    save("02_choices.png", img)


def shot_shop() -> None:
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Star Shop", "Earn stars or buy via Google Play")
    cards = [
        ("Neon wheel skin", "200 ★"),
        ("Remove ads", "500 ★"),
        ("Unlimited choices", "300 ★"),
    ]
    y = 380
    for title, price in cards:
        draw.rounded_rectangle((72, y, 1008, y + 180), radius=28, fill=(255, 255, 255, 24), outline=GOLD, width=2)
        draw.text((110, y + 40), title, fill=WHITE, font=load_font(36, bold=True))
        draw.text((110, y + 100), price, fill=GOLD, font=load_font(30, bold=True))
        y += 210
    save("03_shop.png", img)


def shot_themes() -> None:
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Customize", "Themes, backgrounds & wheel skins")
    boxes = [(72, 360, 520, 720), (560, 360, 1008, 720), (72, 760, 520, 1120), (560, 760, 1008, 1120)]
    colors = [CORAL, (9, 132, 227), (0, 184, 148), (253, 121, 168)]
    labels = ["Sunset", "Midnight", "Tropical", "Sakura"]
    for box, color, label in zip(boxes, colors, labels):
        draw.rounded_rectangle(box, radius=32, fill=color)
        draw.text((box[0] + 36, box[1] + 36), label, fill=WHITE, font=load_font(34, bold=True))
    save("04_themes.png", img)


def shot_feature() -> None:
    img = gradient_bg()
    draw = ImageDraw.Draw(img)
    header(draw, "Premium features", "Unlock with stars or Google Play packs")
    feats = ["Weighted spin", "Spin history", "Export lists", "No watermark on share"]
    y = 380
    for feat in feats:
        draw.ellipse((90, y + 8, 130, y + 48), fill=GOLD)
        draw.text((150, y), feat, fill=WHITE, font=load_font(34, bold=True))
        y += 90
    draw_wheel(draw, SIZE[0] // 2, 1350, 220)
    save("05_features.png", img)


def main() -> None:
    shot_wheel()
    shot_choices()
    shot_shop()
    shot_themes()
    shot_feature()


if __name__ == "__main__":
    main()
