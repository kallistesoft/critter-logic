"""Draws the Critter Logic app icon (chosen 2026-11-12: "Trail", concept 2 of the second round).

The other concepts are kept so they can be re-rendered: python3 -I tools/make_icon.py <pack> --concept N.

Same pipeline as round 1 (icon-concepts/make_concepts.py): each concept is drawn as SVG and rendered by headless
Chrome into a background layer (full bleed), a foreground layer (transparent, the design fitted inside the circle
Android never crops) and icon.png (both flattened, design enlarged for legacy/iOS/web). comparison.png shows all four.
Critters (concept 3 only) are Kenney's "Animal Pack Remastered" (CC0) vector paths; everything else is drawn here.
Numbers use Fredoka Bold (OFL, the game's display font), embedded as a data URI.

Run: python3 -I tools/make_icon.py <unzipped Animal Pack Remastered root>
then: dart pub global run flutter_launcher_icons
"""
import base64
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from xml.sax.saxutils import quoteattr

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_critters import CHROME, HEAD, bbox, head_center, load, render  # noqa: E402

HERE = Path(__file__).resolve().parent
SIZE = 1024
FIT_RADIUS = 335   # farthest opaque foreground pixel from the center (safe circle 313 px, circle mask 341 px)
ICON_BOOST = 1.4   # legacy icon: about what a launcher shows of the adaptive icon

# Meadow palette (lib/ui/worlds/meadow_world.dart).
INK = '#4A3426'
WOOD, WOOD_LIGHT, WOOD_DARK, WOOD_EDGE = '#C98A4B', '#E3AD6C', '#8E5A2B', '#6B4220'
PAPER, PAPER_EDGE, TILE_EMPTY = '#FFF8E7', '#E6D2AC', '#F3E6CE'
LEAF, LEAF_EDGE, GOOD = '#6CCB3C', '#3F9322', '#5CBF3A'
GRASS, GRASS_DARK, LAWN_TOP, LAWN_EDGE = '#6CC04A', '#479A35', '#8ED46B', '#2F7A26'
GOLD, GOLD_EDGE = '#FFC23D', '#D38A12'
CORAL, CORAL_EDGE = '#FF8A5B', '#D25A31'
PEB_TOP, PEB_LOW, PEB_RIM = '#FFEDB8', '#F5C95A', '#D38A12'   # reached pebble
# Cozy zone colors for the icon (softer than candy): sage, butter, terracotta, sky.
SAGE, SAGE_E = '#A8D58A', '#6FA653'
BUTTER, BUTTER_E = '#FFE08A', '#D9A93C'
TERRA, TERRA_E = '#F0A274', '#C46A3F'
SKYZ, SKYZ_E = '#A6D8F2', '#5FA3CC'

FONT = base64.b64encode((HERE.parent / 'assets' / 'fonts' / 'Fredoka-Bold.ttf').read_bytes()).decode()
FONT_CSS = f'<style>@font-face{{font-family:Fredoka;src:url(data:font/ttf;base64,{FONT}) format("truetype");}}</style>'

# ---------------------------------------------------------------- helpers

_CRITTERS = {}


def critter(pack, cid, cx, cy, d):
    """Critter `cid` with its head circle (diameter d) centered on (cx, cy)."""
    if cid not in _CRITTERS:
        group = load(pack)[cid]
        with tempfile.TemporaryDirectory() as tmp:
            im = render(group, 1, tmp)
        hx, hy = head_center(np.array(im)[:, :, 3] > 128)
        x0, y0, *_ = bbox(group)
        _CRITTERS[cid] = (group, x0 - 1 + hx, y0 - 1 + hy)
    group, hx, hy = _CRITTERS[cid]
    s = d / HEAD
    body = ''.join(f'<path fill="{f}"' + (f' fill-opacity="{op}"' if op is not None else '') + f' d={quoteattr(p)}/>'
                   for f, op, p, _ in group)
    return f'<g transform="translate({cx} {cy}) scale({s}) translate({-hx} {-hy})">{body}</g>'


DEFS = ''.join(f'<filter id="blur{b}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{b}"/></filter>'
               for b in (4, 8, 14, 20, 30))


