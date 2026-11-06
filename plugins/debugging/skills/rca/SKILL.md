---
name: rca
description: Root cause analysis of a bug, failure or unexpected behavior, with every fact, hypothesis, dead end and insight logged as it is found to its own folder under docs/rca/, so the investigation can be resumed later. Use when the user says "rca", "root cause", "investigate this", "find out why", "dig into this failure", or asks to resume an investigation.
---

# Root Cause Analysis

Find the fundamental cause of a problem, not a fix for its symptom, and keep a log of everything known so far in `docs/rca/`. The log is the memory of the investigation: anyone, including a later session after context compaction, must be able to continue from it alone.

Each investigation is one folder, so everything about a case stays together and a person browsing `docs/rca/` sees one entry per case, with finished ones out of the way:

```
docs/rca/
  20261105-export-context-canceled/   # in progress
    README.md                         # the log
    evidence/                         # outputs too long for the log
    agents/                           # one file per agent task: brief and report
  closed/
    20261012-login-timeout/           # resolved or abandoned, same layout
```

The log is `README.md` so that it is the first thing seen when the folder is opened. Below, `<case>` is the case folder.

Everything under `docs/rca/` is private to the people and agents working on the project and never enters version control. A `docs/rca/.gitignore` containing the single line `*` ignores the whole folder, itself included, without touching the project's own `.gitignore`.

## 1. Start or resume

1. Make sure `docs/rca/.gitignore` exists and contains `*`; create it if not. Then check `git ls-files docs/rca`: if it lists anything, those files were committed before and the ignore file does not hide them. Tell the user which files are tracked and leave untracking them to the user; do not run `git rm` yourself.
2. List the case folders directly under `docs/rca/` (not `closed/`): those are the investigations in progress.
3. If one matches the problem, read its `README.md` fully and continue from it. Then check `<case>/agents/` for reports the timeline does not mark as processed, and process them (see Agents) before anything else: they hold results that arrived after the last log update. Do not repeat anything listed under Ruled out or Dead ends unless new evidence justifies it, and say what that evidence is.
4. If none matches, create the case folder `docs/rca/<YYYYMMDD>-<slug>/` (date from `date +%Y%m%d`, slug of 2-5 kebab-case words naming the symptom, not a suspected cause) and its `README.md` from the template in `${CLAUDE_PLUGIN_ROOT}/skills/rca/references/log-template.md`. Fill Problem and Environment from what the user gave; mark gaps as unknown. Add the first timeline entry, `case opened`, with the timeline script (see Logging rules).
5. Search the closed cases in `docs/rca/closed/` for prior art, and the other open ones too, through an agent (see Agents): it greps them for the exact error text, the components involved and key symptoms, and returns the matching cases with their Root cause, Insights and Dead ends. This is the one agent allowed to read `docs/rca/`. Carry over what applies: as a Known fact if it still verifiably holds, otherwise as a hypothesis. Cite the earlier log either way.
6. Tell the user the log path.

## 2. Investigate

The main session orchestrates and agents investigate. The main session frames the problem, forms hypotheses, writes briefs, processes reports, keeps the log, talks to the user and runs the confirmation gate. It does not check anything itself: no reading code or library source, no grepping logs, no running tests, builds or bisects, not even a "quick look". Each of those fills the main context with output that is needed once, and a context that fills up gets compacted and loses the thread. Every check, however small, is an agent task (see Agents). The main session reads only the case log, agent task files and the few lines an agent cites as key evidence (Agents, rule 7).

Loop until a hypothesis passes the confirmation gate (section 3):

1. **Gather facts, through agents.** The first round of agents reads the code, logs, configs and history (`git log`, `git blame`, `git log -S '<code>'` to find when a line appeared). Reproduce the problem if at all possible. Pin down the shape of the symptom before explaining it: continuous or episodic, since when, how often, on which instances and which not, which component reports it and in which direction (inbound or outbound, caller or callee), and whether anything restarted, deployed or changed around its start. These are facts to log, and every later hypothesis must fit them. When the problem is a regression and a good revision is known, an agent following `${CLAUDE_PLUGIN_ROOT}/skills/bisect/SKILL.md` finds the commit that introduced it.
2. **Form hypotheses.** First, account for what the reporter has already ruled out. Someone escalating a problem has usually looked at the obvious: what they can see in their own tools (restart counts, their recent deploys, dashboards, the error itself), and the way they describe it is evidence too. "Still failing" from the person who owns the service is different from "it keeps crashing". A cause the reporter could have confirmed in seconds is not a leading candidate: give its quick check to an agent alongside the real tests, or put it last. Log what the reporter checked under Problem.

   Then form at least two competing hypotheses before testing any: a single hypothesis is a conclusion in disguise. Draw them from more than one area: the code itself, configuration and environment differences, architecture and design limits (coupling, capacity, scaling), external dependencies (other services, libraries, network), and process (deploy order, missing validation). Each states what must be true if it is the cause, what would prove it wrong, and how to check that cheaply.
