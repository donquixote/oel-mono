#!/usr/bin/env sh

set -ex

cd "$(dirname "$0")"

cd packages/oe_bootstrap_theme
docker compose up -d node
docker compose exec -u node node npm install
docker compose exec -u node node npm run build
cd ../..

cd packages/oe_whitelabel
docker compose up -d node
docker compose exec -u node node npm install
docker compose exec -u node node npm run build
cd ../..
