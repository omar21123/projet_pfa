FROM php:8.2-fpm

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installer Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Définir le dossier de travail
WORKDIR /var/www

# Copier uniquement composer.json et composer.lock en premier
# (meilleur cache Docker)
COPY composer.json composer.lock ./

# Installer les dépendances PHP AVANT de copier tout le projet
RUN composer install --no-interaction --optimize-autoloader --no-scripts

# Copier le reste du projet
COPY . .

# Supprimer le symlink public/storage s'il existe (cause de l'erreur)
RUN rm -rf public/storage

# Créer les dossiers nécessaires à Laravel
RUN mkdir -p \
    bootstrap/cache \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/testing \
    storage/framework/views \
    storage/logs \
    public/storage

# Donner les permissions
RUN chown -R www-data:www-data storage bootstrap/cache public/storage \
    && chmod -R 775 storage bootstrap/cache public/storage

EXPOSE 9000

CMD sh -c "\
    if [ ! -f .env ]; then \
        cp .env.example .env && php artisan key:generate; \
    fi && \
    php artisan storage:link --force && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache && \
    php artisan migrate --force && \
    php-fpm"