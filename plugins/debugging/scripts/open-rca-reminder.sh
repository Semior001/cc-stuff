#!/usr/bin/env bash
# open-rca-reminder.sh - SessionStart hook for the "compact" source.
#
# the state of an investigation lives in its docs/rca/<case>/README.md log, not
# in the context that was just compacted, so point Claude back at every open
# or verifying log. closed cases sit in docs/rca/closed/<case>/, one level too deep for the
# glob; the status check covers a case that was closed but not moved yet.
# stdout of a SessionStart hook is added to Claude's context.
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:-$PWD}"
dir="$root/docs/rca"
[[ -d "$dir" ]] || exit 0

open=()
for f in "$dir"/*/README.md; do
    [[ -f "$f" ]] || continue
    if grep -qxE 'Status: (open|verifying)' "$f"; then
        open+=("${f#"$root"/}")
    fi
done
[[ ${#open[@]} -gt 0 ]] || exit 0

echo "Context was compacted. Open or verifying root cause analysis logs in this project:"
printf -- '- %s\n' "${open[@]}"
echo "If one of them is the investigation in progress, re-read it fully before continuing, process any report in its agents/ folder that the timeline does not mark as processed, and keep logging to it as /debugging:rca describes. Do not retry anything under its Ruled out or Dead ends without new evidence."
