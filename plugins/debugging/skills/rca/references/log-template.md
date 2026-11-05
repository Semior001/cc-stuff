# RCA: <short problem title>

Status: open
Started: <YYYY-MM-DD>
Updated: <YYYY-MM-DD HH:MM>

## Problem

- **Symptom:** what is observed, with the exact error text
- **Expected:** what should happen instead
- **Impact:** who or what is affected, how often
- **Reproduction:** steps, or "not reproduced yet"
- **Reported by:** who, where, in their own words
- **Already checked by the reporter:** what they ruled out or could trivially see, stated or implied by how they framed it

## Environment

Versions, commit, configuration, platform. Where it happens and where it does not.

## Known facts

Verified only. Each fact carries its evidence.

- <fact> - <evidence: file:line, command and the relevant lines of its output, log line, or a link to a file in evidence/>

## Hypotheses

State is one of: open, supported (consistent with evidence, not yet tested in a way that could fail), confirmed (passed the confirmation gate), rejected (move to Ruled out).

### H1: <statement> - open

- **Predicts:** what must be true if this is the cause
- **Disproved by:** what observation would rule it out
- **Test:** how to check it
- **Result:** pending

## Ruled out

Rejected hypotheses and suspects, moved here from above, never deleted.

- <suspect> - <why ruled out, evidence>

## Dead ends

Approaches, tools and fix attempts that did not work, so they are not repeated.

- <what was tried> - <why it failed>

## Insights

Non-obvious things learned about the system, useful beyond this bug.

## Open questions

- <question>

## Root cause

Filled once confirmed. Cause chain from symptom to the fundamental cause, each step with its evidence.

1. <symptom> because <cause> - <evidence>

### Confirmation

Every point needs evidence; an unchecked point means the root cause is not confirmed.

- [ ] Every link above was observed, on the code, build and config that actually run - <evidence>
- [ ] Explains every Known fact, including where and when it does not happen - <evidence>
- [ ] A test that could have failed passed (ideally: cause added -> symptom, cause removed -> no symptom) - <evidence>
- [ ] Every alternative is in Ruled out with evidence, or confirmed as a contributing cause
- [ ] Adversarial check by a fresh subagent: gaps found and how each was addressed - <summary>
- [ ] Accepted by the user

## Fix

Proposed or applied fix, how it was verified, follow-ups.

## Timeline

Append-only, oldest first.

- <YYYY-MM-DD HH:MM> <action> -> <outcome>
