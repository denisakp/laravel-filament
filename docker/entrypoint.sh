#!/bin/bash

echo "Starting php-fpm ............"
php-fpm -D

echo "Starting nginx ............"
nginx -g "daemon off;"