def rrect(x0, y0, x1, y1, r, **attrs):
    a = ' '.join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    return f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="{r}" {a}/>'


def soft_shadow(x0, y0, x1, y1, r, dy=26, op=0.30, blur=20, color='#5A3A1E'):
    return rrect(x0 + 10, y0 + dy, x1 - 10, y1 + dy, r, fill=color, fill_opacity=op, filter=f'url(#blur{blur})')


def wood_frame(uid, x0, y0, x1, y1, r, depth=30, outline=14, plank=92, seed=1):
    """Chunky wooden board like WoodPainter (paintWoodPlanks): darker lip below, light->mid gradient face,
    plank seams and grain, a soft top shine. Returns svg."""
    rng = np.random.default_rng(seed)
    out = f'<linearGradient id="{uid}g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{WOOD_LIGHT}"/>' \
          f'<stop offset="1" stop-color="{WOOD}"/></linearGradient>'
    out += f'<clipPath id="{uid}c">{rrect(x0, y0, x1, y1, r)}</clipPath>'
    out += soft_shadow(x0, y0, x1, y1 + depth, r)
    out += rrect(x0, y0 + depth, x1, y1 + depth, r, fill=WOOD_EDGE, stroke=WOOD_EDGE, stroke_width=outline)
    out += rrect(x0, y0, x1, y1, r, fill=f'url(#{uid}g)', stroke=WOOD_EDGE, stroke_width=outline)
    out += f'<g clip-path="url(#{uid}c)">'
    rows = max(1, round((y1 - y0) / plank))
    ph = (y1 - y0) / rows
    for i in range(rows):
        y = y0 + i * ph
        if i:
            out += f'<line x1="{x0}" y1="{y:.1f}" x2="{x1}" y2="{y:.1f}" stroke="{WOOD_DARK}" stroke-opacity="0.5" stroke-width="5"/>'
        for _ in range(2):
            gy = y + ph * rng.uniform(0.3, 0.75)
            gx = x0 + rng.uniform(0.05, 0.6) * (x1 - x0)
            gl = rng.uniform(0.2, 0.35) * (x1 - x0)
            out += (f'<path d="M{gx:.0f} {gy:.0f} q{gl / 2:.0f} {rng.uniform(-8, 8):.0f} {gl:.0f} 0" fill="none" '
                    f'stroke="{WOOD_DARK}" stroke-opacity="0.22" stroke-width="4" stroke-linecap="round"/>')
    out += rrect(x0 + r * 0.7, y0 + 12, x1 - r * 0.7, y0 + 30, 9, fill='#FFFFFF', fill_opacity=0.28)
    out += '</g>'
    return out


def nail(x, y, s=11):
    return (f'<circle cx="{x}" cy="{y + 2}" r="{s}" fill="{WOOD_EDGE}" fill-opacity="0.5"/>'
            f'<circle cx="{x}" cy="{y}" r="{s}" fill="#B9A58C" stroke="{WOOD_EDGE}" stroke-width="3"/>'
            f'<circle cx="{x - s * 0.3}" cy="{y - s * 0.3}" r="{s * 0.35}" fill="#FFFFFF" fill-opacity="0.7"/>')


def paw(cx, cy, s, color, rot=0):
    """Paw print of overall size ~s: a big rounded pad and four toe beans."""
    pad = (f'<path d="M{cx} {cy - s * 0.02} C{cx + s * 0.20} {cy - s * 0.02} {cx + s * 0.34} {cy + s * 0.20} '
           f'{cx + s * 0.30} {cy + s * 0.32} C{cx + s * 0.27} {cy + s * 0.42} {cx + s * 0.14} {cy + s * 0.40} {cx} {cy + s * 0.38} '
           f'C{cx - s * 0.14} {cy + s * 0.40} {cx - s * 0.27} {cy + s * 0.42} {cx - s * 0.30} {cy + s * 0.32} '
           f'C{cx - s * 0.34} {cy + s * 0.20} {cx - s * 0.20} {cy - s * 0.02} {cx} {cy - s * 0.02}Z"/>')
    toes = ''.join(f'<ellipse cx="{cx + dx * s}" cy="{cy + dy * s}" rx="{s * 0.105}" ry="{s * 0.135}" '
                   f'transform="rotate({a} {cx + dx * s} {cy + dy * s})"/>'
                   for dx, dy, a in [(-0.36, -0.12, -25), (-0.13, -0.32, -8), (0.13, -0.32, 8), (0.36, -0.12, 25)])
    return f'<g fill="{color}" transform="rotate({rot} {cx} {cy + s * 0.05})">{pad}{toes}</g>'


