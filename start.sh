#!/bin/bash
# Avvia PHP-FPM in background
php-fpm -D
# Avvia Nginx in foreground
nginx -g 'daemon off;'
