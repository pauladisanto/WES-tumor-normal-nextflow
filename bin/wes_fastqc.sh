#!/usr/bin/env bash
set -euo pipefail
fastqc --threads "$1" "${@:2}"
