#!/usr/bin/env python3
import argparse
import base64
import json
import os
import struct
import urllib.request
import zlib
from pathlib import Path
from typing import Dict, List, Optional, Tuple


ROOT = Path(__file__).resolve().parents[1]
PROMPT_MANIFEST = ROOT / "FireflyForestGame" / "image_prompts" / "asset_manifest.json"
ASSET_CATALOG = ROOT / "FireflyForestGame" / "Assets.xcassets"
GENERATED_DIR = ROOT / "FireflyForestGame" / "generated_assets"
API_URL = "https://api.openai.com/v1/images/generations"


def load_manifest() -> List[Dict[str, str]]:
    return json.loads(PROMPT_MANIFEST.read_text(encoding="utf-8"))


def ensure_imageset(name: str) -> Path:
    path = ASSET_CATALOG / f"{name}.imageset"
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_contents_json(imageset_dir: Path, filename: str) -> None:
    contents = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"filename": filename, "idiom": "universal", "scale": "2x"},
            {"filename": filename, "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset_dir / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


def request_image(prompt: str, model: str, size: str) -> bytes:
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is required for remote image generation.")

    timeout_seconds = int(os.environ.get("OPENAI_IMAGE_TIMEOUT", "20"))
    payload = json.dumps({"model": model, "prompt": prompt, "size": size}).encode("utf-8")
    request = urllib.request.Request(
        API_URL,
        data=payload,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
        body = json.loads(response.read().decode("utf-8"))

    data = body.get("data", [])
    if not data:
        raise RuntimeError("Empty image generation response.")
    item = data[0]
    if "b64_json" in item:
        return base64.b64decode(item["b64_json"])
    if "url" in item:
        with urllib.request.urlopen(item["url"], timeout=timeout_seconds) as response:
            return response.read()
    raise RuntimeError("Unsupported image generation payload.")


def infer_remote_size(size_hint: str) -> str:
    size_hint = size_hint.lower()
    if "1624" in size_hint or "1792" in size_hint or "1536x2732" in size_hint:
        return "1024x1792"
    return "1024x1024"


def local_size(size_hint: str) -> Tuple[int, int]:
    normalized = size_hint.lower().replace("pt", "").replace(" ", "")
    if "x" in normalized:
        width_text, height_text = normalized.split("x", 1)
        width = int(float(width_text))
        height_digits = []
        for ch in height_text:
            if ch.isdigit() or ch == ".":
                height_digits.append(ch)
            else:
                break
        height = int(float("".join(height_digits)))
        return width, height
    return 512, 512


def palette(category: str) -> Tuple[Tuple[int, int, int], Tuple[int, int, int]]:
    category = category.lower()
    if "background" in category:
        return (20, 27, 53), (64, 184, 214)
    if "anchor" in category:
        return (35, 134, 178), (189, 241, 255)
    if "fragment" in category:
        return (212, 168, 67), (255, 234, 126)
    if "button" in category:
        return (52, 104, 160), (235, 247, 255)
    if "obstacle" in category:
        return (122, 48, 50), (205, 101, 82)
    if "portal" in category:
        return (71, 83, 219), (143, 225, 255)
    if "block" in category:
        return (108, 63, 160), (190, 163, 230)
    if "ball" in category:
        return (65, 168, 108), (164, 244, 185)
    return (50, 78, 128), (196, 215, 240)


def png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF)


def build_placeholder_png(width: int, height: int, primary: Tuple[int, int, int], accent: Tuple[int, int, int]) -> bytes:
    rows = []
    cx = width / 2.0
    cy = height / 2.0
    max_distance = max(1.0, (cx ** 2 + cy ** 2) ** 0.5)

    for y in range(height):
        row = bytearray([0])
        for x in range(width):
            dx = x - cx
            dy = y - cy
            distance = (dx * dx + dy * dy) ** 0.5 / max_distance
            t = min(1.0, max(0.0, 1.0 - distance * 1.2))
            r = int(primary[0] * (1 - t) + accent[0] * t)
            g = int(primary[1] * (1 - t) + accent[1] * t)
            b = int(primary[2] * (1 - t) + accent[2] * t)

            band = ((x // max(1, width // 12)) + (y // max(1, height // 12))) % 2
            if band == 0:
                r = min(255, r + 8)
                g = min(255, g + 8)
                b = min(255, b + 8)

            alpha = 255
            if width <= 256 and height <= 256:
                margin = max(6, min(width, height) // 10)
                if x < margin or y < margin or x >= width - margin or y >= height - margin:
                    alpha = 0
                if x > width * 0.22 and x < width * 0.78 and y > height * 0.22 and y < height * 0.78:
                    alpha = 255
            row.extend((r, g, b, alpha))
        rows.append(bytes(row))

    image_data = zlib.compress(b"".join(rows), 9)
    png = bytearray(b"\x89PNG\r\n\x1a\n")
    png.extend(png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
    png.extend(png_chunk(b"IDAT", image_data))
    png.extend(png_chunk(b"IEND", b""))
    return bytes(png)


def generate_assets(model: str, only_asset: Optional[str], allow_placeholder_fallback: bool) -> None:
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    for item in load_manifest():
        if only_asset and item["asset_name"] != only_asset:
            continue

        asset_name = item["asset_name"]
        filename = item["filename"]
        imageset_dir = ensure_imageset(asset_name)
        print(f"Generating {asset_name}", flush=True)

        try:
            png_bytes = request_image(item["prompt"], model, infer_remote_size(item["size_hint"]))
        except Exception as exc:
            if not allow_placeholder_fallback:
                raise
            width, height = local_size(item["size_hint"])
            primary, accent = palette(item["category"])
            print(f"Falling back to placeholder for {asset_name}: {exc}", flush=True)
            png_bytes = build_placeholder_png(width, height, primary, accent)

        (GENERATED_DIR / filename).write_bytes(png_bytes)
        (imageset_dir / filename).write_bytes(png_bytes)
        write_contents_json(imageset_dir, filename)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and package FireflyForest texture assets.")
    parser.add_argument("--model", default=os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-1"))
    parser.add_argument("--only", default=None, help="Only generate one asset by asset_name.")
    parser.add_argument("--no-placeholder-fallback", action="store_true")
    args = parser.parse_args()
    generate_assets(
        model=args.model,
        only_asset=args.only,
        allow_placeholder_fallback=not args.no_placeholder_fallback,
    )


if __name__ == "__main__":
    main()
