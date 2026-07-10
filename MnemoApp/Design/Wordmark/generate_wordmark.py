#!/usr/bin/env python3
"""Generate Mnemo's outlined Newsreader wordmark SVG from a local font source."""

import argparse
from pathlib import Path

from fontTools.pens.qu2cuPen import Qu2CuPen
from fontTools.pens.recordingPen import DecomposingRecordingPen, RecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("font", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    font = instantiateVariableFont(
        TTFont(args.font),
        {"wght": 400, "opsz": 72},
        inplace=False,
    )
    glyph_set = font.getGlyphSet()
    glyph_names = ["M", "n", "e", "m", "o"]
    tracking = -20.48  # -0.01em at the font's 2048 units-per-em scale.

    combined = RecordingPen()
    x_offset = 0.0
    for index, glyph_name in enumerate(glyph_names):
        source = DecomposingRecordingPen(glyph_set)
        glyph_set[glyph_name].draw(source)
        cubic = Qu2CuPen(combined, max_err=1.0, all_cubic=True)
        source.replay(TransformPen(cubic, (1, 0, 0, 1, x_offset, 0)))
        x_offset += glyph_set[glyph_name].width
        if index < len(glyph_names) - 1:
            x_offset += tracking

    points = [point for _, command_points in combined.value for point in command_points]
    x_min = min(point[0] for point in points)
    y_min = min(point[1] for point in points)
    x_max = max(point[0] for point in points)
    y_max = max(point[1] for point in points)
    width = x_max - x_min
    height = y_max - y_min

    commands: list[str] = []
    for command, command_points in combined.value:
        if command == "moveTo":
            x, y = command_points[0]
            commands.append(f"M{x:.3f},{y:.3f}")
        elif command == "lineTo":
            x, y = command_points[0]
            commands.append(f"L{x:.3f},{y:.3f}")
        elif command == "curveTo":
            (c1x, c1y), (c2x, c2y), (x, y) = command_points
            commands.append(
                f"C{c1x:.3f},{c1y:.3f} {c2x:.3f},{c2y:.3f} {x:.3f},{y:.3f}"
            )
        elif command == "closePath":
            commands.append("Z")

    svg = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width:.3f} {height:.3f}">
  <title>Mnemo Newsreader wordmark</title>
  <desc>Outlined Newsreader Regular, optical size 72, with -0.01em tracking.</desc>
  <g transform="translate({-x_min:.3f} {y_max:.3f}) scale(1 -1)">
    <path fill="#232820" d="{' '.join(commands)}"/>
  </g>
</svg>
"""
    args.output.write_text(svg, encoding="utf-8")


if __name__ == "__main__":
    main()
