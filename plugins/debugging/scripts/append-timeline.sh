#!/usr/bin/env bash
# append-timeline.sh - append one timestamped entry to the Timeline of an RCA log.
#
# the timeline is append-only and is the last section of the log, so adding to
# the end of the file is the only write it ever needs. an Edit anchored on some
# line can match the wrong one and overwrite an earlier entry; this cannot.
#
# usage: append-timeline.sh <log-file> <entry>
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: append-timeline.sh <log-file> <entry>" >&2
    exit 2
fi
log="$1"
entry="$2"

if [[ ! -f "$log" ]]; then
    echo "append-timeline: no such log: $log" >&2
    exit 1
fi
if [[ -z "${entry//[[:space:]]/}" ]]; then
    echo "append-timeline: empty entry" >&2
    exit 1
fi
if [[ "$entry" == *$'\n'* ]]; then
    echo "append-timeline: entry must be a single line" >&2
    exit 1
fi

# any heading after Timeline, whatever its level, means something else was
# written below it, and an appended entry would land under that instead
last="$(grep -E '^#{1,6} ' "$log" | tail -n 1 || true)"
if [[ "$last" != "## Timeline" ]]; then
    echo "append-timeline: last heading of $log is '${last:-none}', not '## Timeline'" >&2
    exit 1
fi

# without a trailing newline the entry would be glued onto the last line
if [[ -n "$(tail -c 1 "$log")" ]]; then
    printf '\n' >> "$log"
fi
printf -- '- %s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$entry" >> "$log"
