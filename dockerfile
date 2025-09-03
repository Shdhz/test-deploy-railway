# ----------------------------
# Stage 1: Build Frontend Assets
# ----------------------------
FROM node:20-alpine AS frontend
WORKDIR /app

# Copy package.json dan lockfile (biar caching efisien)
COPY package*.json vite.config.* ./

RUN npm ci

# Copy resource yang dibutuhkan
COPY resources ./resources
COPY public ./public

# Build Vite (React + Inertia)
RUN npm run build

# ----------------------------
# Stage 2: Laravel + PHP-FPM
# ----------------------------
FROM php:8.3-fpm-alpine

# Install ekstensi PHP yang umum dipakai Laravel
RUN apk add --no-cache bash curl git unzip libpng-dev libjpeg-turbo-dev libfreetype-dev oniguruma-dev \
    && docker-php-ext-install pdo pdo_mysql bcmath mbstring exif gd

WORKDIR /var/www/html

# Copy Composer dari image resmi
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy seluruh source code Laravel
COPY . .

# Copy hasil build dari stage frontend
COPY --from=frontend /app/public/build ./public/build

# Install dependency PHP (tanpa dev, optimize autoload)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Cache config dan route
RUN php artisan config:clear && php artisan config:cache \
    && php artisan route:clear && php artisan route:cache

EXPOSE 9000
CMD ["php-fpm"]

