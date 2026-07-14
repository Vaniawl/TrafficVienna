#!/usr/bin/env bash
set -euo pipefail

bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
bash scripts/build.sh
bash scripts/test.sh
git diff --check HEAD
echo "[ci] OK"
