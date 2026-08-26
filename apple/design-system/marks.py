"""App marks for Sill and Aubade, drawn in the Soft Stone language.

Neumorphism is brutal at 40px - the shadows that carry the whole effect are the
first thing to vanish. So both marks are built on a silhouette that survives
without any relief at all, and the relief is a finish on top rather than the
idea itself. Same rule as the design system: relief encodes structure, never
meaning.
"""
from PIL import Image, ImageDraw, ImageFilter
import os, math

S = 1024
OUT = os.path.dirname(os.path.abspath(__file__))

SILL_GROUND, SILL_RAISED = (236, 233, 228), (243, 240, 235)
SILL_SHADE, SILL_LIGHT   = (198, 192, 182), (255, 255, 255)
SILL_ACCENT              = (91, 107, 168)

AUB_GROUND, AUB_SHADE, AUB_LIGHT = (35, 34, 32), (14, 13, 11), (62, 58, 52)
AUB_AMBER, AUB_AMBER_HI          = (201, 138, 75), (240, 187, 122)


def layer():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def mask_of(draw_fn):
    """A single-channel mask from a draw callback."""
    m = Image.new("L", (S, S), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def relief(base, shape_mask, shade, light, offset, blur, strength=1.0):
    """The two-shadow bevel: dark down-right, light up-left, always.

    Light is fixed top-left in the app, so it is fixed top-left here too - an
    icon lit from anywhere else stops belonging to the same object.
    """
    for colour, (dx, dy) in ((shade, (offset, offset)), (light, (-offset, -offset))):
        glow = Image.new("RGBA", (S, S), colour + (int(255 * strength),))
        m = shape_mask.filter(ImageFilter.GaussianBlur(blur))
        shifted = Image.new("L", (S, S), 0)
        shifted.paste(m, (dx, dy))
        glow.putalpha(shifted)
        base.alpha_composite(glow)
    return base


def fill(base, shape_mask, colour):
    solid = Image.new("RGBA", (S, S), colour + (255,))
    solid.putalpha(shape_mask)
    base.alpha_composite(solid)
    return base


# ── Sill ──────────────────────────────────────────────────────────────────
# A ledge, and one stone resting on it. That is the whole app: a place you set
# things down, and the light that lands there in the morning.

def sill():
    img = Image.new("RGBA", (S, S), SILL_GROUND + (255,))

    # A wash of morning light from the top-left, so the ground isn't flat.
    wash = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wash)
    for i in range(60):
        a = int(16 * (1 - i / 60))
        wd.ellipse([-S * 0.35 - i * 6, -S * 0.45 - i * 6, S * 0.75 + i * 6, S * 0.6 + i * 6],
                   fill=(255, 255, 255, a))
    img.alpha_composite(wash)

    ledge_top, ledge_h = 618, 138
    ledge = mask_of(lambda d: d.rounded_rectangle(
        [116, ledge_top, S - 116, ledge_top + ledge_h], radius=40, fill=255))

    # The stone sits *on* the ledge — a couple of pixels of overlap is what
    # stops it reading as two shapes that happen to be near each other.
    stone_s = 302
    stone_x = (S - stone_s) // 2 - 26
    stone_y = ledge_top - stone_s + 6
    stone = mask_of(lambda d: d.rounded_rectangle(
        [stone_x, stone_y, stone_x + stone_s, stone_y + stone_s], radius=94, fill=255))

    # The stone casts onto the ledge — the one cue that says "resting on",
    # and the reason the mark reads as depth rather than two floating shapes.
    cast = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cm = mask_of(lambda d: d.ellipse(
        [stone_x + 30, ledge_top - 20, stone_x + stone_s + 168, ledge_top + 62], fill=125))
    cast_solid = Image.new("RGBA", (S, S), SILL_SHADE + (255,))
    cast_solid.putalpha(cm.filter(ImageFilter.GaussianBlur(26)))
    cast.alpha_composite(cast_solid)

    relief(img, ledge, SILL_SHADE, SILL_LIGHT, 17, 24, 0.95)
    fill(img, ledge, SILL_RAISED)
    img.alpha_composite(cast)

    relief(img, stone, SILL_SHADE, SILL_LIGHT, 19, 26, 0.85)
    fill(img, stone, SILL_ACCENT)

    # A specular edge on the stone: light top-left, so the highlight is too.
    spec = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(spec)
    sd.rounded_rectangle([stone_x + 18, stone_y + 16, stone_x + stone_s - 18, stone_y + stone_s - 16],
                         radius=82, outline=(255, 255, 255, 62), width=8)
    spec = spec.filter(ImageFilter.GaussianBlur(5))
    spec.putalpha(spec.getchannel("A").point(lambda v: int(v * 0.9)))
    img.alpha_composite(spec)
    return img


