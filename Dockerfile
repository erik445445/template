FROM php:8.2-fpm

# Installa dipendenze di sistema e Nginx
RUN apt-get update && apt-get install -y \
    unzip git curl libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev nginx \
    default-mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql zip intl

# Installa Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copia i file del progetto
WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader

# Configura permessi
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 755 /var/www/html
RUN chmod -R 775 /var/www/html/config /var/www/html/var /var/www/html/public

# Configura PHP-FPM per ascoltare su 0.0.0.0:9000
RUN echo "[www]\nlisten = 0.0.0.0:9000" > /usr/local/etc/php-fpm.d/zz-docker.conf

# Configura PHP (memory_limit, OPcache e debug)
RUN echo "[PHP]\nmemory_limit=512M\nerror_reporting=E_ALL\ndisplay_errors=On\ndisplay_startup_errors=On\nlog_errors=On\n[opcache]\nopcache.enable=1\nopcache.memory_consumption=256\nopcache.interned_strings_buffer=8\nopcache.max_accelerated_files=10000" > /usr/local/etc/php/conf.d/custom.ini

# Configura Nginx
COPY nginx.conf /etc/nginx/sites-available/default
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Copia script di avvio
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Etichette Traefik
LABEL traefik.enable=true
LABEL traefik.http.routers.shopware.rule="Host(`i8g88840sk0c8kksw04w0sw8.157.180.26.10.sslip.io`,`157.180.26.10`)"
LABEL traefik.http.services.shopware.loadbalancer.server.port=80
LABEL traefik.http.routers.shopware.entrypoints=web
LABEL traefik.http.routers.shopware.middlewares=strip-prefix
LABEL traefik.http.middlewares.strip-prefix.stripprefix.prefixes=/

# Espone le porte
EXPOSE 80 9000

# Avvia lo script
CMD ["/start.sh"]
