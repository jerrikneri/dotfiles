#!/usr/bin/env bash

set -euo pipefail

# Usage: compress_nfs_to_local_parallel.sh <nfs_source_dir> <local_dest_dir> [preset] [jobs]
# Optimized for 720p digitized VHS/8mm videos with powerful CPU (3950x)
# Uses parallel processing to maximize CPU utilization
#
# Environment variables:
#   LIGHTEN=1  - Add -color_range pc flag to brighten dark captures
#   DENOISE=1  - Apply light denoising to reduce VHS grain/noise (15-25% smaller files)

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <nfs_source_dir> <local_dest_dir> [preset] [jobs]"
  echo "  preset: extreme (default, CRF 25, slow), balanced (CRF 23, medium), fast (CRF 24, faster)"
  echo "  jobs: number of parallel encodes (default: 3 for 3950x)"
  echo ""
  echo "Optional environment variables:"
  echo "  LIGHTEN=1  - Brighten dark captures"
  echo "  DENOISE=1  - Reduce VHS grain/noise (smaller files, slight softening)"
  exit 1
fi

NFS_SOURCE="$1"
LOCAL_DEST="$2"
PRESET="${3:-extreme}"
JOBS="${4:-3}"  # 3 parallel jobs is good for 3950x (16c/32t)

# Check if GNU parallel is installed
if ! command -v parallel &> /dev/null; then
  echo "Error: GNU parallel is not installed"
  echo "Install on macOS: brew install parallel"
  echo "Install on Arch: sudo pacman -S parallel"
  echo "Install on Ubuntu/Debian: sudo apt install parallel"
  exit 1
fi

# Validate source exists
if [ ! -d "$NFS_SOURCE" ]; then
  echo "Error: NFS source directory does not exist: $NFS_SOURCE"
  exit 1
fi

# Create destination if it doesn't exist
mkdir -p "$LOCAL_DEST"

# Set ffmpeg parameters based on preset
# VHS source is already degraded, so we can be much more aggressive (CRF 28-32)
case "$PRESET" in
  extreme)
    CRF="32"
    PRESET_SPEED="veryslow"
    AUDIO_BITRATE="128k"
    DESC="Maximum compression, very slow encode (best for VHS)"
    ;;
  balanced)
    CRF="30"
    PRESET_SPEED="slow"
    AUDIO_BITRATE="128k"
    DESC="Balanced quality/speed (good for VHS)"
    ;;
  fast)
    CRF="28"
    PRESET_SPEED="medium"
    AUDIO_BITRATE="128k"
    DESC="Faster encode, good compression"
    ;;
  *)
    echo "Error: Unknown preset '$PRESET'. Use 'extreme', 'balanced', or 'fast'"
    exit 1
    ;;
esac

echo "Starting parallel compression from NFS to local SSD"
echo "Source: $NFS_SOURCE"
echo "Destination: $LOCAL_DEST"
echo "Parallel jobs: $JOBS"
echo "Preset: $PRESET - $DESC"
echo "  CRF: $CRF"
echo "  Speed: $PRESET_SPEED"
echo "  Audio: $AUDIO_BITRATE AAC"
if [ "${LIGHTEN:-0}" -eq 1 ]; then
  echo "  Color: Full range (brightening enabled)"
else
  echo "  Color: Standard range"
fi
if [ "${DENOISE:-0}" -eq 1 ]; then
  echo "  Denoise: Enabled (hqdn3d light)"
else
  echo "  Denoise: Disabled"
fi
echo ""

# Export variables for parallel function
export LOCAL_DEST CRF PRESET_SPEED AUDIO_BITRATE LIGHTEN DENOISE

# Function to process a single video (will be called by GNU parallel)
process_video() {
  local f="$1"
  local filename=$(basename "$f")
  local name="${filename%.*}"
  local output="$LOCAL_DEST/${name}-hevc.mp4"

  # Skip if already exists
  if [ -f "$output" ]; then
    echo "[SKIP] $filename - already exists"
    return 0
  fi

  echo "[START] $filename"

  # Build flags
  EXTRA_FLAGS=()
  if [ "${LIGHTEN:-0}" -eq 1 ]; then
    EXTRA_FLAGS+=("-color_range" "pc")
  fi

  # Build video filter chain
  VF_FILTERS=()
  if [ "${DENOISE:-0}" -eq 1 ]; then
    VF_FILTERS+=("-vf" "hqdn3d=1.5:1.5:3:3")
  fi

  # x265 threading params - reduce per-job threads since we're running multiple jobs
  # Let each job use fewer threads so multiple jobs can run efficiently
  X265_PARAMS="pools=+:frame-threads=0"

  # Run ffmpeg
  if ffmpeg -hide_banner -loglevel error -stats -i "$f" \
    -c:v libx265 \
    -preset "$PRESET_SPEED" \
    -crf "$CRF" \
    -pix_fmt yuv420p \
    "${VF_FILTERS[@]}" \
    -x265-params "$X265_PARAMS" \
    "${EXTRA_FLAGS[@]}" \
    -c:a aac \
    -b:a "$AUDIO_BITRATE" \
    -movflags +faststart \
    -tag:v hvc1 \
    "$output" 2>&1; then

    # Show file size comparison
    if command -v du &> /dev/null; then
      src_size=$(du -h "$f" | cut -f1)
      dst_size=$(du -h "$output" | cut -f1)
      echo "[DONE] $filename ($src_size → $dst_size)"
    else
      echo "[DONE] $filename"
    fi
    return 0
  else
    echo "[FAIL] $filename"
    rm -f "$output"
    return 1
  fi
}

# Export the function so parallel can use it
export -f process_video

# Find all video files and process them in parallel
find "$NFS_SOURCE" -maxdepth 1 -type f \
  \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" \) \
  | parallel -j "$JOBS" --bar --eta process_video {}

echo ""
echo "=========================================="
echo "Compression complete"
echo "Check output above for individual file results"
echo "=========================================="
