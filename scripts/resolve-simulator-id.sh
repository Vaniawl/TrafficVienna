#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${TRAFFICVIENNA_SIMULATOR_ID:-}" ]]; then
  printf '%s\n' "$TRAFFICVIENNA_SIMULATOR_ID"
  exit 0
fi

simulator_name="${TRAFFICVIENNA_SIMULATOR_NAME:-iPhone 17}"
device_lines="$(xcrun simctl list devices available)"
matches=()
booted=()

while IFS=' ' read -r state identifier; do
  [[ -n "$identifier" ]] || continue
  matches+=("$identifier")
  if [[ "$state" == "Booted" ]]; then
    booted+=("$identifier")
  fi
done < <(
  printf '%s\n' "$device_lines" |
    sed -nE "s/^[[:space:]]*${simulator_name} \(([[:xdigit:]-]+)\) \((Booted|Shutdown)\).*$/\2 \1/p"
)

if (( ${#booted[@]} > 0 )); then
  if (( ${#booted[@]} > 1 )); then
    printf 'warning: multiple booted %s simulators; selecting %s\n' \
      "$simulator_name" "${booted[0]}" >&2
  fi
  printf '%s\n' "${booted[0]}"
  exit 0
fi

if (( ${#matches[@]} == 0 )); then
  printf 'error: no available simulator named %s\n' "$simulator_name" >&2
  exit 1
fi

if (( ${#matches[@]} > 1 )); then
  printf 'warning: multiple %s simulators; selecting %s\n' \
    "$simulator_name" "${matches[0]}" >&2
fi

printf '%s\n' "${matches[0]}"
