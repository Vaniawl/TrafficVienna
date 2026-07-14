#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
cd "$ROOT"

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

opencode debug agent orchestrator > "$tmp_json"

python3 - "$tmp_json" <<'PY'
from __future__ import annotations

import fnmatch
import json
import sys
from pathlib import Path

raw = Path(sys.argv[1]).read_text(encoding="utf-8")
agent = json.loads(raw[raw.index("{"):])
rules = agent["permission"]


def resolve(permission: str, value: str) -> str:
    action = "allow"
    for rule in rules:
        if rule.get("permission") != permission:
            continue
        pattern = rule.get("pattern", "*")
        if fnmatch.fnmatchcase(value, pattern):
            action = rule["action"]
    return action


cases = [
    ("bash", "bash scripts/ci.sh", "allow"),
    ("bash", "bash scripts/build.sh", "allow"),
    ("bash", "bash scripts/test.sh", "allow"),
    ("bash", "xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build", "allow"),
    ("bash", "xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test", "allow"),
    ("bash", "git switch -c codex/demo", "allow"),
    ("bash", "git push -u origin codex/demo", "allow"),
    ("bash", "git push origin main", "deny"),
    ("bash", "git push origin HEAD:main", "deny"),
    ("bash", "git push --force-with-lease origin HEAD", "deny"),
    ("bash", "gh pr create --draft --base main --head codex/demo --title test", "allow"),
    ("bash", "gh pr merge 1", "deny"),
    ("bash", "npm i some-new-package", "ask"),
    ("bash", "fastlane release", "ask"),
    ("bash", "rm -rf build", "deny"),
    ("task", "explorer", "allow"),
    ("task", "implementer", "allow"),
    ("task", "orchestrator", "deny"),
    ("read", ".env", "deny"),
    ("read", "secrets/token.txt", "deny"),
    ("read", "README.md", "allow"),
]

failures: list[str] = []
for permission, value, expected in cases:
    actual = resolve(permission, value)
    print(f"[permission-matcher] {permission} {value!r} -> {actual}")
    if actual != expected:
        failures.append(f"{permission} {value!r}: expected {expected}, got {actual}")

if failures:
    print("[permission-matcher] FAIL")
    for failure in failures:
        print(f"  {failure}")
    raise SystemExit(1)

print("[permission-matcher] OK")
PY
