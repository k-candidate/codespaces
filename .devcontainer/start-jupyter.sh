#!/usr/bin/env bash
set -euo pipefail

exec 9>/tmp/jupyter-start.lock
flock 9

server_is_running() {
  uv run jupyter server list 2>/dev/null | grep -q 'http://[^[:space:]]*:8888/'
}

if server_is_running; then
  exit 0
fi

nohup uv run jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
  9>&- > /tmp/jupyter.log 2>&1 < /dev/null &
server_pid=$!

for _ in {1..60}; do
  if server_is_running; then
    exit 0
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

cat /tmp/jupyter.log >&2
echo "JupyterLab did not start on port 8888." >&2
exit 1
