#!/usr/bin/env bash
# tests for plugins/debugging/scripts/append-timeline.sh
set -euo pipefail

script="$(cd "$(dirname "$0")/.." && pwd)/plugins/debugging/scripts/append-timeline.sh"
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

append() { bash "$script" "$@" 2>/dev/null && echo ok || echo "fail $?"; }
ts='[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}'

log="$tmp/README.md"
printf '# RCA: x\n\n## Known facts\n\n- a fact\n\n## Timeline\n\nAppend-only, oldest first.\n\n- 2026-01-01 10:00 first\n' > "$log"
before="$(cat "$log")"

check "appends an entry" "ok" "$(append "$log" "dispatched check-a -> agents/a.md")"
check "appends a second entry" "ok" "$(append "$log" "processed check-a: rejected")"
check "earlier content untouched" "$before" "$(head -n "$(wc -l <<<"$before")" "$log")"
check "entries in order with timestamps" "2" "$(tail -n 2 "$log" | grep -cE "^- $ts (dispatched check-a -> agents/a.md|processed check-a: rejected)$")"
check "second entry is last" "processed check-a: rejected" "$(tail -n 1 "$log" | sed -E "s/^- $ts //")"

nonl="$tmp/nonl.md"
printf '## Timeline\n\n- 2026-01-01 10:00 first' > "$nonl"
append "$nonl" "second" >/dev/null
check "adds missing trailing newline" "- 2026-01-01 10:00 first" "$(sed -n 3p "$nonl")"
check "entry on its own line" "1" "$(sed -n 4p "$nonl" | grep -cE "^- $ts second$")"

wrong="$tmp/wrong.md"
printf '## Timeline\n\n- 2026-01-01 10:00 first\n\n## Fix\n\nsomething\n' > "$wrong"
wrong_before="$(cat "$wrong")"
check "refuses when timeline is not last" "fail 1" "$(append "$wrong" "entry")"
check "file unchanged on refusal" "$wrong_before" "$(cat "$wrong")"

sub="$tmp/sub.md"
printf '## Timeline\n\n- 2026-01-01 10:00 first\n\n### H6: misplaced hypothesis\n\n- **Predicts:** x\n' > "$sub"
sub_before="$(cat "$sub")"
check "refuses when a subheading follows timeline" "fail 1" "$(append "$sub" "entry")"
check "file unchanged on subheading refusal" "$sub_before" "$(cat "$sub")"

mid="$tmp/mid.md"
printf '## Hypotheses\n\n### H1: a - open\n\n## Timeline\n\n- 2026-01-01 10:00 first\n' > "$mid"
append "$mid" "H1 formed" >/dev/null
python3 - "$mid" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("### H1: a - open\n", "### H1: a - open\n\n### H2: b - open\n")
open(p, "w").write(s)
PY
append "$mid" "H2 formed" >/dev/null
check "entries stay together after a mid-file insert" "3" "$(sed -n '/^## Timeline/,$p' "$mid" | grep -c '^- ')"
check "mid-file insert kept" "1" "$(grep -c '^### H2: b - open$' "$mid")"

check "refuses multi-line entry" "fail 1" "$(append "$log" $'one\ntwo')"
check "refuses empty entry" "fail 1" "$(append "$log" "  ")"
check "refuses missing log" "fail 1" "$(append "$tmp/missing.md" "entry")"
check "refuses wrong argument count" "fail 2" "$(append "$log")"

if [[ $fails -gt 0 ]]; then
    echo "$fails test(s) failed"
    exit 1
fi
echo "all tests passed"
