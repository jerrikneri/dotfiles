# Only download audio
alias yt-dl-a="yt-dlp -x -f bestaudio/best \"$1\""

yt-archive() {
  mv "$1" "$HOME/Movies/Youtube/Archive/"
}