3. **Test, through agents.** One test per hypothesis at a time, designed so it can fail; prefer tests that eliminate the most hypotheses. Tests of different hypotheses that are independent run as parallel agents in one round.
4. **Log it** (see section 4): process each report and update the log before dispatching the next round.
5. **Go deeper.** A confirmed cause that is itself explained by something else is not the root. Keep asking why, typically down this ladder: the immediate cause (the failing operation), the mechanism in the code or config, the system condition that enabled it, the design decision behind that, and finally why the process let it ship unnoticed (no test, no alert, no review of that path). Stop when the next answer is outside the system's control or is a deliberate decision. Five levels is typical, not a rule, and every level needs the same evidence as the first.

A hypothesis is in one of four states: `open` (untested), `supported` (evidence is consistent with it, but no test that could have disproved it has passed yet), `confirmed` (passed the gate), `rejected`. Evidence that merely fits makes a hypothesis `supported`, never `confirmed`.

### Asking the user

Keep going without asking while the next steps are safe: reading code, library source, local logs and files, running local tests and builds. Do not end a turn with "what would you like me to do next?" when the next tests are obvious and safe: dispatch them.

Stop and ask only when:

- **The next action touches production.** Ask before any access to a production cluster or system, read-only included, unless the user allowed it earlier in this same session. A permission never outlives the session: a resumed session or a new session asks again, whatever the log says. Note each grant in the timeline as history, never as a standing permission.
- **The next action changes a shared non-production environment** (staging, a shared dev cluster or database).
- **Only the user has what is needed:** logs or dashboards you cannot reach, access, context about the system or the report.
- **The direction forks** and the evidence gives no clear winner.

**Production is read-only, always, even with access granted.** Allowed: reading state, logs, events and metrics (`kubectl get`, `describe`, `logs`, `top`, `events`; `port-forward` to read a metrics or debug endpoint; read-only queries). Never, whatever the user grants for access: changing anything (`apply`, `edit`, `patch`, `scale`, `rollout restart`, `label`, `annotate`, `delete`, config or feature flag changes), creating anything (`run`, `debug` ephemeral containers, jobs, test messages, test records, load), or anything destructive (killing pods or processes, purging queues, deleting data). `exec` only for a command that reads, never one that writes or signals. When a command's effect is unclear, do not run it: find out, or ask. When a test needs a change in production, do not do it: describe the test and why it is needed, and leave it to the user.

Ask with the AskUserQuestion tool, never as a question in plain text followed by a list. Give 2-4 concrete options, the recommended one first and marked "(Recommended)", each saying what it does and which hypotheses it can confirm or reject. Put independent questions into one call. Before asking, dispatch every safe test that does not depend on the answer.

### Agents

Every check is an agent task, even a single one. When several tasks do not depend on each other's results, spawn them in a single message. Typical tasks:

- **Test one hypothesis:** look for the evidence that would prove it wrong, and for what is needed to complete its chain.
- **Verify one link:** "does cancellation from the caller reach this send?" Read the code path, library source included, and report what it does.
- **Gather facts in one area:** count error variants in the logs, check instance restarts and deploy history, read one dependency's handling of X.

Rules:

1. **One narrow question per agent.** It must not need another agent's answer. A task that changes local shared state (checking out revisions for a bisect, editing local config, restarting local services, adding instrumentation) runs as the only agent in its round, or in its own git worktree (`isolation: "worktree"`) alongside others. Production is never changed at all (see Asking the user).
2. **Up to 4 agents per round.** More costs more than it adds; split further only when a round returns.
3. **A self-contained brief without your preference.** The agent knows only what the brief says, and it does not get the log: the log carries hypothesis states, the reasoning in the timeline and other agents' reports, all of which steer it toward the current favorite. Write the context into the brief instead:
   - the problem as observed: symptom, exact error text, environment;
   - only the Known facts relevant to its question, as plain facts with their evidence;
   - the one question, phrased neutrally ("does cancellation from the caller reach this send?", not "confirm that it does"), with what would answer it either way;
   - what not to retry, as actions already taken and their results, not as conclusions about hypotheses;
   - whether it may access production (only if the user allowed it in this session) and that such access is read-only as defined in Asking the user;
   - the path of its task file (rule 5), and where to save output longer than about 20 lines (`<case>/evidence/<task-slug>-<name>`);
   - that it must not read anything under `docs/rca/` other than its own task file.

   Never mention other hypotheses, their states, which one you favor, or your reasoning toward it: an agent handed a conclusion tends to return it confirmed. Ask it to try to break the idea it is testing, not to support it.
