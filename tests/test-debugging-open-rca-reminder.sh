#!/usr/bin/env bash
# tests for plugins/debugging/scripts/open-rca-reminder.sh
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/plugins/debugging/scripts/open-rca-reminder.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
check() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        echo "PASS: $name"
        return
    fi
    echo "FAIL: $name"
    echo "  want: $want"
    echo "  got:  $got"
    fails=$((fails + 1))
}

run() { CLAUDE_PROJECT_DIR="$1" bash "$script"; }

# no docs/rca directory
mkdir -p "$tmp/empty"
check "no rca directory prints nothing" "" "$(run "$tmp/empty")"

# closed cases, a resolved case not moved yet, an open marker that is not on its own line
mkdir -p "$tmp/closed/docs/rca/closed/20260101-a" "$tmp/closed/docs/rca/20260102-b" "$tmp/closed/docs/rca/20260103-c"
printf '# RCA: a\n\nStatus: open\n' > "$tmp/closed/docs/rca/closed/20260101-a/README.md"
printf '# RCA: b\n\nStatus: resolved\n' > "$tmp/closed/docs/rca/20260102-b/README.md"
printf '# RCA: c\n\nStatus: abandoned\n\nnote: Status: open was the old value\n' > "$tmp/closed/docs/rca/20260103-c/README.md"
check "closed cases print nothing" "" "$(run "$tmp/closed")"

# open cases are listed relative to the project root; evidence files and loose files are not
mkdir -p "$tmp/open/docs/rca/20260104-d/evidence" "$tmp/open/docs/rca/20260105-e" "$tmp/open/docs/rca/20260106-f"
printf '# RCA: d\n\nStatus: open\n' > "$tmp/open/docs/rca/20260104-d/README.md"
printf 'Status: open\n' > "$tmp/open/docs/rca/20260104-d/evidence/README.md"
printf '# RCA: e\n\nStatus: resolved\n' > "$tmp/open/docs/rca/20260105-e/README.md"
printf '# RCA: f\n\nStatus: open\n' > "$tmp/open/docs/rca/20260106-f/README.md"
printf 'Status: open\n' > "$tmp/open/docs/rca/20260107-loose.md"
out="$(run "$tmp/open")"
check "lists open cases" "- docs/rca/20260104-d/README.md
- docs/rca/20260106-f/README.md" "$(grep '^- ' <<<"$out")"
check "mentions compaction" "1" "$(grep -c 'Context was compacted' <<<"$out")"

# falls back to the working directory without CLAUDE_PROJECT_DIR
out="$(cd "$tmp/open" && env -u CLAUDE_PROJECT_DIR bash "$script" | grep -c '^- ')"
check "falls back to working directory" "2" "$out"

if [[ $fails -gt 0 ]]; then
    echo "$fails test(s) failed"
    exit 1
fi
echo "all tests passed"
