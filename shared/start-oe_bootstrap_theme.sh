#!/usr/bin/env sh

set -ex

docker compose up -d

docker compose exec -u node node npm install
docker compose exec -u node node npm run build

docker compose exec web composer install

# See if Drupal is already installed.
docker compose exec web ./vendor/bin/drush status | grep "DB name"

if [ $? -eq 1 ]; then
  # Drupal is not installed yet.
  docker compose exec web ./vendor/bin/run drupal:site-install
fi

docker-compose exec web ./vendor/bin/drush uli
