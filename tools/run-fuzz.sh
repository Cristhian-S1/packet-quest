#!/bin/bash
# Ejecuta la misma suite con 1200 frames de fuzz por escena.
set -o pipefail
export PACKET_FUZZ_LONG=1
exec "$(dirname "$0")/run-tests.sh" "$@"
