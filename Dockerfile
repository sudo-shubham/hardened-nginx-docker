FROM alpine:3.11.3

LABEL maintainer="Shubham Patel <shubhampatelsp812@gmail.com>"

ENV NGINX_VERSION 1.17.9

RUN apk update \
    && apk add --no-cache wget build-base libcap openssl-dev git pcre-dev zlib-dev krb5-dev \
    && cd /tmp \
    && git clone https://github.com/openresty/headers-more-nginx-module \
    && git clone https://github.com/stnoonan/spnego-http-auth-nginx-module.git \
    && cd /etc \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION}.tar.gz \
    && rm nginx-${NGINX_VERSION}.tar.gz \
    && set -x \
    # create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && cd /etc/nginx-${NGINX_VERSION} \
    && ./configure \
        --sbin-path=/usr/sbin/nginx \ 
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --prefix=/etc/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --add-module=/tmp/headers-more-nginx-module \
        --add-module=/tmp/spnego-http-auth-nginx-module \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
    && make \
    && make install \
    && cd .. \
    && rm -rf /tmp/* \
    && rm -r nginx-${NGINX_VERSION} \
    && apk del build-base openssl-dev git zlib-dev wget \
    && rm -rf /var/cache/apk/* \
    && mkdir /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && mkdir /var/cache/nginx \
    && chown nginx:nginx /var/run/nginx.pid \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx \
    && setcap cap_net_bind_service=+ep /usr/sbin/nginx

USER nginx
COPY configs/nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
