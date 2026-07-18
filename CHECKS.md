# Checks

These are the required validation gates for the active goal. Commands are run
from the repository root. A check only counts when its real exit code and
relevant output are observed; `TRAFFICVIENNA_ALLOW_XCODEBUILD_SKIP=1` is local
diagnostic evidence only.

| Requirement | Exact command | Evidence required |
| --- | --- | --- |
| REQ-TV-001 | `bash scripts/test.sh` | Core regression tests pass on macOS. |
| REQ-TV-002 | `bash scripts/build.sh` | App compiles, followed by simulator UI/accessibility evidence recorded in `JOURNAL.md`. |
| REQ-TV-003 | `bash scripts/test.sh` | Focused refactoring regressions and full tests pass. |
| REQ-TV-004 | `bash scripts/test.sh` | Failure/localisation tests pass and affected UI states are inspected. |
| REQ-TV-005 | `bash scripts/test.sh` | Cancellation, coalescing, throttling, and performance checks pass. |
| REQ-TV-006 | `bash scripts/ci.sh` | Full macOS repository, build, test, and whitespace validation exits 0. |
| REQ-TV-007 | `bash scripts/validate-repository.sh` | State relationships pass, then reviewer and security-reviewer report no Blocking/Important findings. |
| REQ-TV-008 | `bash scripts/test.sh` | Feature tests for new functionality pass. |
| REQ-TV-009 | `bash scripts/test.sh` | Account lifecycle tests pass after provider configuration; anonymous use still works. |

## OpenCode migration checks

```bash
bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
```

## Safe server-side checks

These checks do not replace Xcode evidence, but they must stay green during
implementation:

```bash
git diff --check
bash scripts/validate-repository.sh
bash scripts/validate-opencode.sh
```

## Platform limitation

`xcodebuild` is unavailable on AIServer Ubuntu. Continue all safe implementation,
review, documentation, and local validation work on the server. Final completion
still requires a suitable macOS/Xcode environment; report `CONTINUE`, not
`COMPLETE`, while that evidence is unavailable.
