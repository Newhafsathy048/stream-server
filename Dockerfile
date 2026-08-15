# Image moja yenye nginx-rtmp + transcoder (kwa Fly.io / PaaS yoyote inayotumia Docker).
FROM alfg/nginx-rtmp:latest

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY web/ /www/static/
COPY transcoder/run.sh /opt/transcoder.sh
COPY docker-entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/transcoder.sh /opt/entrypoint.sh && mkdir -p /tmp/hls

EXPOSE 1935 8080

ENTRYPOINT ["/bin/sh", "/opt/entrypoint.sh"]
