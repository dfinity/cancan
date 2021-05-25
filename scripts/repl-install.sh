#!/bin/sh

BINDIR=$HOME/bin
mkdir -p $BINDIR
IC_BIN=$BINDIR/ic-repl
VERSION=2021-05-19

if [[ "$OSTYPE" == "darwin"* ]]; then
        wget --output-document $IC_BIN https://github.com/chenyan2002/ic-repl/releases/download/$VERSION/ic-repl-macos
else
        wget --output-document $IC_BIN https://github.com/chenyan2002/ic-repl/releases/download/$VERSION/ic-repl-linux64
fi

chmod +x $IC_BIN && $IC_BIN --help
