#!/bin/bash

set -e
echo "Running bootstrap script..."

# Support bootstrapping CanCan from any folder
BASEDIR=$(
  cd "$(dirname "$0")"
  pwd
)
cd "$BASEDIR"

host="localhost"
address="http://$host"
port=$(dfx config defaults.start.port)

echo "dfx build"
npm run deploy

# echo "Running seed script..."
# echo "\nThis command may prompt you to install node to run.\nPlease accept and continue."
# npm run seed -- 2

URL="http://$(dfx canister id cancan_ui).$host:$port/"

echo "Open at $URL"

case $(uname) in
Linux) xdg-open $URL || true ;;
*) open $URL || true ;;
esac
