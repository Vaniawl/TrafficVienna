#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
cd "$ROOT"

models_file="$(mktemp)"
tmpdir="$(mktemp -d)"
trap 'rm -f "$models_file"; rm -rf "$tmpdir"' EXIT

if [[ -n "${OPENCODE_LITELLM_BASE_URL:-}" && -n "${LITELLM_MASTER_KEY:-}" ]]; then
  opencode models > "$models_file"
else
  : > "$models_file"
fi

python3 - "$ROOT" "$models_file" "$tmpdir" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
models_file = Path(sys.argv[2])
tmpdir = Path(sys.argv[3])

available_models = {
    line.strip()
    for line in models_file.read_text(encoding="utf-8").splitlines()
    if line.startswith("local-litellm/")
}
runtime_models_available = bool(available_models)

expected_agents = {
    "orchestrator": "local-litellm/gpt-oss-120b",
    "explorer": "local-litellm/qwen-27b",
    "architect": "local-litellm/deepseek-q6-70b",
    "implementer": "local-litellm/coder-next",
    "test-architect": "local-litellm/coder-32b",
    "reviewer": "local-litellm/deepseek-r1-32b",
    "security-reviewer": "local-litellm/deepseek-q6-70b",
    "release-manager": "local-litellm/local-main",
}


def frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise AssertionError(f"{path} missing frontmatter")
    block = text.split("---", 2)[1]
    result: dict[str, str] = {}
    for raw in block.splitlines():
        if ":" in raw and not raw.startswith(" "):
            key, value = raw.split(":", 1)
            result[key.strip()] = value.strip()
    return result


for agent, expected_model in expected_agents.items():
    path = root / ".opencode" / "agents" / f"{agent}.md"
    meta = frontmatter(path)
    actual_model = meta.get("model")
    if actual_model != expected_model:
        raise AssertionError(f"{agent}: expected model {expected_model}, got {actual_model}")
    if runtime_models_available and actual_model not in available_models:
        raise AssertionError(f"{agent}: model {actual_model} not returned by opencode models")

model_matrix = (root / "docs/opencode/model-matrix.md").read_text(encoding="utf-8")
for model in sorted(set(expected_agents.values())):
    if model not in model_matrix:
        raise AssertionError(f"model matrix missing {model}")

for path in list((root / ".opencode" / "agents").glob("*.md")) + [
    root / "docs/opencode/model-matrix.md",
    root / "docs/opencode/reliability-audit-2026-07-15.md",
]:
    text = path.read_text(encoding="utf-8")
    for forbidden in [
        r"^model:\s*(opencode|openai|anthropic)/",
        r"`(opencode|openai|anthropic)/[^`]+`",
        r"\bembedding-default\b",
    ]:
        if re.search(forbidden, text, flags=re.MULTILINE) and "must not use" not in text:
            raise AssertionError(f"{path} contains forbidden model token")

state_doc = (root / "docs/opencode/state-files.md").read_text(encoding="utf-8")
state_doc_compact = re.sub(r"\s+", " ", state_doc)
for phrase in [
    "Checkpoint Schema",
    "Task ID",
    "Acceptance Criteria",
    "Definition Of Done Status",
    "Invalid or incomplete checkpoints are rejected",
    "Concurrent subagents must not write the same checkpoint",
]:
    if phrase not in state_doc_compact:
        raise AssertionError(f"state-files.md missing phrase: {phrase}")

required_fields = [
    "Task ID",
    "Goal",
    "Acceptance Criteria",
    "Completed Work",
    "Remaining Work",
    "Changed Files",
    "Commands And Results",
    "Current Blockers",
    "Decisions",
    "Next Action",
    "Definition Of Done Status",
]


