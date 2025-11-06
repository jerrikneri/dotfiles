#!/bin/bash

# Usage: ./convert_upscale.sh [directory]
# Default to current directory if none is given
ROOT_DIR="${1:-.}"

# Find all .mkv files recursively
find "$ROOT_DIR" -type f -iname "*.mkv" | while read -r file; do
  dir=$(dirname "$file")
  base=$(basename "$file" .mkv)
  output="$dir/${base}_1080.mov"

  # Skip if output already exists
  if [ -f "$output" ]; then
    echo "Skipping existing file: $output"
    continue
  fi

  echo "Upscaling and converting: $file → $output"

  # ffmpeg command:
  # - upscale to 1080p with high-quality bicubic scaling
  # - encode to ProRes 422 for high-quality archival MOV
  # - preserve stereo audio
  ffmpeg -i "$file" \
    -vf "scale=1920:1080:flags=bicubic" \
    -c:v prores_ks -profile:v 3 \
    -c:a pcm_s16le \
    "$output"

  # Check for success
  if [ $? -eq 0 ]; then
    echo "Finished: $output"
  else
    echo "Error processing: $file"
  fi
done