4. **A fixed answer format.** Ask each agent to write its report in this format and return the same text: verdict (`supported`, `rejected` or `inconclusive`); verified facts, each with evidence (`file:line`, a command and the relevant lines of its output); inferences, labeled as such and kept apart from facts; what it could not check and why; new questions.
5. **Every task is saved to a file, before and after.** Results that exist only in the conversation are lost on compaction, and agents may finish after it. So:
   - Before spawning, the main session writes the brief to `<case>/agents/<YYYYMMDD-HHMM>-<task-slug>.md` under a `## Brief` heading, and adds a timeline entry `dispatched <task-slug> -> agents/<file>`.
   - The brief tells the agent to append its report to that file under a `## Report` heading before returning. A task file without `## Report` is a task that never finished: rerun it or record it as a dead end.
   - Once a report has been processed (rule 7 and the log updated), add a timeline entry `processed <task-slug>: <verdict>`. A report without that entry is unprocessed, and resuming picks it up.
   - Process one report at a time: every log section it touches, then its `processed` entry, before opening the next report, even when several agents finished together.
6. **Agents do not edit the log.** The main session is its only writer, so parallel agents never overwrite each other; each agent writes only its own task file and evidence files.
7. **Agent results are claims.** Before moving a hypothesis to `rejected` or counting a link as verified, re-read the key evidence the agent cites: only the cited lines and output, a few per report. When checking a report needs more than that, dispatch a verification agent instead of investigating in the main session. An agent's verdict carries no more weight than its evidence. An `inconclusive` result goes into Open questions with what blocked it.

Do not change production code to fix the problem until the root cause is confirmed, unless the user asks. Temporary instrumentation (extra logging, a failing test, a debug print) added by an agent is fine; record it in the timeline and have an agent remove it at the end.

## 3. Confirmation gate

The most common failure of an investigation is stopping at the first explanation that fits. A hypothesis becomes the root cause only when every point below holds, each backed by evidence written in the log:

1. **Verified, not inferred.** Every link in the chain from cause to symptom was observed: the code path was shown to execute (a log line, a debug print, a stack trace, a failing test), or traced through source that was actually read, not just assumed to work the way it sounds. Library and framework code counts: read it at the exact version in use (from the lockfile or `go.mod`) in the module cache, vendor directory or installed packages, before claiming what it does. The code read is the code that actually runs: right revision, right build, right config, right dependency version.
2. **It explains everything.** It accounts for every entry in Known facts: when it happens and when it does not, where it happens and where not, frequency, timing. Count the variants of the symptom (each distinct error message, status code, failure mode) and check the hypothesis accounts for each in proportion: a cause that explains a handful of hundreds of errors is a side note, not the cause. One unexplained fact means it is not confirmed; add that fact as an open question.
3. **A test that could have failed, passed.** A prediction derived from the hypothesis was checked and held. The strongest form is control: introducing the cause produces the symptom, and removing it alone makes the symptom go away.
4. **Alternatives were settled.** Every other hypothesis is either in Ruled out with evidence, not dismissed as "less likely", or confirmed through this same gate as a contributing cause. Problems often have more than one cause; the root cause section then lists each with its share of the symptom.
5. **Adversarial check.** Spawn a fresh subagent, with a task file like any other agent but not the log: its brief holds the problem, every Known fact with its evidence, the claimed cause chain, Ruled out with its evidence, and this gate. Ask it to find a gap: an unexplained fact, an unverified link, an untested alternative. Do not pass it your reasoning or your preferred answer. Address every gap it finds, or record why it does not apply.

Traps that do not count as confirmation:

- A fix that makes the symptom disappear. It may mask the cause or change timing; it confirms nothing until the mechanism is shown.
- A single passing run of an intermittent problem.
- "This code looks wrong." Wrong-looking code that is not on the failing path, or whose effect was not observed, is a suspect, not a cause.
- Matching a known pattern or an earlier RCA. Prior art gives a hypothesis, not a conclusion.
- Reading the error text as the cause. `context canceled`, `connection reset`, `EOF`, `timeout` say what happened to one operation, not why. Before blaming the familiar cause behind such a message, write down what must be true if it is that cause and check each point.

  Example: a service forwarding messages to a broker logged `context canceled` with thousands of rejected items, and the investigation concluded "the pod was shutting down". Four checks would have refuted it. The pod had last restarted hours earlier, and the instance had not changed since. The error fired every few seconds on that same running pod: continuous, not a one-off shutdown. The paired `transport is closing` warnings were on the inbound connection from clients, not the outbound one to the broker. And the developer who reported it had escalated with "still having the problem", not "the pod keeps crashing": a restart from their own release, an OOM kill or a failing probe would have been obvious to them in the pod status. The next trap shows the mistake the same investigation made after that.
