#!/bin/sh

set -e

BINDIR=$HOME/bin
BIN=$BINDIR/moc

mkdir -p $BINDIR
MOTOKO_VERSION=0.5.8
wget --output-document moctools.tgz https://download.dfinity.systems/motoko/$MOTOKO_VERSION/x86_64-linux/motoko-$MOTOKO_VERSION.tar.gz
tar -zxf moctools.tgz
cp moc $BIN
chmod +x $BIN
