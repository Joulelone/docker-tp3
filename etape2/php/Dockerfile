FROM php:8.2-fpm

# Installer l'extension mysqli (doc officielle: "docker-php-ext-install")
RUN docker-php-ext-install mysqli \
 && docker-php-ext-enable mysqli

WORKDIR /app
