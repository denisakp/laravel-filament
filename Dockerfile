FROM php:8.2-fpm as base

ARG DB_HOST=127.0.0.1
ARG DB_PORT=3306
ARG DB_DATABASE=php_laravel
ARG DB_USERNAME=root
ARG DB_PASSWORD=""

ARG AWS_ACCESS_KEY_ID=""
ARG AWS_SECRET_ACCESS_KEY=""
ARG AWS_DEFAULT_REGION=us-east-1
ARG AWS_BUCKET=""

ENV APP_ENV=production
ENV APP_DEBUG=false

ENV DB_HOST=${DB_HOST}
ENV DB_PORT=${DB_PORT}
ENV DB_DATABASE=${DB_DATABASE}
ENV DB_USERNAME=${DB_USERNAME}
ENV DB_PASSWORD=${DB_PASSWORD}

ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
ENV AWS_BUCKET=${AWS_BUCKET}

ENV FILESYSTEM_DRIVER=s3
ENV FILAMENT_FILESYSTEM_DISK=s3

# Install dependencies.
RUN apt-get update \
    && apt-get install -y unzip curl ca-certificates libcurl4-gnutls-dev gnupg libpq-dev nginx libonig-dev libicu-dev \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP extensions.
RUN docker-php-ext-install pdo_mysql bcmath curl opcache mbstring pcntl intl exif

FROM base as builder
# Set working directory to /var/www/html.
WORKDIR /var/www/html

# Copy composer executable.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy files from current folder to container current folder (set in workdir).
COPY --chown=www-data:www-data . .

# Build Laravel Application
RUN cp .env.example .env \
    && composer install --no-dev --no-progress \
    && php artisan key:generate \
    && php artisan optimize \
    && php artisan view:cache

FROM base as final
COPY --from=builder  /var/www/html /var/www/html

# Copy custom php.ini and opcache.ini files
COPY ./docker/php/php.ini /usr/local/etc/php/php.ini
COPY ./docker/nginx/site.conf /etc/nginx/nginx.conf

# Set working directory to /var/www/html.
WORKDIR /var/www/html

# Run the entrypoint file.
ENTRYPOINT [ "docker/entrypoint.sh" ]

EXPOSE 80 9000
