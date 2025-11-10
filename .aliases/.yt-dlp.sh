# Only download audio
alias yt-dl-a="yt-dlp -x -f bestaudio/best \"$1\""

yt-del() {
  mv "$1" "$HOME/Movies/Youtube/Archive/"
}

yt-fav() {
  mv "$1" "$HOME/Movies/Youtube/Favorite/"
}
