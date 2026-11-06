# cc-stuff

My [Claude Code](https://claude.ai/code) hooks, skills, commands and agents, organized as a marketplace of independent plugins.

## Install

Add the marketplace, then install the plugins you want:

    /plugin marketplace add Semior001/cc-stuff

    /plugin install debugging@semior-cc-stuff

Test a plugin locally:

    claude --plugin-dir plugins/<plugin>

## Plugins

### debugging

**rca** (skill, `/debugging:rca`) - root cause analysis that logs everything known so far in the project being debugged, one folder per case: `docs/rca/YYYYMMDD-<slug>/README.md`, with long outputs in an `evidence/` folder next to it, and finished cases moved to `docs/rca/closed/`. The log keeps the current state (problem, verified facts with evidence, hypotheses, ruled out suspects, dead ends, insights, open questions, root cause, fix) plus an append-only timeline of what was tried. It is written after every finding, so an open investigation can be resumed in a later session. It does not jump to conclusions: a hypothesis is only declared the root cause after passing a confirmation gate (every link observed, all facts explained, a test that could have failed passed, alternatives ruled out, an independent subagent review, and your acceptance); until then it is reported as a hypothesis with what is still unverified. The main session only orchestrates and keeps the log; every check runs as an agent, independent ones in parallel, and agents are told to break the hypothesis, not confirm it; the main session re-checks their evidence and is the only writer of the log. Each agent task is saved as a file in the case's `agents/` folder (the brief before the agent starts, its report when it finishes), so results survive compaction and unprocessed ones are picked up on resume. It suggests mitigations as soon as the impact is known, without waiting for the root cause, then two or three fix options with a recommendation and prevention suggestions once the cause is confirmed. When further work would not change the fix, or the evidence is out of reach, it proposes pausing the case; you decide, and a paused case keeps its open questions, says its cause is unconfirmed, and ships fixes with predictions that reopen it if they fail. Before starting, it searches earlier logs for the same symptoms. Everything under `docs/rca/` stays out of git: the skill creates `docs/rca/.gitignore` with `*`, which ignores the folder without touching the project's `.gitignore`, and warns if any case files were already committed.

**bisect** (skill, `/debugging:bisect`) - finds the commit that introduced a regression with `git bisect run`. It writes a reproduction script that checks for the specific symptom, validates it on the good and bad revisions, always resets the bisect afterwards, and records the culprit in the open RCA log. It refuses to start on a dirty working tree.

**open RCA reminder** (hook, `SessionStart` on compaction) - after the context is compacted, lists the open cases in `docs/rca/` and tells Claude to re-read the one in progress and process any agent reports not yet handled. Prints nothing when none are open.

## License

MIT
