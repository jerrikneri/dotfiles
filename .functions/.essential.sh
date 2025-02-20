# Processes | PID
kp() {
  if [ -z "$1" ]
  then
    echo "Process name required."
  else
    kill -9 `ps aux | grep $1 | awk '{print $2}'`
  fi
}