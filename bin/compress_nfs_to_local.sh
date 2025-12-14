#!/usr/bin/env bash

set -euo pipefail

# Usage: compress_nfs_to_local.sh <nfs_source_dir> <local_dest_dir> [preset]
# Optimized for 720p digitized VHS/8mm videos with powerful CPU (3950x)
# Uses CRF-based encoding for better quality/size balance
#
# Environment variables:
#   LIGHTEN=1  - Add -color_range pc flag to brighten dark captures

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <nfs_source_dir> <local_dest_dir> [preset]"
  echo "  preset: extreme (default, CRF 25, slow), balanced (CRF 23, medium), fast (CRF 24, faster)"
  echo ""
  echo "Optional environment variables:"
  echo "  LIGHTEN=1  - Brighten dark captures"
  exit 1
fi

NFS_SOURCE="$1"
LOCAL_DEST="$2"
PRESET="${3:-extreme}"

# Validate source exists
if [ ! -d "$NFS_SOURCE" ]; then
  echo "Error: NFS source directory does not exist: $NFS_SOURCE"
  exit 1
fi

# Create destination if it doesn't exist
mkdir -p "$LOCAL_DEST"

# Set ffmpeg parameters based on preset
# CRF scale: 0-51, LOWER=better quality/larger files, HIGHER=worse quality/smaller files
# For 720p VHS/8mm digitized content - optimized for degraded source at HD resolution
case "$PRESET" in
  extreme)
    CRF="25"
    PRESET_SPEED="slow"
    AUDIO_BITRATE="128k"
    DESC="Maximum compression, slow encode"
    ;;
  balanced)
    CRF="23"
    PRESET_SPEED="medium"
    AUDIO_BITRATE="128k"
    DESC="Balanced quality/speed"
    ;;
  fast)
    CRF="24"
    PRESET_SPEED="faster"
    AUDIO_BITRATE="128k"
    DESC="Faster encode, good compression"
    ;;
  *)
    echo "Error: Unknown preset '$PRESET'. Use 'extreme', 'balanced', or 'fast'"
    exit 1
    ;;
esac

echo "Starting compression from NFS to local SSD"
echo "Source: $NFS_SOURCE"
echo "Destination: $LOCAL_DEST"
echo "Preset: $PRESET - $DESC"
echo "  CRF: $CRF"
echo "  Speed: $PRESET_SPEED"
echo "  Audio: $AUDIO_BITRATE AAC"
if [ "${LIGHTEN:-0}" -eq 1 ]; then
  echo "  Color: Full range (brightening enabled)"
else
  echo "  Color: Standard range"
fi
echo ""

# Counter for stats
total=0
converted=0
skipped=0
failed=0

# Process all video files (mkv, mp4, mov, avi)
for ext in mkv mp4 mov avi MKV MP4 MOV AVI; do
  for f in "$NFS_SOURCE"/*."$ext"; do
    [ -e "$f" ] || continue

    total=$((total + 1))
    filename=$(basename "$f")
    name="${filename%.*}"
    output="$LOCAL_DEST/${name}-hevc.mp4"

    if [ -f "$output" ]; then
      echo "Skipping $filename - already exists"
      skipped=$((skipped + 1))
      continue
    fi

    echo "Converting: $filename"
    echo "  Source: $f"
    echo "  Dest: $output"

    # Use libx265 software encoding with CRF for optimal compression
    # -preset slow/medium for better compression (3950x can handle it)
    # -crf for constant quality (better than bitrate for archival)
    # -tag:v hvc1 for better compatibility with Apple devices
    # -color_range pc can help brighten dark captures (use LIGHTEN=1 env var)
    # x265-params to maximize CPU utilization on 3950x (32 threads)
    EXTRA_FLAGS=()
    if [ "${LIGHTEN:-0}" -eq 1 ]; then
      EXTRA_FLAGS+=("-color_range" "pc")
    fi

    # x265 threading params for maximum CPU usage
    # pools='+' enables multiple thread pools for better parallelism
    # frame-threads auto-detects optimal frame-level parallelism
    X265_PARAMS="pools=+:frame-threads=0"

    if ffmpeg -hide_banner -i "$f" \
      -c:v libx265 \
      -preset "$PRESET_SPEED" \
      -crf "$CRF" \
      -pix_fmt yuv420p \
      -x265-params "$X265_PARAMS" \
      "${EXTRA_FLAGS[@]}" \
      -c:a aac \
      -b:a "$AUDIO_BITRATE" \
      -movflags +faststart \
      -tag:v hvc1 \
      "$output"; then

      # Show file size comparison
      if command -v du &> /dev/null; then
        src_size=$(du -h "$f" | cut -f1)
        dst_size=$(du -h "$output" | cut -f1)
        echo "Done: $filename ($src_size → $dst_size)"
      else
        echo "Done: $filename"
      fi
      converted=$((converted + 1))
    else
      echo "Failed: $filename"
      # Remove partial file if conversion failed
      rm -f "$output"
      failed=$((failed + 1))
    fi
    echo ""
  done
done

echo "=========================================="
echo "Compression complete"
echo "Total files found: $total"
echo "Converted: $converted"
echo "Skipped (already exist): $skipped"
echo "Failed: $failed"
echo "=========================================="
