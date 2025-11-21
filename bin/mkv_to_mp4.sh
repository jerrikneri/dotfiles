#!/bin/bash

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${INPUT_DIR}/converted"

mkdir -p "$OUTPUT_DIR"

for f in "$INPUT_DIR"/*.mkv; do
  [ -e "$f" ] || continue

  filename=$(basename "$f" .mkv)
  output="$OUTPUT_DIR/${filename}-av1.mp4"

  if [ -f "$output" ]; then
    echo "Skipping $filename - already exists"
    continue
  fi

  echo "Converting: $filename"

  ffmpeg -n -i "$f" \
    -c:v libsvtav1 \
    -crf 35 \
    -preset 5 \
    -c:a aac \
    -b:a 128k \
    -movflags +faststart \
    "$output"

  echo "Done: $filename"
done

echo "All conversions complete"
