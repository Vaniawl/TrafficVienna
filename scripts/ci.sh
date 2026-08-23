#!/usr/bin/env bash
set -euo pipefail

bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
bash tests/opencode-reliability.sh
bash tests/repository-validation-regressions.sh
bash scripts/build.sh
bash scripts/test.sh
git diff --check HEAD
echo "[ci] OK"
