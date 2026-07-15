# OpenCode Model Matrix

## Runtime Inventory

Observed on AIServer with:

```bash
opencode --version
OPENCODE_LITELLM_BASE_URL=http://127.0.0.1:4000/v1 opencode models
```

- OpenCode CLI: `1.17.20`
- Provider in use: global `local-litellm`
- Cloud providers are disabled by the global OpenCode configuration on AIServer.

| Model ID | LiteLLM alias | Backend | Context |
|---|---|---|---:|
| `local-litellm/gpt-oss-120b` | `gpt-oss-120b` | local managed llama.cpp Vulkan | 131072 |
| `local-litellm/qwen-27b` | `qwen-27b` | local llama-swap GGUF | 32768 |
| `local-litellm/deepseek-q6-70b` | `deepseek-q6-70b` | local managed llama.cpp Vulkan | 65536 |
| `local-litellm/coder-next` | `coder-next` | local managed llama.cpp Vulkan | 131072 |
| `local-litellm/coder-32b` | `coder-32b` | local llama-swap GGUF | 32768 |
| `local-litellm/deepseek-r1-32b` | `deepseek-r1-32b` | local llama-swap GGUF | 32768 |
| `local-litellm/local-main` | `local-main` | local llama-swap GGUF | 32768 |

## Agent Assignment

| Agent | Model | Rationale |
|---|---|---|
| orchestrator | `local-litellm/gpt-oss-120b` | strongest local long-context orchestration model |
| explorer | `local-litellm/qwen-27b` | fast local read/search-oriented model; low-risk read-only role |
| architect | `local-litellm/deepseek-q6-70b` | strong local architecture/reasoning assignment |
| implementer | `local-litellm/coder-next` | local coding-specialized model with 128k context |
| test-architect | `local-litellm/coder-32b` | local coding/test reasoning model |
| reviewer | `local-litellm/deepseek-r1-32b` | independent local review/reasoning model, different from implementer |
| security-reviewer | `local-litellm/deepseek-q6-70b` | strong local security/privacy reasoning assignment |
| release-manager | `local-litellm/local-main` | lightweight local handoff-readiness model |

## Reuse And Fallback

Seven suitable local chat aliases are available for eight agents, so
`local-litellm/deepseek-q6-70b` is intentionally reused for architecture and
security review.

No repository-level fallback model is configured. Standard agents must not use
`opencode/*`, `openai/*`, `anthropic/*`, `embedding-default`, or external
fallback aliases for chat.
