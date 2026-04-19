# DEV-PREFERENCES.md — Shared Developer Preferences

**Scope:** All machines and agents.
**Subordinate to:** `UNIVERSAL_EXECUTION_DOCTRINE.md`.

---

## Communication

- Direct, precise, and fast. No filler.
- No subjective quality labels without measurable criteria.
- Execute tasks, don't propose them. Don't ask for permission repeatedly.
- Do not narrate obvious diffs during implementation — the diff is right there.
- Voice mode is frequent — expect typos and phonetic errors. Decode intent when confidence is high; ask when ambiguous.

## Handoff Reporting

Even when implementation narration is unwanted, every handoff must include:

- Changed files (paths and what changed).
- Verification commands executed and exit codes.
- Unverified items (what was not checked and why).
- Risks (concrete, not speculative).
- Next entry point (exact next step).

Verification claims must follow Doctrine Section 13 format: command, exit code, coverage, and unknowns.

## Code Style

- Simple over clever. No unnecessary abstractions.
- Don't add docs, comments, types, or features to unchanged code or beyond scope.
- No unapproved placeholders — Doctrine Section 6 governs all placeholder rules, approval, tracking, and allowed non-placeholder categories. If blocked, declare BLOCKED.
- Fix proportionally: targeted repair for bugs, boundary replacement for structural failures.
- Finish what you touch to production standard.

## Testing

- Test what breaks, not what works. Cover edge cases, invariants, error paths.
- Don't mock unless told to. Prefer real dependencies at test boundaries. Mocks belong only at true system boundaries.
- Never claim "tests pass" without running them. Report command, exit code, and output.

## Git Workflow

- **Rebase on pull** — `pull.rebase = true`.
- **Default branch** — `main`.
- Create new commits rather than amending unless the user explicitly asks to amend.
- Destructive operations (force-push, hard reset, branch deletion) governed by Doctrine Section 16 — require approval, never on shared branches.
- Never skip hooks (`--no-verify` prohibited unless user requests).

## Commit Messages

- Imperative mood: "fix X", not "fixed X" or "fixes X".
- Subject line <= 72 chars.
- Body explains WHY, not WHAT (the diff is the what).
- Reference issues/PRs where they exist.

## Branch Naming

- `feature/<short-description>` — new functionality
- `fix/<short-description>` — bug fixes
- `refactor/<short-description>` — no behavior change
- `chore/<short-description>` — tooling, deps, non-code

## Verification Before Completion

Before claiming a task is done:

1. The code compiles / the binary builds / the project loads.
2. Tests pass (run them, don't assume).
3. The specific change works as intended (observe behavior, don't infer).
4. No placeholders, no TODOs introduced, no commented-out code left behind.
5. No secrets or runtime artifacts introduced into version control.

## Cross-Machine Etiquette

- Leave work in a state the other agent can pick up without archaeology.
- If you create a dependency the other machine needs (new tool, new config, new secret), document it in the appropriate `TODO-*-CLAUDE.md`.
- Don't rewrite files the other machine is actively using without coordinating via TODO files.
