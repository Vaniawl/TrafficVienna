#!/usr/bin/env bash
set -euo pipefail

bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
bash -n scripts/agent-framework/provider-*.sh
python3 -m compileall -q scripts/agent-framework
python3 -m unittest -v tests.agent-framework.test_generated_artifacts tests.agent-framework.test_project_opencode tests.agent-framework.test_provider_shims
bash tests/opencode-reliability.sh
bash scripts/build.sh
bash scripts/test.sh
git diff --check HEAD
echo "[ci] OK"
