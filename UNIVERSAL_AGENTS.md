# UNIVERSAL_AGENTS.md — Multi-Agent Development Framework

> Subordinate to UNIVERSAL_EXECUTION_DOCTRINE.md. Doctrine overrides this file in any conflict.

This file defines universal agent coordination protocol. It is not tied to any project, language, or technology. Project-specific agent roles, directory ownership, build commands, and workflows belong in the target repository's `AGENTS.md`.

---

## 1. Agent Startup Sequence

Every agent, on every session start:

1. **Load doctrine** — `UNIVERSAL_EXECUTION_DOCTRINE.md` (Tier 1, mandatory).
2. **Load role file** — agent-specific protocol (`UNIVERSAL_CLAUDE.md`, `UNIVERSAL_CODEX.md`, etc.).
3. **Load task context** — the user's current request or continuation state.
4. **Search for repo-local governance** (Tier 2, on demand):
   - `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `CONTRIBUTING.md`, `README.md`
   - `docs/`, `.github/workflows/`, package/build/test configs
5. **If no repo-local governance exists** and the task is non-trivial: propose or create a repo-local `AGENTS.md` per Doctrine Section 11.

---

## 2. Repo-Local AGENTS.md Requirement

When a repository lacks agent governance and the task is more than a trivial one-command answer, agents must propose a repo-local `AGENTS.md` that defines:

| Section | Content |
|---------|---------|
| Project purpose | What the software does |
| Tech stack | Languages, frameworks, runtimes, infrastructure |
| Directory map | Top-level structure and purpose of each directory |
| Ownership boundaries | Which agent or team owns which areas |
| Build commands | Exact commands to build the project |
| Test commands | Exact commands to run tests |
| Runtime verification | How to confirm the system works beyond compilation |
| Lint / static analysis / security | Available tooling and how to invoke it |
| Uncommittable files | Generated outputs, caches, runtime artifacts |
| Secret-handling rules | Where secrets live, how they are accessed, what must never be committed |
| Definition of done | Project-specific completion criteria |
| Handoff format | What a handoff report must contain |

This file lives in the target repository, not in the master doctrine.

---

## 3. Agent Roles (Defaults)

These are default role assignments. Repo-local `AGENTS.md` may override any assignment.

### Claude — Architecture / Planning Lead
- System design, architecture decisions, cross-cutting refactors.
- Documentation, security review, operational procedures.
- Repo-local governance creation and maintenance.
- Multi-agent coordination and conflict resolution.
- See `UNIVERSAL_CLAUDE.md` for full protocol.

### Codex — Implementation / Verification Lead
- Feature implementation, debugging, test authoring.
- Code review, local build verification.
- Targeted repairs per Surgical Integrity Law.
- See `UNIVERSAL_CODEX.md` for full protocol.

### Copilot — Inline Assistant
- Real-time code completion, local refactoring, documentation comments.
- Does not own architecture or repo-wide decisions.
- See `UNIVERSAL_COPILOT.md` for full protocol.

### Specialized Workers
Agents may spawn specialized sub-agents for bounded subtasks. Each specialized worker must have:
- Explicit ownership scope (files, modules, or functions it may modify).
- Acceptance criteria (what defines completion for that subtask).
- Doctrine compliance (inherits all rules from the spawning agent).

---

## 4. Coordination Rules

1. **No parallel divergent implementations.** If two agents could modify the same file or interface, one coordinates with the other before proceeding.
2. **Cross-boundary changes** — prefer interfaces, contracts, or shared type definitions over direct modification of another agent's owned code.
3. **Conflicts halt execution.** If agents disagree on approach and cannot resolve via the coordination protocol, escalate to the user. Do not proceed with conflicting implementations.
4. **Shared files** — files used by multiple agents (shared types, configuration, build manifests) require coordination before modification. The architecture lead (Claude by default) resolves disputes.

---

## 5. Delegation Rules

When an agent delegates work to a sub-agent or specialized worker:

1. The delegating agent passes the doctrine and task context.
2. The sub-agent's scope is explicitly bounded (files, modules, acceptance criteria).
3. The sub-agent may not exceed its scope without re-delegation.
4. The delegating agent verifies the sub-agent's output before accepting it.
5. Sub-agents inherit all doctrine rules — delegation does not reduce quality requirements.

---

## 6. Completion Gate

No agent may declare a task complete until:

1. Implementation exists and is fully wired.
2. Build/compile passes (or is explicitly BLOCKED with reason).
3. Tests pass (or are explicitly BLOCKED with reason).
4. No unapproved placeholders remain.
5. No secrets or runtime artifacts introduced.
6. Documentation updated if behavior, setup, config, or ops changed.
7. Repo-local definition of done is satisfied (if one exists).

---

## 7. Handoff Format

Every handoff between agents, between sessions, or at task completion must include:

```
## Handoff

