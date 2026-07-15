# OpenCode Model Matrix

## Runtime Inventory

Observed with:

```bash
opencode --version
opencode models --verbose
```

- OpenCode CLI: `1.17.20`
- Provider in use: `opencode`
- All listed models reported zero input/output/cache cost in the installed runtime.

| Model ID | Family | Context | Output | Cost class |
|---|---:|---:|---:|---|
| `opencode/big-pickle` | `big-pickle` | 200000 | 32000 | free |
| `opencode/deepseek-v4-flash-free` | `deepseek-flash-free` | 200000 | 128000 | free |
| `opencode/hy3-free` | `hy3-free` | 190000 | 64000 | free |
| `opencode/mimo-v2.5-free` | `mimo-v2.5-free` | 200000 | 32000 | free |
| `opencode/nemotron-3-ultra-free` | `nemotron-free` | 1000000 | 128000 | free |
| `opencode/north-mini-code-free` | `north-free` | 256000 | 64000 | free |

## Agent Assignment

| Agent | Model | Rationale |
|---|---|---|
| orchestrator | `opencode/nemotron-3-ultra-free` | strongest available long-context reasoning model for long autonomous runs |
| explorer | `opencode/mimo-v2.5-free` | fast read/search-oriented model; low-risk read-only role |
| architect | `opencode/nemotron-3-ultra-free` | strongest architecture/reasoning assignment |
| implementer | `opencode/north-mini-code-free` | coding-specialized model family |
| test-architect | `opencode/hy3-free` | reliable reasoning model for validation planning |
| reviewer | `opencode/big-pickle` | independent review model family, different from implementer |
| security-reviewer | `opencode/deepseek-v4-flash-free` | strong reasoning model with large output budget for security review |
| release-manager | `opencode/big-pickle` | reliable instruction-following model for handoff readiness |

## Reuse And Fallback

Only six suitable models are available for eight agents, so `opencode/nemotron-3-ultra-free`
is intentionally reused for orchestration and architecture, and `opencode/big-pickle` is
intentionally reused for review and release handoff.

No repository-level fallback model is configured because the installed OpenCode agent files
expose a directly verifiable `model:` field, but no fallback field is verified by the current
project configuration or local validation tools. Fallback behavior must remain an explicit
future change with validation before use.