def leaf(cx, cy, s, rot=-34):
    """paintLeaf: the Meadow's Nests "not here" mark."""
    w = h = s
    d = (f'M0 {-h * 0.46:.1f} Q{w * 0.42:.1f} {-h * 0.1:.1f} 0 {h * 0.42:.1f} '
         f'Q{-w * 0.42:.1f} {-h * 0.1:.1f} 0 {-h * 0.46:.1f}Z')
    sw = w * 0.07
    return (f'<g transform="translate({cx} {cy}) rotate({rot})">'
            f'<path d="{d}" transform="translate(0 {s * 0.04})" fill="#000" fill-opacity="0.18"/>'
            f'<path d="{d}" fill="{GOOD}" stroke="{LAWN_EDGE}" stroke-width="{sw}" stroke-linejoin="round"/>'
            f'<line x1="0" y1="{-h * 0.32}" x2="0" y2="{h * 0.5}" stroke="{LAWN_EDGE}" stroke-width="{sw}" stroke-linecap="round"/>'
            f'<circle cx="{-w * 0.1}" cy="{-h * 0.12}" r="{w * 0.06}" fill="#fff" fill-opacity="0.55"/></g>')


def cream_bg(uid, warm='#F3D7A6', center='#FFF9EC', mid='#FFF1D6'):
    return f'''<defs><radialGradient id="{uid}" cx="0.5" cy="0.42" r="0.75">
      <stop offset="0" stop-color="{center}"/><stop offset="0.55" stop-color="{mid}"/><stop offset="1" stop-color="{warm}"/>
    </radialGradient></defs><rect width="1024" height="1024" fill="url(#{uid})"/>'''


def catmull(points, closed=False):
    """Smooth path through points (Catmull-Rom -> cubic Bezier)."""
    p = points
    d = f'M{p[0][0]:.1f} {p[0][1]:.1f}'
    for i in range(len(p) - 1):
        p0 = p[i - 1] if i else p[0]
        p1, p2 = p[i], p[i + 1]
        p3 = p[i + 2] if i + 2 < len(p) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f' C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f}'
    return d


def check_badge(cx, cy, r):
    chk = f'M{cx - r * 0.42} {cy + r * 0.02} L{cx - r * 0.12} {cy + r * 0.32} L{cx + r * 0.44} {cy - r * 0.30}'
    lip = r * 0.12
    return (f'<circle cx="{cx}" cy="{cy + lip + 8}" r="{r}" fill="#2B1A10" fill-opacity="0.25" filter="url(#blur8)"/>'
            f'<circle cx="{cx}" cy="{cy + lip}" r="{r}" fill="{LEAF_EDGE}" stroke="{WOOD_EDGE}" stroke-width="12"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{GOOD}" stroke="{WOOD_EDGE}" stroke-width="12"/>'
            f'<ellipse cx="{cx}" cy="{cy - r * 0.45}" rx="{r * 0.62}" ry="{r * 0.30}" fill="#fff" fill-opacity="0.22"/>'
            f'<path d="{chk}" fill="none" stroke="{LEAF_EDGE}" stroke-width="{r * 0.30}" stroke-linecap="round" '
            f'stroke-linejoin="round" transform="translate(0 {r * 0.07})"/>'
            f'<path d="{chk}" fill="none" stroke="#FFFFFF" stroke-width="{r * 0.27}" stroke-linecap="round" stroke-linejoin="round"/>')


# ---------------------------------------------------------------- concepts

