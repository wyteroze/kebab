#!/usr/bin/env python3
# Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

import argparse
import struct
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required (install using `pip install pillow`)")

MAX_DIM = 65535

def png_to_bmp(src_path: str, dst_path: str, force_32: bool = False) -> None:
    img = Image.open(src_path)

    has_alpha = force_32 or (img.mode in ("RGBA", "LA", "PA") or "transparency" in img.info)
    img = img.convert("RGBA" if has_alpha else "RGB")

    width, height = img.size
    if not (1 <= width <= MAX_DIM and 1 <= height <= MAX_DIM):
        sys.exit(f"error: dimensions {width}x{height} out of range [1, {MAX_DIM}]")

    bpp = 32 if has_alpha else 24
    bytes_per_pixel = bpp // 8
    row_stride = (width * bytes_per_pixel + 3) & ~3
    pixel_data_size = row_stride * height

    px = img.load()
    rows = bytearray()

    for y in range(height - 1, -1, -1):
        row = bytearray()
        for x in range(width):
            if has_alpha:
                r, g, b, a = px[x, y]
                row += bytes((b, g, r, a))
            else:
                r, g, b = px[x, y]
                row += bytes((b, g, r))
        row += b"\x00" * (row_stride - len(row))
        rows += row

    pixel_offset = 14 + 40
    file_size = pixel_offset + pixel_data_size

    with open(dst_path, "wb") as f:
        # File header
        f.write(b"BM")
        f.write(struct.pack("<I", file_size))
        f.write(struct.pack("<HH", 0, 0))
        f.write(struct.pack("<I", pixel_offset))

        # The BITMAPINFOHEADER
        f.write(struct.pack("<I", 40))
        f.write(struct.pack("<i", width))
        f.write(struct.pack("<i", height))
        f.write(struct.pack("<H", 1))
        f.write(struct.pack("<H", bpp))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", pixel_data_size))
        f.write(struct.pack("<i", 2835))
        f.write(struct.pack("<i", 2835))
        f.write(struct.pack("<I", 0))
        f.write(struct.pack("<I", 0))
        f.write(rows)

    print(f"wrote {dst_path}: {width}x{height}, {bpp}bpp")


def main():
    ap = argparse.ArgumentParser(description="Convert a .png to a .bmp that works with the parser")
    ap.add_argument("input", help="source png")
    ap.add_argument("output", nargs="?", help="destination bmp (default is input with .bmp suffixed)")
    ap.add_argument("--force-32", action="store_true", help="makes 32bpp BGRA even if the source is opaque")

    args = ap.parse_args()

    out = args.output or (args.input.rsplit(".", 1)[0] + ".bmp")
    png_to_bmp(args.input, out, force_32=args.force_32)


if __name__ == "__main__":
    main()
