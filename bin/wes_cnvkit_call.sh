#!/usr/bin/env bash

set -euo pipefail

tumor="$1"
segments="$2"

# Convert continuous log2 segments into discrete copy-number calls. Without a
# supplied purity/ploidy model these are approximate, research-use calls.
cnvkit.py call "$segments" \
    --method threshold \
    --output "${tumor}.cnv.call.cns"
