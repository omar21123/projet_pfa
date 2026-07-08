FROM php:8.2-fpm
# 1. Install system tools
RUN apt-get update && apt-get install -y \
    git unzip zip curl libzip-dev libpng-dev \
    libjpeg62-turbo-dev libfreetype6-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql zip

# 2. Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# 3. Copy your project files
COPY . .

# 4. Install PHP packages
RUN composer install --no-interaction --optimize-autoloader

EXPOSE 9000

# 5. All automatic setup steps are inside this CMD
CMD sh -c "\
    mkdir -p storage/framework/cache \
             storage/framework/sessions \
             storage/framework/testing \
             storage/framework/views \
             storage/logs \
             bootstrap/cache && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache && \
    if [ ! -f .env ]; then cp .env.example .env && php artisan key:generate; fi && \
    touch database/database.sqlite && \
    chown -R www-data:www-data database database/database.sqlite && \
    chmod -R 775 database && \
    php artisan migrate --force && \
    php-fpm"
