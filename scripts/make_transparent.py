#!/usr/bin/env python
"""
Script to convert white backgrounds to transparent in portrait images.
Uses a tolerance threshold to handle near-white pixels.
"""

import os
from PIL import Image

# Configuration
PORTRAIT_DIR = "assets/cards/portraits"
TOLERANCE = 30  # How close to white to consider as "white" (0-255)

def make_white_transparent(img, tolerance=30):
    """Convert white/near-white pixels to transparent."""
    # Ensure image has alpha channel
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Check if pixel is close to white
            if r >= 255 - tolerance and g >= 255 - tolerance and b >= 255 - tolerance:
                # Make it fully transparent
                pixels[x, y] = (r, g, b, 0)

    return img

def process_portraits():
    """Process all portrait images in the directory."""
    if not os.path.exists(PORTRAIT_DIR):
        print(f"Directory not found: {PORTRAIT_DIR}")
        return

    files = [f for f in os.listdir(PORTRAIT_DIR) if f.lower().endswith('.png')]
    print(f"Found {len(files)} portrait files to process")

    for filename in files:
        filepath = os.path.join(PORTRAIT_DIR, filename)
        print(f"Processing: {filename}")

        try:
            img = Image.open(filepath)
            processed = make_white_transparent(img, TOLERANCE)
            processed.save(filepath, 'PNG')
            print(f"  -> Saved with transparent background")
        except Exception as e:
            print(f"  -> Error: {e}")

    print(f"\nCompleted processing {len(files)} files")

if __name__ == "__main__":
    process_portraits()