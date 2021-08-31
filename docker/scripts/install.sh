#!/bin/bash

# Init ----------------------------------------------------------------------

# SRC="$(echo ${BASH_SOURCE[0]} | sed 's:\\:/:g')"
SRC="${BASH_SOURCE[0]//\\//}"
DIR="$(cd -P "${SRC%/*}" > /dev/null && pwd)"

ROOT_DIR="$(cd -P "${DIR}/../" > /dev/null && pwd)"
SCRIPT_DIR="$(cd -P "${DIR}/" > /dev/null && pwd)"

# Init ----------------------------------------------------------------------

BOBASH_HOME=/bobash/home

find "$BOBASH_HOME" -maxdepth 1 -mindepth 1 -type l -exec rm -rf {} \;
rm -rf "$BOBASH_HOME/.bobash"

"$SCRIPT_DIR/bobash-cfg.sh" -d "$ROOT_DIR/dist/bobash.tar.gz" -a install -y -h "$BOBASH_HOME"

cp -rf /bobash/.ssh "$BOBASH_HOME"

chown developer:developer -R "$BOBASH_HOME"

# while :; do sleep 2073600; done
