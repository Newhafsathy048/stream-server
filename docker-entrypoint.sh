#!/bin/sh
# Huendesha nginx-rtmp na transcoder ndani ya container moja.
set -eu

export RTMP_HOST="${RTMP_HOST:-127.0.0.1}"
export STREAM_KEYS="${STREAM_KEYS:-stream}"

mkdir -p /tmp/hls

nginx -g 'daemon off;' &
NGINX_PID=$!

# Subiri nginx iwe tayari kabla ya transcoder kuanza kuuliza /stat.
i=0
while [ $i -lt 30 ]; do
  wget -qO- "http://127.0.0.1:8080/health" >/dev/null 2>&1 && break
  i=$((i + 1))
  sleep 1
done

/bin/sh /opt/transcoder.sh &
TRANSCODER_PID=$!

term() {
  kill "$NGINX_PID" "$TRANSCODER_PID" 2>/dev/null || true
}
trap term TERM INT

# Container hufa nginx ikifa.
wait "$NGINX_PID"
