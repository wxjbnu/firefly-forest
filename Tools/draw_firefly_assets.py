#!/usr/bin/env python3
from pathlib import Path
import json
import math
import random

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSET_CATALOG = ROOT / "FireflyForestGame" / "Assets.xcassets"
GENERATED_DIR = ROOT / "FireflyForestGame" / "generated_assets"


def imageset(name):
    path = ASSET_CATALOG / f"{name}.imageset"
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_contents(path, filename):
    data = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"filename": filename, "idiom": "universal", "scale": "2x"},
            {"filename": filename, "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (path / "Contents.json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def save_asset(name, image):
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)
    filename = f"{name}.png"
    out = imageset(name)
    image.save(out / filename)
    image.save(GENERATED_DIR / filename)
    write_contents(out, filename)


def rounded_rect(size, radius, fill, outline=None, width=1):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=fill, outline=outline, width=width)
    return img


def draw_background():
    w, h = 750, 1624
    img = Image.new("RGB", (w, h), (6, 16, 26))
    pix = img.load()
    for y in range(h):
        t = y / h
        for x in range(w):
            moon = math.exp(-(((x - w * 0.70) / 300) ** 2 + ((y - h * 0.16) / 260) ** 2))
            mist = math.exp(-((y - h * 0.68) / 360) ** 2)
            r = int(8 + 12 * (1 - t) + moon * 34 + mist * 10)
            g = int(18 + 35 * (1 - t) + moon * 48 + mist * 28)
            b = int(34 + 55 * (1 - t) + moon * 58 + mist * 34)
            pix[x, y] = (r, g, b)

    d = ImageDraw.Draw(img, "RGBA")
    random.seed(19)
    for _ in range(34):
        x = random.randint(-60, w + 40)
        height = random.randint(260, 820)
        y0 = random.randint(-80, h - 180)
        trunk_w = random.randint(13, 28)
        color = random.choice([(14, 33, 29, 150), (19, 47, 39, 130), (38, 28, 24, 95)])
        d.rounded_rectangle((x, y0, x + trunk_w, y0 + height), radius=trunk_w // 2, fill=color)
        if random.random() < 0.65:
            d.line((x + trunk_w // 2, y0 + 80, x + trunk_w // 2 + random.randint(-90, 90), y0 + random.randint(120, 220)), fill=color, width=max(4, trunk_w // 3))

    for _ in range(80):
        x = random.randint(30, w - 30)
        y = random.randint(int(h * 0.16), int(h * 0.84))
        radius = random.randint(2, 5)
        alpha = random.randint(35, 115)
        d.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 211, 80, alpha))

    fog = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    for band in range(7):
        y = int(h * (0.20 + band * 0.105))
        fd.ellipse((-120, y - 80, w + 120, y + 120), fill=(92, 153, 151, 16))
    fog = fog.filter(ImageFilter.GaussianBlur(18))
    return Image.alpha_composite(img.convert("RGBA"), fog)


def draw_firefly(name, core, wing):
    size = 192
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = size // 2, size // 2
    for r, a in [(72, 20), (52, 35), (34, 65)]:
        gd.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*core, a))
    glow = glow.filter(ImageFilter.GaussianBlur(8))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((42, 64, 92, 110), fill=(*wing, 120), outline=(255, 255, 255, 90), width=3)
    d.ellipse((100, 64, 150, 110), fill=(*wing, 120), outline=(255, 255, 255, 90), width=3)
    d.rounded_rectangle((78, 58, 114, 132), radius=17, fill=(28, 37, 32, 240), outline=(250, 229, 132, 170), width=2)
    d.ellipse((74, 40, 118, 78), fill=(31, 42, 36, 245), outline=(244, 221, 118, 160), width=2)
    d.ellipse((84, 126, 108, 158), fill=(*core, 235), outline=(255, 255, 220, 180), width=2)
    d.line((84, 48, 60, 26), fill=(252, 218, 114, 150), width=3)
    d.line((108, 48, 132, 26), fill=(252, 218, 114, 150), width=3)
    save_asset(name, img)


def draw_catcher():
    img = Image.new("RGBA", (220, 220), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((58, 38, 162, 142), fill=(255, 192, 77, 45), outline=(255, 219, 130, 180), width=6)
    d.rounded_rectangle((80, 72, 140, 154), radius=18, fill=(38, 74, 65, 235), outline=(255, 214, 104, 220), width=5)
    d.rectangle((91, 84, 129, 140), fill=(255, 202, 87, 80))
    d.arc((70, 44, 150, 116), 200, 340, fill=(255, 224, 139, 220), width=6)
    d.line((138, 146, 184, 188), fill=(116, 75, 44, 240), width=12)
    d.line((142, 144, 188, 186), fill=(247, 213, 130, 135), width=3)
    save_asset("ff_player_lantern", img)


def draw_lantern_button():
    img = rounded_rect((420, 150), 48, (18, 46, 43, 235), (239, 203, 105, 210), 4)
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle((26, 38, 96, 112), radius=20, fill=(37, 75, 64, 255), outline=(255, 216, 106, 230), width=4)
    d.ellipse((16, 22, 106, 82), fill=(255, 195, 76, 55), outline=(255, 221, 126, 190), width=4)
    d.rectangle((44, 54, 78, 103), fill=(255, 207, 90, 115))
    for x in range(130, 386, 34):
        d.ellipse((x, 65, x + 13, 78), fill=(255, 220, 111, 175))
    save_asset("ff_lantern_button", img)


def draw_info_panel():
    img = rounded_rect((520, 150), 44, (12, 36, 50, 230), (92, 164, 160, 190), 4)
    d = ImageDraw.Draw(img, "RGBA")
    for x in range(42, 492, 42):
        d.ellipse((x, 57, x + 17, 74), fill=(255, 219, 102, 150))
    d.line((48, 96, 470, 96), fill=(119, 194, 178, 85), width=5)
    save_asset("ff_info_panel", img)


def draw_button():
    img = rounded_rect((620, 170), 58, (24, 80, 63, 246), (255, 221, 119, 220), 5)
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle((18, 16, 602, 154), radius=50, outline=(90, 174, 145, 150), width=5)
    for x in range(70, 565, 80):
        d.ellipse((x, 36, x + 18, 54), fill=(255, 219, 98, 120))
    save_asset("ff_button_wide", img)


def draw_panel():
    img = rounded_rect((700, 980), 42, (7, 36, 26, 245), (80, 132, 74, 220), 5)
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle((18, 18, 682, 962), radius=34, outline=(35, 84, 56, 170), width=5)
    save_asset("ff_play_panel", img)


def main():
    save_asset("forest_bg", draw_background())
    save_asset("Backgrounds", draw_background())
    draw_firefly("ff_firefly_gold", (255, 205, 73), (255, 237, 166))
    draw_firefly("ff_firefly_green", (117, 245, 123), (190, 255, 193))
    draw_firefly("ff_firefly_blue", (111, 198, 255), (196, 235, 255))
    draw_catcher()
    draw_lantern_button()
    draw_info_panel()
    draw_button()
    draw_panel()


if __name__ == "__main__":
    main()
