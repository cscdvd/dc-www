#!/usr/bin/env sh
set -eu

# Get full path of log directory
LOGDIR="${1:-.}"

# Check given path
if [ ! -d "$LOGDIR" ]; then
  echo "INFO: usage $0 <full-path-to-log-directory>."
  exit 1
fi

echo "INFO: compressing log files in $LOGDIR started."
echo "INFO: init nullglob, *.log will return null if no files are found."
shopt -s nullglob

echo "INFO: looping through log files in $LOGDIR."
for log in "$LOGDIR"/*.log; do
  echo "INFO: processing $log."
  [ -e "$log" ] || continue

  echo "INFO: compressing $log."
  if gzip -c "$log" > "$log.gz"; then
    echo "INFO: cleaning up $log."
    : > "$log"
    echo "INFO: file $log compressed successfully."
  else
    echo "ERROR: failed to compress $log" >&2
  fi
done