def concept1(pack):
    """Wooden Nests board, top-down: 4x4 zones (sage/butter/terracotta/sky) with wood hedges, solved with paw tokens."""
    bg = cream_bg('bg1')
    X0, Y0, X1, Y1 = 130, 120, 870, 860
    fg = DEFS + wood_frame('f1', X0, Y0, X1, Y1, 90, depth=30)
    for x, y in [(X0 + 44, Y0 + 44), (X1 - 44, Y0 + 44), (X0 + 44, Y1 - 44), (X1 - 44, Y1 - 44)]:
        fg += nail(x, y)
    # Inner well.
    a, b = X0 + 78, X1 - 78
    top, bot = Y0 + 78, Y1 - 78
    n = 4
    cw = (b - a) / n
    zones = ['AABB', 'ACBB', 'DCCB', 'DDCC']
    col = {'A': (SAGE, SAGE_E), 'B': (SKYZ, SKYZ_E), 'C': (BUTTER, BUTTER_E), 'D': (TERRA, TERRA_E)}
    fg += rrect(a - 6, top - 10, b + 6, bot + 6, 40, fill=WOOD_EDGE)
    fg += '<clipPath id="well"><rect x="{}" y="{}" width="{}" height="{}" rx="34"/></clipPath>'.format(a, top, b - a, bot - top)
    fg += '<g clip-path="url(#well)">'
    for r in range(n):
        for c in range(n):
            f, e = col[zones[r][c]]
            x, y = a + c * cw, top + r * cw
            fg += f'<rect x="{x - 1}" y="{y - 1}" width="{cw + 2}" height="{cw + 2}" fill="{f}"/>'
            # soft inner shading at the bottom of each cell
            fg += f'<rect x="{x}" y="{y + cw * 0.78}" width="{cw}" height="{cw * 0.22}" fill="{e}" fill-opacity="0.22"/>'
    # Thin cell lines inside a zone.
    for k in range(1, n):
        fg += f'<line x1="{a + k * cw}" y1="{top}" x2="{a + k * cw}" y2="{bot}" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="5"/>'
        fg += f'<line x1="{a}" y1="{top + k * cw}" x2="{b}" y2="{top + k * cw}" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="5"/>'
    fg += '</g>'
    # Hedges: thick wooden rails on zone borders.
    segs = []
    for r in range(n):
        for c in range(n):
            if c + 1 < n and zones[r][c] != zones[r][c + 1]:
                x = a + (c + 1) * cw
                segs.append((x, top + r * cw, x, top + (r + 1) * cw))
            if r + 1 < n and zones[r][c] != zones[r + 1][c]:
                y = top + (r + 1) * cw
                segs.append((a + c * cw, y, a + (c + 1) * cw, y))
    lines = ''.join(f'<line x1="{x0}" y1="{y0}" x2="{x1}" y2="{y1}"/>' for x0, y0, x1, y1 in segs)
    fg += f'<g stroke="{WOOD_EDGE}" stroke-width="48" stroke-linecap="round" transform="translate(0 7)">{lines}</g>'
    fg += f'<g stroke="{WOOD_DARK}" stroke-width="44" stroke-linecap="round">{lines}</g>'
    fg += f'<g stroke="{WOOD}" stroke-width="20" stroke-linecap="round" transform="translate(-2 -6)">{lines}</g>'
    # Solved: one token per row, column and zone, none touching.
    for r, c in [(0, 1), (1, 3), (2, 0), (3, 2)]:
        x, y = a + (c + 0.5) * cw, top + (r + 0.5) * cw
        rr = cw * 0.36
        fg += f'<circle cx="{x}" cy="{y + 8}" r="{rr}" fill="{WOOD_EDGE}" fill-opacity="0.35"/>'
        fg += f'<circle cx="{x}" cy="{y}" r="{rr}" fill="{PAPER}" stroke="{WOOD_EDGE}" stroke-width="9"/>'
        fg += paw(x, y - rr * 0.08, rr * 1.32, WOOD_EDGE)
    return bg, fg


