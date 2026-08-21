# Only download audio
yt-dl-a() {
  yt-dlp -x -f bestaudio/best "$1"
}

yt-del() {
  mv "$1" "$HOME/Movies/Youtube/Archive/"
}

yt-fav() {
  mv "$1" "$HOME/Movies/Youtube/Favorite/"
}

yt-transcribe() {
  local url="$1"
  local out="${2:-$HOME/Movies/Youtube/Transcripts}"

  if [ -z "$url" ]; then
    echo "Usage: yt-transcribe <youtube-url> [output_dir]" >&2
    return 1
  fi

  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "Error: ffmpeg is required for --convert-subs=srt" >&2
    return 1
  fi

  mkdir -p "$out"
  yt-dlp --write-auto-sub --convert-subs=srt --skip-download \
    -o "$out/%(title)s.%(ext)s" "$url"
}
