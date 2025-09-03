# ----------------------------
# Stage 1: Build Frontend (Vite)
# ----------------------------
FROM node:20-alpine AS frontend
WORKDIR /app

COPY package*.json vite.config.* ./
RUN npm ci

COPY resources ./resources
COPY public ./public

RUN npm run build

# ----------------------------
# Stage 2: Laravel + Apache
# ----------------------------
FROM php:8.3-apache

# Install ekstensi PHP
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libjpeg-dev libfreetype-dev libonig-dev \
    && docker-php-ext-install pdo pdo_mysql bcmath mbstring exif gd \
    && a2enmod rewrite

WORKDIR /var/www/html

# Copy Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy source code Laravel
COPY . .

# Copy hasil build frontend
COPY --from=frontend /app/public/build ./public/build

# Install dependencies (production only)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --ignore-platform-reqs

# Cache config & route
RUN php artisan config:clear && php artisan config:cache \
    && php artisan route:clear && php artisan route:cache

# Apache listen port 8080 (Railway default)
EXPOSE 8080

CMD ["apache2-foreground"]