def concept2(pack):
    """Trail: a cream paper tile on grass, a bold dirt trail through stones 1-2-3 to a flag, paw at the start."""
    bg = '''<defs><linearGradient id="g2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#9BDA77"/><stop offset="1" stop-color="#5DB03F"/></linearGradient>
      <radialGradient id="l2" cx="0.5" cy="0.35" r="0.7"><stop offset="0" stop-color="#FFF6C8" stop-opacity="0.45"/>
      <stop offset="1" stop-color="#FFF6C8" stop-opacity="0"/></radialGradient></defs>
      <rect width="1024" height="1024" fill="url(#g2)"/><rect width="1024" height="1024" fill="url(#l2)"/>'''
    for x, y in [(110, 150), (900, 120), (80, 880), (930, 900), (520, 60), (40, 520), (980, 560)]:
        bg += (f'<path d="M{x - 18} {y + 14} q4 -22 8 -30 q2 14 4 24 q6 -18 12 -24 q-2 16 -2 28 q8 -12 14 -14 q-4 10 -6 18Z" '
               f'fill="{GRASS_DARK}" fill-opacity="0.45"/>')
    X0, Y0, X1, Y1 = 140, 140, 860, 860
    fg = DEFS + soft_shadow(X0, Y0, X1, Y1 + 26, 110, op=0.35, color='#1E4A12')
    fg += rrect(X0, Y0 + 26, X1, Y1 + 26, 110, fill=PAPER_EDGE, stroke=WOOD_EDGE, stroke_width=14)
    fg += rrect(X0, Y0, X1, Y1, 110, fill=PAPER, stroke=WOOD_EDGE, stroke_width=14)
    fg += rrect(X0 + 40, Y0 + 36, X1 - 40, Y0 + 70, 17, fill='#FFFFFF', fill_opacity=0.6)
    # Trail.
    pts = [(255, 760), (470, 730), (690, 640), (640, 470), (420, 430), (330, 310), (470, 250), (640, 250)]
    d = catmull(pts)
    fg += f'<path d="{d}" fill="none" stroke="{WOOD_EDGE}" stroke-width="128" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 8)" stroke-opacity="0.35"/>'
    fg += f'<path d="{d}" fill="none" stroke="#A8723F" stroke-width="128" stroke-linecap="round" stroke-linejoin="round"/>'
    fg += f'<path d="{d}" fill="none" stroke="#D39A5C" stroke-width="100" stroke-linecap="round" stroke-linejoin="round"/>'
    fg += f'<path d="{d}" fill="none" stroke="#E6BC85" stroke-width="40" stroke-linecap="round" stroke-linejoin="round" transform="translate(-4 -8)" stroke-opacity="0.7"/>'
    # Paw prints along the trail (dirtPrint), a bolder one at the start.
    for (x, y, rot) in [(560, 712, 95), (690, 575, 165), (480, 432, 255), (395, 380, 230)]:
        fg += paw(x, y, 46, '#A8723F', rot=rot)
    fg += paw(262, 752, 84, WOOD_EDGE, rot=78)
    # Stones 1-2-3.
    for (x, y), k in zip([(470, 730), (640, 470), (330, 310)], '123'):
        r = 74
        fg += f'<circle cx="{x}" cy="{y + 14}" r="{r}" fill="{PEB_RIM}" stroke="{WOOD_EDGE}" stroke-width="12"/>'
        fg += f'<circle cx="{x}" cy="{y}" r="{r}" fill="{PEB_LOW}" stroke="{WOOD_EDGE}" stroke-width="12"/>'
        fg += f'<circle cx="{x - 4}" cy="{y - 8}" r="{r * 0.78}" fill="{PEB_TOP}"/>'
        fg += (f'<text x="{x}" y="{y + 30}" font-family="Fredoka" font-size="104" text-anchor="middle" fill="{WOOD_EDGE}">{k}</text>')
    # Flag at the end.
    fx, fy = 660, 262
    fg += f'<ellipse cx="{fx}" cy="{fy + 4}" rx="34" ry="14" fill="{WOOD_EDGE}" fill-opacity="0.4"/>'
    fg += f'<line x1="{fx}" y1="{fy}" x2="{fx}" y2="{fy - 220}" stroke="{WOOD_EDGE}" stroke-width="26" stroke-linecap="round"/>'
    fg += f'<line x1="{fx}" y1="{fy}" x2="{fx}" y2="{fy - 220}" stroke="{WOOD}" stroke-width="12" stroke-linecap="round"/>'
    flag = f'M{fx + 6} {fy - 214} C{fx + 70} {fy - 240} {fx + 110} {fy - 190} {fx + 175} {fy - 205} L{fx + 150} {fy - 150} L{fx + 175} {fy - 95} C{fx + 110} {fy - 80} {fx + 70} {fy - 130} {fx + 6} {fy - 104}Z'
    fg += f'<path d="{flag}" fill="{CORAL}" stroke="{WOOD_EDGE}" stroke-width="12" stroke-linejoin="round"/>'
    fg += f'<path d="M{fx + 20} {fy - 196} C{fx + 70} {fy - 214} {fx + 100} {fy - 180} {fx + 150} {fy - 190}" fill="none" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="12" stroke-linecap="round"/>'
    return bg, fg


