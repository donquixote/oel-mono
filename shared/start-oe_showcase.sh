#!/usr/bin/env sh

set -ex

# Stop containers in all packages.
docker compose --project-directory=packages/oe_bootstrap_theme stop
docker compose --project-directory=packages/oe_whitelabel stop
docker compose --project-directory=packages/oe_showcase stop

# Build assets in other packages.
cd ../oe_bootstrap_theme
docker compose up -d node
docker compose exec -u node node npm install
docker compose exec -u node node npm run build
docker compose stop

cd ../oe_whitelabel
docker compose up -d node
docker compose exec -u node node npm install
docker compose exec -u node node npm run build
docker compose stop

cd ../oe_showcase

docker compose up -d

# Remove vendor and build directories for packages that will be symlinked.
# This avoids confusion in the IDE and in Drupal directory scans.
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/node_modules
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/vendor
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/build/core
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/build/modules
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/build/themes
docker compose exec web rm -rf ../../packages/oe_whitelabel/node_modules
docker compose exec web rm -rf ../../packages/oe_whitelabel/vendor
docker compose exec web rm -rf ../../packages/oe_whitelabel/build/core
docker compose exec web rm -rf ../../packages/oe_whitelabel/build/modules
docker compose exec web rm -rf ../../packages/oe_whitelabel/build/themes

cp composer.lock composer.mono.lock
docker compose exec web composer update --no-install openeuropa/oe_whitelabel openeuropa/oe_bootstrap_theme

docker compose exec web composer install

# See if Drupal is already installed.
docker compose exec web ./vendor/bin/drush status | grep "DB name"

if [ $? -eq 1 ]; then
  # Drupal is not installed yet.
  docker compose exec web ./vendor/bin/run drupal:site-install
  docker-compose exec web ./vendor/bin/run ci:site-setup
  # Prepare for phpunit tests.
  docker-compose exec web ./vendor/bin/drush en -y oe_showcase_test
fi

docker-compose exec web ./vendor/bin/drush uli
