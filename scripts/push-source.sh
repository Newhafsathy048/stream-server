#!/usr/bin/env bash
# Tuma chanzo (file au stream unayoruhusiwa kuitumia) kwenye server yako.
#
#   ./push-source.sh /path/video.mp4 [stream_key] [rtmp_host]
#
# Baada ya hapo tazama: http://<host>:8080/?src=/hls/<stream_key>.m3u8
set -euo pipefail

SRC="${1:?Toa chanzo: file au URL}"
KEY="${2:-stream}"
HOST="${3:-rtmp://127.0.0.1:1935}"

exec ffmpeg -re -stream_loop -1 -i "$SRC" \
  -c:v libx264 -preset veryfast -tune zerolatency -profile:v baseline \
  -b:v 1500k -maxrate 1600k -bufsize 3000k -g 50 -r 25 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -ar 44100 -ac 2 \
  -f flv "$HOST/live/$KEY"
