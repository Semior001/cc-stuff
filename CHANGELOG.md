# Changelog

Entries are per plugin, headed `## <plugin> v<version> - YYYY-MM-DD`, grouped into New Features, Improvements, Bug Fixes, Other.

## debugging v0.1.4 - 2026-11-06

### Bug Fixes

- `rca` timeline entries were written with Edit anchored on an arbitrary line, which overwrote earlier entries. Entries are now appended only by `scripts/append-timeline.sh`, which writes to the end of the log, adds the timestamp, and refuses when any heading, of any level, follows Timeline
- `rca` never issues two writes to the log in the same message, so a parallel Edit cannot drop a timeline entry
- `rca` processes one agent report fully, including its `processed` entry, before opening the next
- `rca` log no longer has an `Updated:` field that went stale; the last timeline entry shows when the log last changed

## debugging v0.1.3 - 2026-11-05

### Improvements

- `rca` main session only orchestrates: every check, including the first fact gathering, single quick checks, prior art search and bisect, runs as an agent task, so investigation output no longer fills the main context. The main session reads only the log, task files and the few lines agents cite as key evidence

## debugging v0.1.2 - 2026-11-05

### Bug Fixes

- `rca` agents were briefed with the log path, so they read the hypothesis states, the timeline reasoning and other agents' reports and leaned toward the current favorite. Briefs now carry only the problem, the facts relevant to the question, a neutrally phrased question and what not to retry, and agents are told not to read `docs/rca/` beyond their own task file. The adversarial check gets the claimed chain and facts in its brief instead of the log

## debugging v0.1.1 - 2026-11-05

### Bug Fixes

- `rca` stopped to ask what to do next when the next tests were safe, and listed the options as plain text: it now runs safe tests without asking, in parallel when independent, and asks only before touching production or shared systems, when it needs something only the user has, or at a real fork, always with a selectable question
- `rca` no longer tells the investigator to test strictly one hypothesis at a time, which conflicted with parallel investigation
- `rca` asks before any access to production; a grant holds for the current session only and is never read back from the log
- `rca` treats production as read-only even with access granted: no changes, nothing created (test messages, debug containers, jobs), nothing destructive; tests that need a production change are described and left to the user. Agent briefs carry the same restriction

## debugging v0.1.0 - 2026-11-05

### New Features

- `rca` skill: root cause analysis with a persistent investigation log in `docs/rca/`, prior art search in earlier logs, and an evidence directory for long outputs
- `rca` confirmation gate: a hypothesis becomes the root cause only when every link was observed, it explains all known facts, a test that could have failed passed, alternatives were ruled out, a fresh subagent found no gap, and the user accepted it
- `rca` symptom characterization before hypotheses (continuous or episodic, scope, direction, recent restarts or changes), and a trap against reading familiar error text as the cause, with a worked example
- `rca` accounts for what the reporter has already ruled out before ranking hypotheses; the log template records who reported the problem and what they checked
- `rca` hypotheses drawn from several areas (code, configuration, architecture, dependencies, process), a 5-Why ladder down to the process level, and support for multiple contributing causes
- `rca` gate requires reading library source at the version in use before claiming what it does, counting symptom variants so a cause must explain them in proportion, and separating verified from inferred in every report; adds a trap for plausible but unread mechanisms
- `rca` parallel investigation: independent hypothesis tests, link checks and fact gathering run as up to 4 agents per round, with self-contained briefs that hide the favored hypothesis, a fixed answer format, the main session as the only writer of the log, and agent evidence re-checked before it counts; each agent task is saved to `<case>/agents/` (brief before spawning, report appended by the agent) and marked processed in the timeline, so results survive compaction
- `rca` keeps each investigation in its own folder, `docs/rca/<YYYYMMDD>-<slug>/` with the log as `README.md` and an `evidence/` folder, and moves finished cases to `docs/rca/closed/`
- `rca` keeps `docs/rca/` out of version control with a self-ignoring `docs/rca/.gitignore` (`*`), warns about case files already tracked, and never commits or cites case files
- `bisect` skill: find the commit that introduced a regression with `git bisect run` and record it in the open RCA log
- `SessionStart` hook: after compaction, point Claude back at open RCA logs
