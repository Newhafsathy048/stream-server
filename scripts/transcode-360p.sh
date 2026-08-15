#!/usr/bin/env bash
# Punguza ubora wa chanzo chochote (unachomiliki/uliyoruhusiwa) hadi 360p (SD)
# na toa HLS moja kwa moja kwenye folda — bila kuhitaji RTMP.
#
#   ./transcode-360p.sh <input> [outdir]
#
# Kisha huduma faili za outdir kwa nginx/HTTP yoyote na ucheze <outdir>/stream.m3u8
set -euo pipefail

IN="${1:?Toa input (file au URL)}"
OUT="${2:-./hls-out}"
mkdir -p "$OUT"

exec ffmpeg -re -i "$IN" \
  -c:v libx264 -preset veryfast -profile:v baseline -level 3.0 \
  -vf "scale=-2:360" -b:v 800k -maxrate 900k -bufsize 1600k -g 50 -r 25 -pix_fmt yuv420p \
  -c:a aac -b:a 96k -ar 44100 -ac 2 \
  -f hls -hls_time 2 -hls_list_size 6 -hls_flags delete_segments+independent_segments \
  -hls_segment_filename "$OUT/seg_%05d.ts" \
  "$OUT/stream.m3u8"
