#!/usr/bin/env sh

# Add git remotes, if they do not already exist.
git remote add oe_bootstrap_theme git@github.com:openeuropa/oe_bootstrap_theme.git || true
git remote add oe_whitelabel git@github.com:openeuropa/oe_whitelabel.git || true
git remote add oe_showcase git@github.com:openeuropa/oe_showcase.git || true

# Configure prefixes for tags from different remotes.
git config --add remote.oe_bootstrap_theme.fetch '+refs/tags/*:refs/tags/oe_bootstrap_theme/*'
git config --add remote.oe_whitelabel.fetch '+refs/tags/*:refs/tags/oe_whitelabel/*'
git config --add remote.oe_showcase.fetch '+refs/tags/*:refs/tags/oe_showcase/*'

# Create symlinks in package directories.
ln -sf ../../shared/start-oe_showcase.sh packages/oe_showcase/start.sh
ln -sf ../../shared/start-oe_whitelabel.sh packages/oe_whitelabel/start.sh
ln -sf ../../shared/start-oe_bootstrap_theme.sh packages/oe_bootstrap_theme/start.sh

ln -sf ../../shared/docker-compose.package.yml packages/oe_whitelabel/docker-compose.override.yml
ln -sf ../../shared/docker-compose.package.yml packages/oe_showcase/docker-compose.override.yml

# Create .env files with distinguishable names.
if [ -z "$1" ]; then
  NAME=${PWD##*/}
else
  NAME=$1
fi

if [ ! -f packages/oe_showcase/.env ]; then
  echo "COMPOSE_PROJECT_NAME=oe_showcase-$NAME" > packages/oe_showcase/.env
fi

if [ ! -f packages/oe_whitelabel/.env ]; then
  echo "COMPOSE_PROJECT_NAME=oe_whitelabel-$NAME" > packages/oe_whitelabel/.env
fi

if [ ! -f packages/oe_bootstrap_theme/.env ]; then
  echo "COMPOSE_PROJECT_NAME=oe_bootstrap_theme-$NAME" > packages/oe_bootstrap_theme/.env
fi