def concept3(pack):
    """Logic grid with a check: chunky wooden 3x3, leaves ruling out cells, one glowing critter cell, green check badge."""
    bg = cream_bg('bg3', warm='#EFD5A4')
    X0, Y0, X1, Y1 = 140, 150, 860, 870
    fg = DEFS + wood_frame('f3', X0, Y0, X1, Y1, 100, depth=34, seed=3)
    m, gap = 62, 34
    cw = (X1 - X0 - 2 * m - 2 * gap) / 3
    fg += '<radialGradient id="glow3"><stop offset="0" stop-color="#FFF6C8"/><stop offset="0.6" stop-color="#FFD95E"/>' \
          f'<stop offset="1" stop-color="{GOLD}"/></radialGradient>'
    marks = {(0, 0): 'leaf', (0, 1): 'leaf', (1, 0): 'leaf', (1, 1): 'critter', (2, 2): 'leaf', (1, 2): 'leaf', (2, 1): 'leaf'}
    for r in range(3):
        for c in range(3):
            x, y = X0 + m + c * (cw + gap), Y0 + m + r * (cw + gap)
            lit = marks.get((r, c)) == 'critter'
            fg += rrect(x - 4, y - 6, x + cw + 4, y + cw + 2, 34, fill=WOOD_EDGE)   # recess
            if lit:
                fg += rrect(x - 18, y - 18, x + cw + 18, y + cw + 18, 48, fill='#FFE27A', fill_opacity=0.9, filter='url(#blur14)')
            fg += rrect(x, y + 10, x + cw, y + cw, 30, fill=GOLD_EDGE if lit else PAPER_EDGE)
            fg += rrect(x, y, x + cw, y + cw - 10, 30, fill='url(#glow3)' if lit else TILE_EMPTY)
            fg += rrect(x + 14, y + 10, x + cw - 14, y + 30, 10, fill='#FFFFFF', fill_opacity=0.45)
            cx, cy = x + cw / 2, y + cw / 2 - 4
            if marks.get((r, c)) == 'leaf':
                fg += leaf(cx, cy, cw * 0.56)
            elif lit:
                fg += f'<ellipse cx="{cx}" cy="{cy + cw * 0.33}" rx="{cw * 0.28}" ry="{cw * 0.06}" fill="{WOOD_EDGE}" fill-opacity="0.3"/>'
                fg += critter(pack, 'chick', cx, cy + 4, cw * 0.70)
    fg += check_badge(X1 - 28, Y0 + 20, 118)
    return bg, fg