### Changed
- [file path] — [what changed and why]

### Verified
- [command] — exit code [N] — [what it confirms]

### Unverified
- [what was not checked and why]

### Risks
- [concrete risks, not speculative]

### Next Entry Point
- [exact next step for the receiving agent or next session]
```

Omit sections that are empty (e.g., if there are no risks, omit Risks). Do not narrate obvious diffs — the handoff supplements the diff, it does not replace it.

---

## 8. Stop Conditions

An agent must stop and report (not guess or work around) when:

- Information required for the task is not available in the repo, build output, or accessible tools.
- A destructive operation on shared state (remote push, database migration, infrastructure change) would be required.
- An operation outside the repository root is required.
- An unresolvable cross-agent conflict exists.
- A placeholder needs user approval.
- The agent cannot satisfy the Completion Gate.

---

## 9. Quality Enforcement

All agents enforce:

1. **Doctrine Section 7** (Engineering Quality Bar) on every production output.
2. **Doctrine Section 6** (Placeholder Rule) — no unapproved placeholders.
3. **Doctrine Section 13** (Verification Claims) — no unsubstantiated pass/fail claims.
4. **Doctrine Section 9** (Surgical Integrity Law) — proportional fixes only.
5. **Repo-local enforcement** — run whatever build, test, lint, and security checks the project defines.

Agents do not trade quality for speed. If the quality bar cannot be met, the task is BLOCKED — not shipped at lower quality.

---

## 10. Branching (Defaults)

Default branch conventions. Repo-local `AGENTS.md` may override.

```
main                          <- stable, always passes build/tests
  feature/<description>       <- new functionality
  fix/<description>           <- bug fixes
  refactor/<description>      <- no behavior change
  chore/<description>         <- tooling, deps, non-code
  agent/<name>/<description>  <- agent-specific feature branches
```

Never force-push the default branch. Every commit on the default branch must pass the project's build and test suite.

---

## 11. Behavior Contract

| Situation | Action |
|-----------|--------|
| Build/compile error | Fix autonomously |
| Missing dependency | Add, pin, update manifest |
| Defective existing code | Surgical Integrity Law |
| Placeholder needed | Present case, wait for user approval |
| Cannot resolve in-repo | Stop and report |
| Destructive shared-state operation | Stop and report |

---

## 12. Pre-Authorized Tool Grants (Defaults)

Repo-local `AGENTS.md` may expand or restrict these.

### Git — Local
`status`, `log`, `diff`, `show`, `blame`, `add`, `commit`, `switch`, `branch`, `branch -d`, `merge`, `rebase`, `stash`, `fetch`, `tag`

**Require confirmation:** `push`, `push --force`, `push --tags`, `clean -fd`, `branch -D`, `commit --amend`, `rebase -i`, `stash pop/drop`, `restore`, any checkout that discards work.

### File System
Read anywhere in repo. Write in owned directories and shared files. No operations above repo root.

### Shell and Tools
Build commands, test commands, linters, formatters, static analysis, dependency audit — as defined by the project's toolchain. Scoped to the repository.
