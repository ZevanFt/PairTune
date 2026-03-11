#!/usr/bin/env bash
set -euo pipefail

npm -C backend run dev &
BACK_PID=$!

npm -C admin run dev &
ADMIN_PID=$!

trap "kill $BACK_PID $ADMIN_PID" INT TERM
wait
