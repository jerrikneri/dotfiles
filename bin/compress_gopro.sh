#!/usr/bin/env bash

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${INPUT_DIR}/converted"

mkdir -p "$OUTPUT_DIR"

for f in "$INPUT_DIR"/*.mkv; do
  [ -e "$f" ] || continue

  filename=$(basename "$f" .mkv)
  output="$OUTPUT_DIR/${filename}-hevc.mp4"

  if [ -f "$output" ]; then
    echo "Skipping $filename - already exists"
    continue
  fi

  echo "Converting: $filename"

  ffmpeg -hide_banner -i "$f" \
    -c:v hevc_videotoolbox \
    -b:v 20M \
    -c:a aac \
    -b:a 128k \
    -movflags +faststart \
    "$output"

  echo "Done: $filename"
done

echo "All conversions complete"
