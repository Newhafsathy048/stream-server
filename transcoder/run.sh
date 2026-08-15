#!/bin/sh
# Transcoder: husubiri stream ije kwenye `live`, kisha huitengeneza
# 360p (SD) + 480p na kuipeleka kwenye application ya `hls`.
#
# Env:
#   RTMP_HOST   - host ya nginx-rtmp (default: stream)
#   STREAM_KEYS - orodha ya stream keys, zinatenganishwa kwa nafasi (default: stream)
set -u

RTMP_HOST="${RTMP_HOST:-stream}"
STREAM_KEYS="${STREAM_KEYS:-stream}"
STAT_URL="http://$RTMP_HOST:8080/stat"
START_TIMEOUT="${START_TIMEOUT:-12}"   # sekunde za kusubiri output ianze kabla ya kujaribu tena

stat_has() {
  wget -qO- "$STAT_URL" 2>/dev/null | grep -q "<name>$1</name>"
}

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

# Huua ffmpeg ikishindwa kuanza kutoa output ndani ya START_TIMEOUT — RTMP input
# inaweza kukwama ikiunganishwa kabla publisher hajatuma headers.
watchdog() {
  key="$1"; pid="$2"; waited=0
  while [ "$waited" -lt "$START_TIMEOUT" ]; do
    kill -0 "$pid" 2>/dev/null || return 0
    if stat_has "${key}_360p"; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "[transcoder] $key: output haijaanza ndani ya ${START_TIMEOUT}s — inaanzisha upya"
    kill "$pid" 2>/dev/null
  fi
}

watch_key() {
  key="$1"
  while true; do
    if stat_has "$key"; then
      # Mpe publisher nafasi ya kutuma metadata/keyframe kabla ya kuunganisha.
      sleep 2
      echo "[transcoder] $key ipo hewani — inaanza transcode 360p/480p"
      transcode "$key" &
      ff=$!
      watchdog "$key" "$ff"
      wait "$ff"
      echo "[transcoder] $key imesimama (ffmpeg exit $?) — inasubiri tena"
    fi
    sleep 3
  done
}

for k in $STREAM_KEYS; do
  watch_key "$k" &
done
wait
