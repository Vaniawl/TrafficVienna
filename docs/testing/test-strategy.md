# Test Strategy

TrafficVienna uses repository structure and OpenCode validators, permission and recovery
tests, Xcode build gates, and the shared scheme's XCTest/XCUITest targets. The existing
test requirements and recorded evidence remain in `SPEC.md`, `CHECKS.md`, `STATUS.md`, and
the release documents under `docs/release/`.

Agent-framework adoption adds catalog validation, generated-artifact drift detection,
and focused portable framework tests before the existing build and test commands. The
complete eval suite remains a documented manual diagnostic below.
These gates do not replace native evidence. A missing Xcode or Simulator is reported as a
limitation and never represented as a passing native run.

Required repository gates are:

```sh
python3 -m pip install -r requirements-dev.txt
bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
python3 -m unittest -v tests.agent-framework.test_generated_artifacts tests.agent-framework.test_project_opencode tests.agent-framework.test_provider_shims
bash scripts/ci.sh
```

## Manual framework diagnostics

The full source-framework unit suite includes starter workflow-contract tests and is not an
adopter CI gate. The complete eval suite is also diagnostic until the approved dependency
cleanup removes tracked `node_modules/`; E18 currently fails on sensitive-looking files in
that preserved baseline. Run these commands directly and preserve their real exit status:

```sh
python3 -m unittest discover -s tests/agent-framework -t .
python3 scripts/agent-framework/evals/run-evals.py --report /tmp/traffic-vienna-evals.json
```
