#!/usr/bin/env bash

# Set the root directory to start searching from
ROOT_DIR="${1:-.}" # Default to current directory if no argument

# Find all .mkv files recursively
find "$ROOT_DIR" -type f -iname "*.mkv" | while read -r file; do
  # Get directory and filename without extension
  dir=$(dirname "$file")
  base=$(basename "$file" .mkv)

  # Construct output file path
  output="$dir/$base.mov"

  # Skip if output already exists
  if [ -f "$output" ]; then
    echo "Skipping existing file: $output"
    continue
  fi

  echo "Converting: $file → $output"

  # Convert using ffmpeg (copy video and audio streams if H.264 + AAC)
  ffmpeg -i "$file" -c copy "$output"

  # Optional: Uncomment to remove original MKV after successful conversion
  # if [ $? -eq 0 ]; then
  #     rm "$file"
  # fi
done
