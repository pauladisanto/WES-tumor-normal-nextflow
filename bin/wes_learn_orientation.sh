#!/usr/bin/env bash
set -euo pipefail
tumor=$1; normal=$2; f1r2=$3
gatk --java-options '-Xmx3g' LearnReadOrientationModel \
  -I "$f1r2" -O "${tumor}_vs_${normal}.orientation-priors.tar.gz"