def concept4(pack):
    """Paw-print grid: a wooden 5x5 board whose filled cells draw a paw print, on soft sage."""
    bg = '''<defs><radialGradient id="g4" cx="0.5" cy="0.4" r="0.78">
      <stop offset="0" stop-color="#E4F3CF"/><stop offset="0.6" stop-color="#C9E6A8"/><stop offset="1" stop-color="#A3CF7E"/>
      </radialGradient></defs><rect width="1024" height="1024" fill="url(#g4)"/>'''
    X0, Y0, X1, Y1 = 130, 130, 870, 870
    fg = DEFS + wood_frame('f4', X0, Y0, X1, Y1, 96, depth=30, seed=4)
    n, m, gap = 4, 58, 14
    cw = (X1 - X0 - 2 * m - (n - 1) * gap) / n
    fg += rrect(X0 + m - 14, Y0 + m - 16, X1 - m + 14, Y1 - m + 12, 40, fill=WOOD_EDGE)
    cells = [(X0 + m + c * (cw + gap), Y0 + m + r * (cw + gap)) for r in range(n) for c in range(n)]
    clip = ''.join(rrect(x, y, x + cw, y + cw - 8, 20) for x, y in cells)
    clip_lip = ''.join(rrect(x, y + 8, x + cw, y + cw, 20) for x, y in cells)
    fg += f'<clipPath id="cells4">{clip}</clipPath><clipPath id="lips4">{clip_lip}</clipPath>'
    for x, y in cells:
        fg += rrect(x, y + 8, x + cw, y + cw, 20, fill=PAPER_EDGE)
        fg += rrect(x, y, x + cw, y + cw - 8, 20, fill=TILE_EMPTY)
    # A paw print stamped across the cells: toes over single cells, the pad over the bottom three rows.
    def ctr(r, c):
        return X0 + m + c * (cw + gap) + cw / 2, Y0 + m + r * (cw + gap) + cw / 2
    toes = ''
    for (r, c), a in [((1, 0), -24), ((0, 1), -8), ((0, 2), 8), ((1, 3), 24)]:
        x, y = ctr(r, c)
        toes += f'<ellipse cx="{x}" cy="{y}" rx="{cw * 0.36}" ry="{cw * 0.44}" transform="rotate({a} {x} {y})"/>'
    px, py = ctr(2.42, 1.5)
    s_ = cw * 3.75
    pad = (f'<path d="M{px} {py - s_ * 0.26} C{px + s_ * 0.22} {py - s_ * 0.26} {px + s_ * 0.40} {py + s_ * 0.0} '
           f'{px + s_ * 0.36} {py + s_ * 0.13} C{px + s_ * 0.32} {py + s_ * 0.24} {px + s_ * 0.16} {py + s_ * 0.21} {px} {py + s_ * 0.20} '
           f'C{px - s_ * 0.16} {py + s_ * 0.21} {px - s_ * 0.32} {py + s_ * 0.24} {px - s_ * 0.36} {py + s_ * 0.13} '
           f'C{px - s_ * 0.40} {py + s_ * 0.0} {px - s_ * 0.22} {py - s_ * 0.26} {px} {py - s_ * 0.26}Z"/>')
    tilt = f'<g transform="rotate(-12 {px} {(Y0 + Y1) / 2})">{toes}{pad}</g>'
    fg += f'<g clip-path="url(#lips4)" fill="#A9502A">{tilt}</g>'
    fg += f'<g clip-path="url(#cells4)" fill="#E07B4C">{tilt}</g>'
    for x, y in cells:
        fg += rrect(x + 10, y + 7, x + cw - 10, y + 20, 6, fill='#FFFFFF', fill_opacity=0.4)
    return bg, fg


CONCEPTS = {1: concept1, 2: concept2, 3: concept3, 4: concept4}
NAMES = {1: '1  Wooden Nests board', 2: '2  Trail path', 3: '3  Logic grid + check', 4: '4  Paw-print grid'}


# ---------------------------------------------------------------- rendering

def svg_doc(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}" width="{SIZE}" height="{SIZE}" '
            f'style="position:absolute;left:0;top:0">{FONT_CSS}{body}</svg>')


def place(fg, scale, center=(500, 500)):
    return f'<g transform="translate({SIZE / 2} {SIZE / 2}) scale({scale}) translate({-center[0]} {-center[1]})">{fg}</g>'


def fit(fg, tmp):
    a = np.array(render_svg(place(fg, 1.0), tmp, 'fit'))[:, :, 3] > 128
    ys, xs = np.nonzero(a)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    r = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max()
    return FIT_RADIUS / r, (cx - SIZE / 2 + 500, cy - SIZE / 2 + 500)


def render_svg(body, tmp, name):
    svg = Path(tmp) / f'{name}.svg'
    png = Path(tmp) / f'{name}.png'
    svg.write_text(svg_doc(body))
    subprocess.run([CHROME, '--headless', '--disable-gpu', '--hide-scrollbars', '--default-background-color=00000000',
                    '--force-device-scale-factor=1', f'--window-size={SIZE},{SIZE}', '--virtual-time-budget=2000',
                    f'--screenshot={png}', svg.as_uri()], check=True, capture_output=True)
    return Image.open(png).convert('RGBA').crop((0, 0, SIZE, SIZE))


