#!/usr/bin/env sh

cat ~/.local/state/uva/sequences.txt 2>/dev/null

exec "$@"
