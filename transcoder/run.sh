#!/bin/sh
# Transcoder sidecar: husubiri stream ije kwenye `live`, kisha huitengeneza
# 360p (SD) + 480p na kuipeleka kwenye application ya `hls`.
#
# Env:
#   RTMP_HOST   - host ya nginx-rtmp (default: stream)
#   STREAM_KEYS - orodha ya stream keys, zinatenganishwa kwa nafasi (default: stream)
set -u

RTMP_HOST="${RTMP_HOST:-stream}"
STREAM_KEYS="${STREAM_KEYS:-stream}"

transcode() {
  key="$1"
  ffmpeg -nostdin -hide_banner -loglevel warning \
    -i "rtmp://$RTMP_HOST:1935/live/$key" \
    -c:v libx264 -preset veryfast -tune zerolatency -profile:v baseline \
    -vf scale=-2:360 -b:v 800k -maxrate 900k -bufsize 1600k -g 50 -r 25 -pix_fmt yuv420p \
    -c:a aac -b:a 96k -ar 44100 -ac 2 \
    -f flv "rtmp://$RTMP_HOST:1935/hls/${key}_360p" \
    -c:v libx264 -preset veryfast -tune zerolatency -profile:v main \
    -vf scale=-2:480 -b:v 1400k -maxrate 1600k -bufsize 2800k -g 50 -r 25 -pix_fmt yuv420p \
    -c:a aac -b:a 128k -ar 44100 -ac 2 \
    -f flv "rtmp://$RTMP_HOST:1935/hls/${key}_480p"
}

watch_key() {
  key="$1"
  while true; do
    if wget -qO- "http://$RTMP_HOST:8080/stat" 2>/dev/null | grep -q "<name>$key</name>"; then
      echo "[transcoder] $key ipo hewani — inaanza transcode 360p/480p"
      transcode "$key"
      echo "[transcoder] $key imesimama (ffmpeg exit $?) — inasubiri tena"
    fi
    sleep 3
  done
}

for k in $STREAM_KEYS; do
  watch_key "$k" &
done
wait
