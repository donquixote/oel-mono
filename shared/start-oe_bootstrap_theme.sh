#!/usr/bin/env sh

set -ex

docker compose up -d

docker compose exec -u node node npm install
docker compose exec -u node node npm run build

docker compose exec web composer install

if [ ! -f "build/sites/default/settings.php" ]; then
  docker compose exec web ./vendor/bin/run drupal:site-install
fi

docker-compose exec web ./vendor/bin/drush uli