- A mechanism that would explain the symptom, unread. "The library cancels the context when it sheds load" sounds like an answer and is only a hypothesis until the code doing it has been found. State it as a hypothesis, read the source, then decide.

  Example: in the same investigation, the next claim, stated as fact, was "the client library's queue cancels the send context when a batch is in flight too long or load must be shed". None of the relevant library code had been read, though all of it was on disk. Reading it showed: the batcher sends with a fresh background context, so cancellation from the caller cannot reach the send at all; a timeout wrapper around each send produces `context deadline exceeded`, not `context canceled`, and the logs had a couple of those against hundreds of cancellations; and round-trips to the broker took tens of milliseconds, so nothing was close to the timeout. Both mechanisms were disproved, and the honest state was "root cause not yet known, one candidate left to read", not a conclusion.
- The words "likely", "probably", "should", "seems", "must be" anywhere in the chain. Each one marks a link still to verify.

Until the gate passes, never tell the user "the cause is X". Report the leading hypothesis as a hypothesis: what supports it, what is still unverified, and the next test. In every report, keep what was verified (with its evidence) apart from what was inferred, and label which is which.

## 4. Logging rules

Write to the log immediately after every finding: a new fact, a hypothesis formed or changing state, a dead end, an insight, a new question. Never batch several findings into one write at the end.

- **State sections** (Problem through Fix) describe what is known now: rewrite them as knowledge changes.
- **Timeline** is append-only and stays the last section of the log. Add to it only with `bash ${CLAUDE_PLUGIN_ROOT}/scripts/append-timeline.sh <case>/README.md "<action> -> <outcome>"`, one call per entry. The script appends to the end of the file and adds the timestamp, so no earlier entry can be overwritten. Never write timeline entries with Edit or Write, and never put two entries in one call. Nothing goes below Timeline: new hypotheses, facts and other sections go in their own sections above it. If the script refuses, fix the log structure (Timeline must be last) and retry; do not work around it. The last entry's timestamp is when the log was last updated.
- **Facts vs assumptions.** Known facts holds only what was verified, each with its evidence (`file:line`, the command and the relevant part of its output, a log line). Anything unverified is a hypothesis or an open question.
- **Rejected hypotheses move to Ruled out** with the evidence that rejected them. Never delete them: they keep the next session from retrying them.
- **Dead ends** are approaches that failed, not wrong suspects: a repro that did not trigger, a tool that did not help, a fix attempt that did not work. Record why.
- **Insights** are what was learned about the system that holds beyond this bug: a hidden coupling, a misleading name, an undocumented behavior.
- **Large evidence goes to files.** Output longer than about 20 lines (stack dumps, full test runs, profiles, bisect logs) is saved under `<case>/evidence/`, named for what it holds (`error-counts.txt`, `bisect.log`). The log links the file and quotes only the relevant lines, so it stays cheap to re-read.
- **One write to the log at a time.** Never issue two tool calls that write the log in the same message (an Edit and a timeline append, or two Edits): an Edit that reads the file before a parallel write lands and writes after it silently drops that write.
- Keep entries short and concrete. Quote exact error text; do not paraphrase it.

## 5. Conclude

When a hypothesis passes the confirmation gate:

1. Fill Root cause with the chain from symptom to fundamental cause, evidence at every step, and the Confirmation checklist with the evidence for each point.
2. Present the root cause, its evidence and the checklist to the user, and ask them to accept it. Any doubt they raise goes back into the investigation loop as an open question; the log stays `open` until they accept.
3. Fill Fix with the proposed fix. If the user asks to apply it, apply it, verify it against the original reproduction, and record how it was verified.
4. Remove temporary instrumentation and note it in the timeline.
5. Set `Status: resolved`. If the user stops the investigation without a conclusion, set `Status: abandoned` and make sure Open questions says where to pick up. Either way, move the case folder into `docs/rca/closed/` (`mkdir -p` it first). Resuming an abandoned case moves it back and sets `Status: open`.
6. Report to the user: the root cause in one or two sentences, the fix, and the log path.

Never stage or commit anything under `docs/rca/`, and do not mention case files in commit messages, PR descriptions or code comments: they are for the investigators only.
