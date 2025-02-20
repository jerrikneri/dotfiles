# Git
gclb() {
  git fetch -p &&
  for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}'); do
    git branch -D "$branch"
  done
}

# Processes | PID
kp() {
  if [ -z "$1" ]
  then
    echo "Process name required."
  else
    kill -9 `ps aux | grep $1 | awk '{print $2}'`
  fi
}