"""Draws the Critter Logic app icon: a pastel 3x3 Nests board on coral, with the chick sitting on it.

Game-first, no brand marks. The board's zones use the Nests zone colors from lib/ui/palette.dart;
the chick is Kenney's "Animal Pack Remastered" chick (CC0), rendered from the pack's vector sheet
by tools/make_critters.py so it stays sharp at 1024 px.

Writes assets/icon/icon.png (iOS, web, legacy Android) and, for the Android adaptive icon,
assets/icon/background.png (plain coral) and assets/icon/foreground.png (board + chick, shrunk into
the circle Android never crops).
Run: python3 -I tools/make_icon.py <unzipped Animal Pack Remastered root>  (Pillow, numpy, Chrome),
then: dart pub global run flutter_launcher_icons
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_critters import HEAD, render_critter  # noqa: E402

SIZE = 1024
SS = 4  # supersampling for smooth edges
S = SIZE * SS

BACKGROUND = (0xFF, 0x9F, 0x7A)  # a softer take on palette.dart's coral accent
BOARD = (0xFF, 0xF6, 0xE9)  # palette.dart background (cream)
# Nests zones (palette.dart zoneColors): peach, mint, sky, lavender, pink, lemon.
PEACH, MINT, SKY, LAVENDER, PINK, LEMON = (0xFF, 0xD6, 0xA5), (0xCA, 0xFF, 0xBF), (0x9B, 0xF6, 0xFF), (0xBD, 0xB2, 0xFF), (0xFF, 0xAD, 0xAD), (0xFD, 0xFF, 0xB6)
ZONES = [
    [SKY, SKY, PINK],
    [LAVENDER, MINT, PINK],
    [LAVENDER, MINT, MINT],
]

# Android shows only a circle of diameter 66/108 for sure; keep the whole design inside it.
ADAPTIVE_SCALE = 0.6


def design(img, scale, pack):
    """Board + chick, in design units (0..1) shrunk by `scale` around the center."""
    def p(v):
        return (0.5 + (v - 0.5) * scale) * S

    def ln(v):
        return v * scale * S

    d = ImageDraw.Draw(img)
    # Board: cream rounded square with 3x3 zone tiles.
    x0, y0, size = p(0.14), p(0.08), ln(0.72)
    d.rounded_rectangle([x0, y0, x0 + size, y0 + size], radius=ln(0.11), fill=BOARD)
    pad, gap = ln(0.035), ln(0.018)
    cell = (size - 2 * pad - 2 * gap) / 3
    for r, row in enumerate(ZONES):
        for c, color in enumerate(row):
            tx, ty = x0 + pad + c * (cell + gap), y0 + pad + r * (cell + gap)
            d.rounded_rectangle([tx, ty, tx + cell, ty + cell], radius=cell * 0.22, fill=color)
            # Same-zone neighbors merge into one region, like a Nests zone.
            if c < 2 and row[c + 1] == color:
                d.rectangle([tx + cell / 2, ty, tx + cell * 1.5 + gap, ty + cell], fill=color)
            if r < 2 and ZONES[r + 1][c] == color:
                d.rectangle([tx, ty + cell / 2, tx + cell, ty + cell * 1.5 + gap], fill=color)

    # Chick: head circle 0.54 wide, sitting low on the board, with a soft shadow.
    head = ln(0.54)
    chick, (hx, hy) = render_critter(pack, 'chick', head / HEAD)
    cx, cy = p(0.5), p(0.61)
    shadow = Image.new('L', img.size, 0)
    ImageDraw.Draw(shadow).ellipse([cx - head * 0.42, cy + head * 0.36, cx + head * 0.42, cy + head * 0.54], fill=90)
    shadow = shadow.filter(ImageFilter.GaussianBlur(ln(0.02)))
    img.paste((0x8A, 0x4B, 0x2F, 255), (0, 0), shadow)
    img.alpha_composite(chick, (round(cx - hx), round(cy - hy)))


def save(img, path, rgb=True):
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    (img.convert('RGB') if rgb else img).save(path, optimize=True)


def main():
    pack = sys.argv[1]
    out = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
    os.makedirs(out, exist_ok=True)

    full = Image.new('RGBA', (S, S), BACKGROUND + (255,))
    design(full, 1.0, pack)
    save(full, os.path.join(out, 'icon.png'))

    save(Image.new('RGBA', (S, S), BACKGROUND + (255,)), os.path.join(out, 'background.png'))

    front = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    design(front, ADAPTIVE_SCALE, pack)
    save(front, os.path.join(out, 'foreground.png'), rgb=False)


if __name__ == '__main__':
    main()
