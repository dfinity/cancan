#!/bin/sh

BINDIR=$HOME/bin/
mkdir -p $BINDIR
BIN=$BINDIR/vessel
VESSEL_VERSION=v0.6.0

if [[ "$OSTYPE" == "darwin"* ]]; then
  wget --output-document $BIN https://github.com/dfinity/vessel/releases/download/$VESSEL_VERSION/vessel-macos
else
  wget --output-document $BIN https://github.com/dfinity/vessel/releases/download/$VESSEL_VERSION/vessel-linux64 && chmod +x $BIN
fi

chmod +x $BIN
