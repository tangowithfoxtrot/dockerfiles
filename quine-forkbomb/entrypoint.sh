#!/usr/bin/env bash

if [ "$1" == "--i-really-want-to-forkbomb" ]; then
  while true; do
    cargo run --quiet 2>/dev/null | tee >(cat >&3) &
  done 3>&1
else
  while true; do
    cargo run --quiet 2>/dev/null | tee >(cat >&3) &
    wait $!
  done 3>&1
fi
