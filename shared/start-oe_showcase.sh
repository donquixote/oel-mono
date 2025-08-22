#!/usr/bin/env sh

set -ex

# Build assets in other packages.
if [ ! -d ../oe_bootstrap_theme/assets/css ]; then
  cd ../oe_bootstrap_theme
  docker compose up -d node
  docker compose exec -u node node npm install
  docker compose exec -u node node npm run build
  docker compose exec -u node rm -rf node_modules
  cd ../oe_showcase
fi

if [ ! -d ../oe_whitelabel/assets/css ]; then
  cd ../oe_whitelabel
  docker compose up -d node
  docker compose exec -u node node npm install
  docker compose exec -u node node npm run build
  docker compose exec -u node rm -rf node_modules
  cd ../oe_showcase
fi

# Stop containers in other packages.
# This will also stop the node containers started earlier.
docker compose --project-directory=../oe_bootstrap_theme stop
docker compose --project-directory=../oe_whitelabel stop

# Start containers in this package.
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

if [ ! -f vendor/composer/installed.json ]; then
  cp composer.lock composer.mono.lock
  docker compose exec web composer update --no-install openeuropa/oe_whitelabel openeuropa/oe_bootstrap_theme
  docker compose exec web composer install
fi

# See if Drupal is already installed.
if docker compose exec web ./vendor/bin/drush status | egrep "^Database *: *Connected *$"; then
  echo "Drupal is already installed."
else
  # Drupal is not installed yet.
  docker compose exec web ./vendor/bin/run drupal:site-install
  docker-compose exec web ./vendor/bin/run ci:site-setup
  # Prepare for phpunit tests.
  docker-compose exec web ./vendor/bin/drush en -y oe_showcase_test
fi

docker-compose exec web ./vendor/bin/drush uli
