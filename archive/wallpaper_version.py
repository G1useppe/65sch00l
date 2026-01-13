from PIL import Image, ImageDraw, ImageFont
from datetime import datetime
import os
import sys

# Configuration
BOX_WIDTH = 600
BOX_HEIGHT = 200
OFFSET = 25
PADDING = 10
FONT_SIZE = 60

# Known-good font locations (cross-platform)
FONT_PATHS = [
    "DejaVuSans.ttf",                                # Pillow-bundled
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",  # Linux
    "/Library/Fonts/Arial.ttf",                      # macOS
    "C:/Windows/Fonts/arial.ttf",                    # Windows
]

def load_font(size):
    for path in FONT_PATHS:
        try:
            return ImageFont.truetype(path, size)
        except IOError:
            continue
    print("ERROR: No TrueType font found. Please provide a .ttf file.")
    sys.exit(1)

def annotate_image(input_path, output_path=None):
    img = Image.open(input_path).convert("RGBA")
    draw = ImageDraw.Draw(img)

    img_w, img_h = img.size

    # Bottom-left corner of the text box
    x0 = OFFSET
    y0 = img_h - OFFSET - BOX_HEIGHT

    version_text = input("Enter version number (e.g. v1.2.3): ").strip()
    date_text = datetime.now().strftime("%B %d, %Y")

    font = load_font(FONT_SIZE)

    # Starting Y position inside box
    current_y = y0 + PADDING

    # Draw version (top line)
    draw.text(
        (x0 + PADDING, current_y),
        version_text,
        fill=(0, 0, 0, 255),
        font=font
    )

    # Measure line height for stacking
    _, line_height = draw.textsize(version_text, font=font)

    # Draw date (bottom line)
    draw.text(
        (x0 + PADDING, current_y + line_height),
        date_text,
        fill=(0, 0, 0, 255),
        font=font
    )

    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_annotated{ext}"

    img.save(output_path)
    print(f"Saved annotated image to: {output_path}")
    print(f"Font used: {font.path}")
    print(f"Font size: {FONT_SIZE}px")

if __name__ == "__main__":
    input_png = input("Path to PNG image: ").strip()
    annotate_image(input_png)
