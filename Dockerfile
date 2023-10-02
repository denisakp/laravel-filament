# Used for prod build.
FROM php:8.2-fpm as php

ENV APP_ENV=production

# Install dependencies.
RUN apt-get update \
    && apt-get install -y unzip curl ca-certificates libcurl4-gnutls-dev gnupg libpq-dev nginx libonig-dev libicu-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && apt-get autoremove -y

# Install PHP extensions.
RUN docker-php-ext-install pdo_mysql bcmath curl opcache mbstring pcntl intl exif

# Copy composer executable.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy custom php.ini and opcache.ini files
COPY ./docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY ./docker/php/php.ini /usr/local/etc/php/php.ini
COPY ./docker/nginx/site.conf /etc/nginx/nginx.conf

# Set working directory to /var/www/html.
WORKDIR /var/www/html

# Copy files from current folder to container current folder (set in workdir).
COPY --chown=www-data:www-data . .

RUN cp .env.example .env \
    && composer install --no-dev --no-progress \
    && php artisan key:generate \
    && touch database/database.sqlite \
    && npm install \
    && npm run build \
    && npm cache clean --force \
    && php artisan optimize \
    && php artisan view:cache

# Run the entrypoint file.
ENTRYPOINT [ "docker/entrypoint.sh" ]

EXPOSE 80 9000
