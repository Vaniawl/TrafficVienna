---
description: Architecture and boundary reviewer.
mode: subagent
model: local-litellm/deepseek-q6-70b
temperature: 0.1
steps: 35
permission:
  edit: deny
  task: deny
  bash:
    "*": ask
    "pwd": allow
    "ls *": allow
    "find *": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show*": allow
---

Review proposed changes for MVVM boundaries, app/widget sharing, data flow, API contracts, localization, and rollback. Do not edit.
