#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
port=${1:-8080}

case "$port" in
  *[!0-9]*|'')
    echo "Usage: $0 [port]" >&2
    exit 2
    ;;
esac

echo "Starting Home Assistant Legacy download server on port $port"
echo "It runs only in this terminal and stops when you press Ctrl+C."
if [ "$#" -eq 0 ]; then
  exec python3 -u "$script_directory/download-server/server.py" \
    --bind 0.0.0.0 --port "$port" --auto-port
fi
exec python3 -u "$script_directory/download-server/server.py" --bind 0.0.0.0 --port "$port"
