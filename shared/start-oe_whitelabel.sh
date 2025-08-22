#!/usr/bin/env sh

set -ex

# Build assets in other packages.
if [ ! -d ../oe_bootstrap_theme/assets/css ]; then
  cd ../oe_bootstrap_theme
  docker compose up -d node
  docker compose exec -u node node npm install
  docker compose exec -u node node npm run build
  cd ../oe_whitelabel
fi

# Stop containers in other packages.
# This will also stop the node container started earlier.
docker compose --project-directory=../oe_bootstrap_theme stop
docker compose --project-directory=../oe_showcase stop

# Start containers in this package.
docker compose up -d

# Build assets in this package.
if [ ! -d assets/css ]; then
  docker compose exec -u node node npm install
  docker compose exec -u node node npm run build
fi

# Remove vendor and build directories for packages that will be symlinked.
# This avoids confusion in the IDE and in Drupal directory scans.
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/node_modules
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/vendor
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/build/core
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/build/modules
docker compose exec web rm -rf ../../packages/oe_bootstrap_theme/build/themes

# Also remove vendor and build directories in oe_showcase.
# This is not symlinked, but still causes confusion in the IDE.
docker compose exec web rm -rf ../../packages/oe_showcase/node_modules
docker compose exec web rm -rf ../../packages/oe_showcase/vendor
docker compose exec web rm -rf ../../packages/oe_showcase/build/core
docker compose exec web rm -rf ../../packages/oe_showcase/build/modules
docker compose exec web rm -rf ../../packages/oe_showcase/build/themes

if [ ! -f vendor/composer/installed.json ]; then
  if [ ! -f copmoser.mono.lock ]; then
    # Avoid Drupal 11.2.
    docker compose exec web composer update --no-install
    docker compose exec web composer update --no-install \
      drupal/core:11.1.* \
      drupal/core-composer-scaffold:11.1.* \
      drupal/core-dev:11.1.*
  fi
  docker compose exec web composer install
fi

# See if Drupal is already installed.
if docker compose exec web ./vendor/bin/drush status | egrep "^Database *: *Connected *$"; then
  echo "Drupal is already installed."
else
  # Drupal is not installed yet.
  docker compose exec web ./vendor/bin/run drupal:site-install
fi

docker-compose exec web ./vendor/bin/drush uli
