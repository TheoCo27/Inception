FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /var/run/nginx

RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Inception/CN=localhost" \
    -addext "subjectAltName=DNS:localhost"

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

CMD ["nginx", "-g", "daemon off;"]
