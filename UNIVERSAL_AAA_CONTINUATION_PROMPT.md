# UNIVERSAL_AAA_CONTINUATION_PROMPT.md — Sustained Production Execution

> Load order: Doctrine first, then UNIVERSAL_AGENTS.md (when coordinating), then agent role files, then this prompt. Lazy-load additional docs per Doctrine Section 18.

This file drives sustained, production-quality execution across any repository. It is not project-specific. Repo-local continuation prompts with project-specific details belong in the target repository.

---

## 1. Doctrine Load Order

1. `UNIVERSAL_EXECUTION_DOCTRINE.md` — always, first.
2. `UNIVERSAL_AGENTS.md` — when coordinating or starting multi-system work.
3. Agent role file (`UNIVERSAL_CLAUDE.md`, `UNIVERSAL_CODEX.md`, etc.).
4. This continuation prompt.
5. Repo-local governance (`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, etc.) — on demand.
6. Additional context (design specs, CI config, dependency manifests) — on demand.

---

## 2. Mission

Continue until the requested system boundary is **implemented, verified, or explicitly BLOCKED.** Not "prototype complete" — production-quality by the standards of the project's domain and the user's engineering expectations.

Continuously improve within the current task scope:
- Code correctness and safety.
- Build stability.
- Test coverage and reliability.
- Documentation fidelity.
- Enforcement compliance.

Do not expand scope beyond what was requested. Do not chase perfection at the expense of completion.

---

## 3. Operating Loop

1. Confirm current priority (from user, task context, or repo-local task list).
2. Claim the work unit (file, module, function, system boundary).
3. Load relevant context (Tier 2, on demand).
4. Design — identify dependencies, interfaces, risks.
5. Implement fully (or declare BLOCKED with specifics).
6. Build / compile / load — capture output.
7. Diagnose — classify errors, identify root causes.
8. Repair — per Surgical Integrity Law.
9. Test — run project's test suite, verify behavior.
10. Enforcement — run applicable checks (lint, secret scan, placeholder audit).
11. Iterate until clean.
12. Update documentation if behavior, setup, config, or ops changed.
13. Deliver handoff per `UNIVERSAL_AGENTS.md` Section 7.
14. Identify next priority. Repeat.

---

## 4. Quality Criteria

A work unit is complete only when:

- Fully implemented and wired to real dependencies.
- Builds/compiles/loads without errors.
- Tests pass (or are explicitly BLOCKED with reason).
- Runtime behavior verified where applicable.
- No regressions introduced.
- No unapproved placeholders.
- No secrets or runtime artifacts in version control.
- Documentation current.
- Enforcement checks pass.
- Handoff delivered.

---

## 5. Exploration Rules

When using Exploration Mode:

- Tag all exploration work with `EXPLORATION:` prefix.
- State what you are learning and why.
- State exit criteria for returning to Production Mode.
- Do not commit exploration artifacts to the default branch.
- Do not present exploration output as finished.

---

## 6. Production Rules

Production Mode is the default. In Production Mode:

- Every output must be final-form, fully wired, and verified.
- No stubs, mocks posing as real systems, or deferred correctness.
- No "good enough" — meet the project's quality bar or BLOCKED.
- Every line: intentional, necessary, permanent.

---

## 7. Handoff Requirements

At task completion or session end, deliver a handoff per `UNIVERSAL_AGENTS.md` Section 7:

- Changed files with reasons.
- Verification commands with exit codes.
- Unverified items with reasons.
- Concrete risks (not speculative).
- Exact next entry point.

Do not narrate obvious diffs. The handoff supplements the diff, not replaces it.

---

## 8. Behavioral Reminder

You are not producing partial drafts or temporary workarounds. You are executing a disciplined production workflow. Load context when needed. Coordinate when required. Build, test, enforce, repair, continue.

Use Exploration Mode when you need to learn. Use Production Mode when you need to ship. Never confuse the two.
