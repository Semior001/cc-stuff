---
name: bisect
description: Find the commit that introduced a regression with git bisect run, driven by a reproduction script, and record the result in the open RCA case in docs/rca/. Use when the user says "bisect", "find the commit that broke this", "when did this start failing", or when a root cause analysis has a known good revision.
---

# Bisect

Find the first bad commit automatically: a script decides good or bad for each revision, `git bisect run` does the search.

## 1. Preconditions

1. `git status --porcelain` must be empty: bisect checks out other commits. If it is not, stop and ask the user what to do with the changes. Never stash, commit or discard them on your own.
2. `git bisect log` must fail, meaning no bisect is already in progress. If one is, ask the user before resetting it.
3. Note the current branch or commit to verify the return to it at the end.

## 2. Good and bad revisions

- **Bad**: `HEAD` unless the user names another.
- **Good**: a revision where the problem did not happen, from the user, the RCA log, or a candidate such as the latest release tag (`git describe --tags --abbrev=0`). Confirm a guessed candidate with the user before using it.

## 3. Reproduction script

Write the script outside the working tree, in the session scratchpad or a `mktemp -d` directory: a file inside the tree can be overwritten or disappear when bisect checks out another revision.

- It `cd`s to the repository root by absolute path and builds whatever it needs.
- Exit codes: `0` good, `1` bad, `125` skip (this revision cannot be tested, e.g. it does not build for an unrelated reason). Never exit with 126-127 or above 127 on purpose: bisect treats those as bad or aborts.
- It checks for the **specific symptom** (match the error text or the wrong value), not just any failure. Otherwise an unrelated breakage somewhere in the range takes over the search.
- For a flaky symptom, it runs the check several times and exits `1` if any run fails. Pick the count from the observed failure rate and say what it was.

Validate before running: the script must exit `1` at the bad revision and `0` at the good one (`git checkout --detach <good>`, run, then return). If either check gives the wrong answer, fix the script; a bisect with a wrong script gives a confident wrong answer.

## 4. Run

```
git bisect start <bad> <good>
git bisect run <script>
```

Then, whatever the outcome:

1. Save `git bisect log` output.
2. `git bisect reset`, and confirm HEAD is back where it was in step 1.

If only skipped commits remain, bisect names a range instead of one commit: report the range as the result.

## 5. Record

Inspect the culprit with `git show --stat <sha>` and read the part of its diff that touches the symptom.

If an open case in `docs/rca/` covers this problem, update it following the logging rules of `/debugging:rca`:

- Known facts: the first bad commit (sha, subject), with the good and bad revisions and the script as evidence.
- Save the script and the bisect log to the case's `evidence/` folder.
- Timeline: the bisect, its range and its result.
- The culprit commit is where the problem started, not necessarily the root cause: add hypotheses about which change in it is responsible and continue the analysis from there.

Report to the user: the culprit commit, the relevant part of its change, and where it was recorded.
