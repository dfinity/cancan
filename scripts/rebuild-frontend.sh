#!/bin/bash

set -e
echo "rebuilding frontend..."

# Support bootstrapping CanCan from any folder
BASEDIR=$(cd "$(dirname "$0")"; pwd)
cd "$BASEDIR"

address=$(dfx config defaults.start.address | tr -d '"')
port=$(dfx config defaults.start.port)

dfx build
dfx canister install cancan_ui --mode=reinstall

if [[ seed -eq 1 ]]; then
  echo "npm run seed"
  npm run seed
fi


URL="http://127.0.0.1:$port/?canisterId=$(dfx canister id cancan_ui)"

echo "Opening $URL"

case $(uname) in
  Linux) xdg-open $URL || true;;
  *) open $URL || true;;
esac
