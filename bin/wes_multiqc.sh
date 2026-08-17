#!/usr/bin/env bash
set -euo pipefail
threads=$1
multiqc . --force --filename multiqc_report.html
