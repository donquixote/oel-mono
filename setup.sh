#!/usr/bin/env sh

set -e

if [ -z "$1" ]; then
  NAME="${PWD##*/}"
else
  NAME="$1"
fi

PACKAGES="oe_showcase oe_whitelabel oe_bootstrap_theme"

for PACKAGE in $PACKAGES; do

  # Add git remote, if it does not already exist.
  if ! git remote get-url "$PACKAGE" > /dev/null 2>&1; then
    # Create the remote.
    git remote add "$PACKAGE" "git@github.com:openeuropa/$PACKAGE.git"
    # Configure a prefix for tags from the remote.
    git config --add "remote.$PACKAGE.fetch" "'+refs/tags/*:refs/tags/$PACKAGE/*'"
  fi

  # Create symlinks.
  ln -sf "../../shared/start.sh" "packages/$PACKAGE/start.sh"
  ln -sf "../../shared/docker-compose.package.yml" "packages/$PACKAGE/docker-compose.override.yml"

  # Create .env file.
  if [ ! -f "packages/$PACKAGE/.env" ]; then
    touch "packages/$PACKAGE/.env"
  fi

  if ! egrep -q "^COMPOSE_PROJECT_NAME=" "packages/$PACKAGE/.env"; then
    echo "COMPOSE_PROJECT_NAME=$PACKAGE-$NAME" > packages/$PACKAGE/.env
  fi

  if ! grep -q "PACKAGE=$PACKAGE" "packages/$PACKAGE/.env"; then
    echo "PACKAGE=$PACKAGE" >> "packages/$PACKAGE/.env"
  fi
done