def build(pack, n):
    bg, fg = CONCEPTS[n](pack)
    out = HERE.parent / 'assets' / 'icon' if n == CHOSEN else HERE / f'concept{n}'
    out.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        render_svg(bg, tmp, 'bg').convert('RGB').save(out / 'background.png', optimize=True)
        k, c = fit(fg, tmp)
        print(f'concept{n}: scale {k:.3f} center {c[0]:.0f},{c[1]:.0f}')
        render_svg(place(fg, k, c), tmp, 'fg').save(out / 'foreground.png', optimize=True)
        render_svg(bg + place(fg, k * ICON_BOOST, c), tmp, 'icon').convert('RGB').save(out / 'icon.png', optimize=True)


# ---------------------------------------------------------------- comparison sheet

def shape_mask(s, shape):
    yy, xx = np.mgrid[0:s, 0:s]
    u = (xx + 0.5) / s * 2 - 1
    v = (yy + 0.5) / s * 2 - 1
    if shape == 'circle':
        m = u * u + v * v <= 1
    elif shape == 'squircle':
        m = np.abs(u) ** 4.2 + np.abs(v) ** 4.2 <= 1
    else:
        r = 0.45
        ax, ay = np.maximum(np.abs(u) - (1 - r), 0), np.maximum(np.abs(v) - (1 - r), 0)
        m = ax * ax + ay * ay <= r * r
    return Image.fromarray((m * 255).astype(np.uint8))


def adaptive_view(n, px, shape):
    d = HERE / f'concept{n}'
    comp = Image.open(d / 'background.png').convert('RGBA')
    comp.alpha_composite(Image.open(d / 'foreground.png').convert('RGBA'))
    vis = round(SIZE * 72 / 108)
    o = (SIZE - vis) // 2
    big = comp.crop((o, o, o + vis, o + vis)).resize((px * 4, px * 4), Image.LANCZOS)
    big.putalpha(shape_mask(px * 4, shape))
    return big.resize((px, px), Image.LANCZOS)


def legacy_view(n, px):
    im = Image.open(HERE / f'concept{n}' / 'icon.png').convert('RGBA').resize((px * 4, px * 4), Image.LANCZOS)
    im.putalpha(shape_mask(px * 4, 'rounded'))
    return im.resize((px, px), Image.LANCZOS)


def comparison():
    font = ImageFont.load_default(size=22)
    small = ImageFont.load_default(size=16)
    col_w, pad, big = 560, 24, 512
    panel_h = 18 + 96 + 40 + 48 + 40
    cols = (1, 2, 3, 4)
    H = pad + 34 + big + pad + 2 * (panel_h + pad)
    W = pad + len(cols) * col_w
    sheet = Image.new('RGBA', (W, H), (245, 242, 236, 255))
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(cols):
        x = pad + i * col_w
        d.text((x, pad), NAMES[n], fill=(40, 40, 40), font=font)
        im = Image.open(HERE / f'concept{n}' / 'icon.png').convert('RGBA').resize((big, big), Image.LANCZOS)
        sheet.alpha_composite(im, (x, pad + 34))
        for j, (bgc, fgc, label) in enumerate([((236, 240, 246), (60, 60, 60), 'light'), ((22, 24, 30), (220, 220, 220), 'dark')]):
            y0 = pad + 34 + big + pad + j * (panel_h + pad)
            d.rounded_rectangle([x, y0, x + big, y0 + panel_h], radius=24, fill=bgc)
            yy = y0 + 18
            for px in (96, 48):
                xx = x + 18
                for kind in ('circle', 'squircle', 'legacy'):
                    icon = legacy_view(n, px) if kind == 'legacy' else adaptive_view(n, px, kind)
                    sheet.alpha_composite(icon, (xx, yy))
                    d.text((xx, yy + px + 6), f'{kind} {px}', fill=fgc, font=small)
                    xx += max(px, 110) + 50
                yy += px + 40
            d.text((x + big - 70, y0 + 10), label, fill=fgc, font=small)
    sheet.convert('RGB').save(HERE / 'comparison.png', optimize=True)


CHOSEN = 2


def main():
    pack = sys.argv[1]
    n = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[2] == '--concept' else CHOSEN
    build(pack, n)


if __name__ == '__main__':
    main()