# ── Aubade ────────────────────────────────────────────────────────────────
# A sun that hasn't finished rising, over a carved horizon. Half a disc above a
# line is about as legible as a silhouette gets at 40px.

def aubade():
    img = Image.new("RGBA", (S, S), AUB_GROUND + (255,))

    horizon_y = 664
    cx, r = S // 2, 268

    # Sky glow, strongest just above the horizon.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for i in range(70):
        t = i / 70
        a = int(60 * (1 - t) ** 2)
        rad = r + i * 9
        gd.ellipse([cx - rad * 1.5, horizon_y - rad, cx + rad * 1.5, horizon_y + rad * 0.9],
                   fill=AUB_AMBER + (a,))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(glow)

    # The disc, clipped at the horizon: it is still coming up.
    disc = mask_of(lambda d: d.ellipse([cx - r, horizon_y - r, cx + r, horizon_y + r], fill=255))
    clip = mask_of(lambda d: d.rectangle([0, 0, S, horizon_y], fill=255))
    disc = Image.composite(disc, Image.new("L", (S, S), 0), clip)

    grad = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gdd = ImageDraw.Draw(grad)
    for y in range(horizon_y - r, horizon_y + 1):
        t = (y - (horizon_y - r)) / max(1, r)
        colour = tuple(int(AUB_AMBER_HI[i] + (AUB_AMBER[i] - AUB_AMBER_HI[i]) * (1 - t)) for i in range(3))
        gdd.line([(0, y), (S, y)], fill=colour + (255,))
    grad.putalpha(disc)
    img.alpha_composite(grad)

    # The horizon: carved, not drawn. A groove reads as the sill of the sky.
    # Carved, not painted: a shallow groove with the sun catching its far lip.
    # A solid bar here reads as a censor stripe and kills the depth.
    groove = mask_of(lambda d: d.rounded_rectangle(
        [118, horizon_y, S - 118, horizon_y + 18], radius=9, fill=255))
    relief(img, groove, AUB_LIGHT, AUB_SHADE, 7, 11, 0.85)
    fill(img, groove, (28, 27, 25))

    lip = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lip)
    ld.rounded_rectangle([118, horizon_y - 4, S - 118, horizon_y + 16], radius=9,
                         outline=AUB_AMBER_HI + (150,), width=4)
    img.alpha_composite(lip.filter(ImageFilter.GaussianBlur(4)))
    return img


def export(img, name):
    img = img.convert("RGB")
    img.save(os.path.join(OUT, f"{name}-1024.png"))
    return img


def sheet(pairs):
    sizes = [180, 120, 80, 40]
    pad, gap = 46, 34
    w = pad * 2 + 220 + gap + sum(sizes) + gap * len(sizes)
    h = pad * 2 + len(pairs) * (220 + gap)
    canvas = Image.new("RGB", (w, h), (250, 249, 247))
    d = ImageDraw.Draw(canvas)
    y = pad
    for name, img in pairs:
        canvas.paste(img.resize((220, 220), Image.LANCZOS), (pad, y))
        x = pad + 220 + gap
        for s in sizes:
            canvas.paste(img.resize((s, s), Image.LANCZOS), (x, y + (220 - s) // 2))
            d.text((x, y + 220 - 14), f"{s}px", fill=(150, 146, 140))
            x += s + gap
        d.text((pad, y + 224), name, fill=(90, 87, 82))
        y += 220 + gap
    canvas.save(os.path.join(OUT, "contact-sheet.png"))


s_img = export(sill(), "sill")
a_img = export(aubade(), "aubade")
sheet([("Sill", s_img), ("Aubade", a_img)])
print("wrote", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
