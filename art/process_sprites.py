#!/usr/bin/env python3
"""Convert black-background sprites to transparent PNGs for Godot."""
import os
import numpy as np
from PIL import Image

SPRITE_DIR = os.path.dirname(os.path.abspath(__file__)) + "/sprites"
THRESHOLD = 40  # pixels darker than this on all channels become transparent

files = [f for f in os.listdir(SPRITE_DIR) if f.endswith(".png")]

for fname in files:
    path = os.path.join(SPRITE_DIR, fname)
    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.uint8)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    # Mark near-black pixels as transparent
    black_mask = (r.astype(int) + g.astype(int) + b.astype(int)) < (THRESHOLD * 3)
    data[black_mask, 3] = 0

    result = Image.fromarray(data, "RGBA")
    result.save(path)
    print(f"  {fname}: {img.size[0]}x{img.size[1]} -> transparent background removed")

print("Done.")
