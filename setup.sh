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
