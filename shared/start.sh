#!/usr/bin/env sh

set -e

PACKAGE="${PWD##*/}"
PACKAGES="oe_showcase oe_whitelabel oe_bootstrap_theme"
SUBDIR_NAMES="vendor build"

# Stop and clean up  other packages.
for OTHER_PACKAGE in $PACKAGES; do
  if [ "$PACKAGE" = "$OTHER_PACKAGE" ]; then
    continue
  fi
  # Move vendor and build to hidden subdirectories.
  mkdir -p ../../.ignore/$OTHER_PACKAGE
  for SUBDIR_NAME in $SUBDIR_NAMES; do
    SUBDIR="../$OTHER_PACKAGE/$SUBDIR_NAME"
    IGNORE_DIR="../../.ignore/$OTHER_PACKAGE/$SUBDIR_NAME"
    if [ ! -d "$SUBDIR" ]; then
      echo "Directory $SUBDIR/ not found."
    elif [ -d "$IGNORE_DIR" ]; then
      echo "Directory $IGNORE_DIR/ already exists."
    else
      echo "Moving $SUBDIR/ to $IGNORE_DIR/."
      mv "$SUBDIR" "$IGNORE_DIR"
    fi
  done
done

# Restore vendor and build from /.ignore/ directory, if they were moved previously.
for SUBDIR_NAME in $SUBDIR_NAMES; do
  IGNORE_DIR="../../.ignore/$PACKAGE/$SUBDIR_NAME"
  if [ -d "$SUBDIR_NAME" ]; then
    echo "Directory $SUBDIR_NAME/ already exists."
  elif [ ! -d "$IGNORE_DIR" ]; then
    echo "Directory $IGNORE_DIR/ not found."
    # Create the subdir so that it will be owned by the host system user.
    echo "Creating empty directory $SUBDIR_NAME/."
    mkdir -p "$SUBDIR_NAME"
  else
    echo "Moving $IGNORE_DIR/ to $SUBDIR_NAME/."
    mv "$IGNORE_DIR" "$SUBDIR_NAME"
  fi
done

# Stop other docker containers.
for OTHER_PACKAGE in $PACKAGES; do
  if [ "$PACKAGE" = "$OTHER_PACKAGE" ]; then
    continue
  fi
  cd "../$OTHER_PACKAGE"
  # Stop docker containers in the other package.
  docker compose stop
  cd "../$PACKAGE"
done

# Start containers in this package.
docker compose up -d

# Build assets in relevant packages.
for ASSETS_PACKAGE in $PACKAGES; do
  if [ ! -f "../$ASSETS_PACKAGE/package.json" ]; then
    continue
  fi
  if [ "$PACKAGE" = "oe_bootstrap_theme" ] && [ "$ASSETS_PACKAGE" = "oe_whitelabel" ]; then
    continue
  fi
  if [ -d "../$ASSETS_PACKAGE/assets/css" ]; then
    echo "The npm assets for $ASSETS_PACKAGE are already installed."
  else
    cd ../$ASSETS_PACKAGE
    docker compose up -d node
    docker compose exec -u node node npm install
    docker compose exec -u node node npm run build
    cd ../$PACKAGE
  fi
done

# Install Composer dependencies.
if [ -f vendor/composer/installed.json ]; then
  echo "Composer dependencies are already installed."
else
  if [ "$PACKAGE" = "oe_showcase" ]; then
    cp composer.lock composer.mono.lock
    docker compose exec web composer update --no-install openeuropa/oe_whitelabel openeuropa/oe_bootstrap_theme
  fi
  docker compose exec web composer install
fi

# Sometimes Drupal is not immediately ready.
DRUPAL_STATUS=1  # waiting.
for _ in $(seq 1 10); do
  if docker compose exec web ./vendor/bin/drush status | grep -qE "^Drupal bootstrap *: *Successful *$"; then
    DRUPAL_STATUS=0  # installed.
    break
  fi
  if ! docker compose exec web ./vendor/bin/drush status | grep -qE "^DB name *:"; then
    DRUPAL_STATUS=2  # not installed.
    break
  fi
  sleep 1
done

# See if Drupal is already installed.
if [ $DRUPAL_STATUS -eq 0 ]; then
  echo "Drupal is already installed."
  docker compose exec web ./vendor/bin/drush uli
else
  if [ $DRUPAL_STATUS -eq 1 ]; then
    echo "A Drupal installation was found, but it seems to be not working."
    docker compose exec web ./vendor/bin/drush status
    echo ""
    echo "Next steps to reinstall Drupal:"
  else
    echo "Drupal is not installed yet."
    echo "Next steps to install Drupal:"
  fi
  echo ""
  echo "docker compose exec web ./vendor/bin/run drupal:site-install"
  # Drupal is not installed yet.
  #docker compose exec web ./vendor/bin/run drupal:site-install
  if [ "$PACKAGE" = "oe_showcase" ]; then
    echo "docker compose exec web ./vendor/bin/run ci:site-setup"
    # Prepare for phpunit tests.
    echo "docker compose exec web ./vendor/bin/drush en -y oe_showcase_test"
  fi
  echo "docker compose exec web ./vendor/bin/drush uli"
fi
