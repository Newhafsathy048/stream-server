FROM alfg/nginx-rtmp:latest

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY web/ /www/static/

EXPOSE 1935 8080

ENTRYPOINT ["nginx", "-g", "daemon off;"]