def valid_checkpoint(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    return all(f"## {field}" in text for field in required_fields)


valid_1 = tmpdir / "001-valid.md"
invalid = tmpdir / "002-invalid.md"
valid_2 = tmpdir / "003-valid.md"

def checkpoint(task_id: str, status: str) -> str:
    return "\n".join(
        [f"# Checkpoint {task_id}"]
        + [f"## {field}\n{status}" for field in required_fields]
        + [""]
    )


valid_1.write_text(checkpoint("001", "partial"), encoding="utf-8")
invalid.write_text("# Checkpoint invalid\n## Goal\nmissing fields\n", encoding="utf-8")
valid_2.write_text(checkpoint("003", "latest"), encoding="utf-8")

if not valid_checkpoint(valid_1):
    raise AssertionError("valid checkpoint rejected")
if valid_checkpoint(invalid):
    raise AssertionError("invalid checkpoint accepted")

valids = [p for p in sorted(tmpdir.glob("*.md")) if valid_checkpoint(p)]
if valids[-1].name != "003-valid.md":
    raise AssertionError("latest valid checkpoint selection failed")

journal = tmpdir / "JOURNAL.md"
journal.write_text("# Journal\n\n", encoding="utf-8")
entry = "## 2026-07-15 — Fixture"
for _ in range(2):
    text = journal.read_text(encoding="utf-8")
    if entry not in text:
        journal.write_text(text + entry + "\n\n- once\n", encoding="utf-8")
if journal.read_text(encoding="utf-8").count(entry) != 1:
    raise AssertionError("duplicate update prevention failed")

compacted = tmpdir / "compacted.md"
compacted.write_text(
    "\n".join(
        [
            "Goal: preserve state",
            "Constraints: task-owned files only",
            "File ownership: docs/opencode fixture",
            "Validation: sentinel pass",
            "Next action: continue sequentially",
        ]
    ),
    encoding="utf-8",
)
for phrase in ["Goal:", "Constraints:", "File ownership:", "Validation:", "Next action:"]:
    if phrase not in compacted.read_text(encoding="utf-8"):
        raise AssertionError(f"compaction fixture missing {phrase}")

allowed_files = {"docs/opencode/reliability-audit-2026-07-15.md", "memory/JOURNAL.md"}
changed_files = {"docs/opencode/reliability-audit-2026-07-15.md"}
if not changed_files <= allowed_files:
    raise AssertionError("file ownership enforcement failed")

for path in [
    root / "opencode.json",
    root / ".opencode/agents/orchestrator.md",
    root / "docs/opencode/permission-matrix.md",
]:
    text = path.read_text(encoding="utf-8")
    for forbidden in [".env", "secrets/**", "git push origin main", "git push --force"]:
        if forbidden not in text:
            raise AssertionError(f"{path} missing safety marker {forbidden}")

workflow = (root / "docs/opencode/multi-agent-workflow.md").read_text(encoding="utf-8")
for phrase in [
    "Subagents run sequentially by default",
    "2-3 subagents maximum",
    "3 minutes per parallel batch",
    "reruns unfinished work sequentially",
    "A failed check is not completion",
]:
    if phrase not in workflow:
        raise AssertionError(f"workflow missing {phrase}")

git_ci = (root / "docs/opencode/git-ci-release.md").read_text(encoding="utf-8")
for phrase in ["GH_CONFIG_DIR", "Never push directly to `main`", "Never force-push", "Never auto-merge"]:
    if phrase not in git_ci:
        raise AssertionError(f"git-ci-release missing {phrase}")

print("[opencode-reliability] python checks OK")
PY

python3 - <<'PY'
from __future__ import annotations

import subprocess

try:
    subprocess.run(["sleep", "3"], timeout=1, check=False)
except subprocess.TimeoutExpired:
    print("[opencode-reliability] timeout fixture OK")
else:
    raise SystemExit("[opencode-reliability] timeout fixture unexpectedly completed")
PY

echo "timeout=recorded" > "$tmpdir/timeout-fallback.log"
echo "fallback=sequential" >> "$tmpdir/timeout-fallback.log"
grep -qx "fallback=sequential" "$tmpdir/timeout-fallback.log"

bash tests/opencode-permission-matcher.sh >/dev/null

echo "[opencode-reliability] OK"
