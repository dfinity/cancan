#!/bin/sh

BINDIR=$HOME/bin/
mkdir -p $BINDIR
BIN=$BINDIR/vessel
VESSEL_VERSION=v0.6.0
wget --output-document $BIN https://github.com/dfinity/vessel/releases/download/$VESSEL_VERSION/vessel-linux64 && chmod +x $BIN && $BIN help
