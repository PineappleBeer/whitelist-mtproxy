FROM alpine:3.14

# Install packages and remove default server definition
RUN apk --no-cache add \
  bash \
  curl \
  php8 \
  php8-ctype \
  php8-curl \
  php8-dom \
  php8-fpm \
  php8-gd \
  php8-intl \
  php8-json \
  php8-mbstring \
  php8-mysqli \
  php8-opcache \
  php8-openssl \
  php8-phar \
  php8-session \
  php8-xml \
  php8-xmlreader \
  php8-zlib \
  supervisor \
  nginx=1.20.2-r1 \
  nginx-mod-stream=1.20.2-r1 \
  git && \
  apk add --no-cache --virtual .pynacl_deps \ 
  py3-pip \
  build-base \ 
  python3-dev \
  python3 \
  libffi-dev && \
  pip install --upgrade pip 

USER root

# Set Mtproxy
RUN cd /usr/local && \
  git clone https://ghproxy.com/https://github.com/alexbers/mtprotoproxy && \
  cd mtprotoproxy && \
  pip install cryptography && \
  sed -i 's/443/7443/' config.py && \
  sed -i 's/"tg":\s*".*"/"tg": "si3catbra4ps85p6jpi8nnjg98u6ihr6"/' config.py && \
  sed -i 's/#\s*TLS_DOMAIN\s*=\s*"www\.google\.com"/TLS_DOMAIN = "www.cloudflare.com"/' config.py 


# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php8 /usr/bin/php

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Get ip_white
COPY config/ip_white.conf /etc/nginx/ip_white.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY config/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx && \
  chown -R nobody.nobody /etc/nginx && \
  chown -R nobody.nobody /usr/local 

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm & mtproxy
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
