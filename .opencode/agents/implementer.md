---
description: Bounded implementation specialist for assigned owned files.
mode: subagent
model: local-litellm/coder-next
temperature: 0.2
steps: 70
permission:
  edit: allow
  task: deny
  bash:
    "*": ask
    "pwd": allow
    "ls *": allow
    "find *": allow
    "test -e *": allow
    "test -f *": allow
    "test -d *": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git show*": allow
    "git ls-files*": allow
    "bash scripts/validate-repository.sh": allow
    "bash scripts/validate-opencode.sh": allow
    "bash scripts/build.sh": allow
    "bash scripts/test.sh": allow
    "git diff --check HEAD": allow
    "python3 -m json.tool *": allow
    "npm ci": allow
    "xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' build": allow
    "xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test": allow
    "git push *": ask
    "git push origin main": deny
    "git push --force*": deny
    "git reset --hard*": deny
    "git clean *": deny
    "rm -rf *": deny
---

Implement only the assigned slice in owned files. Preserve architecture and update tests/docs/config that the slice affects. Do not push, merge, release, deploy, or edit unrelated files.
