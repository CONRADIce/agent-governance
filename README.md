# Agent Governance Framework

A production governance framework for coordinating multiple AI coding agents with strict correctness guarantees.

## What This Is

This is the governance system I use daily to coordinate Claude, Codex, and Copilot across multiple repositories and two machines (Windows and Linux). Every AI agent session loads these documents before touching code.

The framework enforces:

- **Execution modes** with explicit transitions between exploration and production
- **Placeholder prohibition** with user-approval gates and a tracking registry
- **Structured verification** — no claiming "tests pass" without command, exit code, and output
- **Multi-agent coordination** — role assignments, delegation rules, conflict resolution, handoff format
- **Quality enforcement** — structural validators, build integrity gates, secret scans

## Why It Exists

AI coding agents are powerful but undisciplined by default. They claim work is complete when it isn't, insert placeholders and forget about them, make verification claims without running anything, produce cosmetic success instead of real results, and drift from task scope.

This framework treats those failure modes as engineering problems with engineering solutions: explicit modes, registries, validators, gates, and structured handoffs.

## How It Works

### Startup Sequence

Every agent, every session:

1. Load `UNIVERSAL_EXECUTION_DOCTRINE.md` (mandatory, highest authority)
2. Load role-specific protocol (`UNIVERSAL_CLAUDE.md`, `UNIVERSAL_CODEX.md`, or `UNIVERSAL_COPILOT.md`)
3. Load task context
4. Search the target repository for local governance (`AGENTS.md`, etc.)
5. If none exists and the task is non-trivial, propose repo-local governance

### Document Hierarchy

```
UNIVERSAL_EXECUTION_DOCTRINE.md          <- Rules (what agents must do)
 |
 +-- UNIVERSAL_AGENTS.md                 <- Coordination (how agents work together)
 |    +-- UNIVERSAL_CLAUDE.md            <- Architecture / planning lead protocol
 |    +-- UNIVERSAL_CODEX.md             <- Implementation / testing lead protocol
 |    +-- UNIVERSAL_COPILOT.md           <- Inline assistant protocol
 |
 +-- UNIVERSAL_AAA_CONTINUATION_PROMPT.md  <- Sustained execution loop
 +-- DEV-PREFERENCES.md                    <- Shared engineering standards
```

### Enforcement

The `enforcement/` directory contains reference validators:

- **PLACEHOLDER_REGISTRY.md** — Tracks all user-approved placeholders across a project
- **Invoke-StructuralValidator.ps1** — Scans source code for empty functions, stub implementations, unregistered placeholders, TODO/FIXME/HACK comments, and exploration tags
- **Invoke-BuildIntegrityGate.ps1** — Full enforcement gate: compile validation + structural scan + placeholder audit

These reference implementations target C++ / Unreal Engine projects. The framework expects each project to create equivalent validators for its own stack.

### Universal vs. Repo-Local Split

Universal documents (this repository) define behavior, quality, and coordination standards that apply to every project regardless of technology.

Repo-local documents (`AGENTS.md`, `CLAUDE.md`, etc. inside each target repository) define project-specific details: tech stack, directory map, build commands, ownership boundaries, and definition of done.

Universal files never contain project-specific paths, module names, build commands, or technology choices. If a project needs specific rules, those rules live in the project's repository.

## Key Concepts

### Execution Modes

- **Production Mode** (default): Ship-quality output. Zero unapproved placeholders, fully wired to real dependencies, verified by execution — not just compilation.
- **Exploration Mode**: Discovery and prototyping. Must be explicitly tagged with `EXPLORATION:` prefix, with stated goals and exit criteria. Nothing moves to Production without meeting transition criteria: all dependencies real, architecture stable, no temporary elements, all exploration tags resolved.

### Placeholder Rule

Placeholders are prohibited by default. A placeholder may exist only if all of:

1. Explicitly declared (tagged, not hidden)
2. Includes reason, scope, and replacement plan
3. Approved by the user (an agent cannot approve its own placeholders)
4. Tracked in the Placeholder Registry

An unapproved placeholder is a violation. A hidden placeholder is an execution failure.

### Surgical Integrity Law

Response is proportional to the defect:

| Condition | Action |
|-----------|--------|
| Structurally unsound (boundary-level) | Replace the affected boundary |
| Locally flawed | Targeted repair |
| Unknown scope | Isolate and measure before deciding |

Never rewrite working code for style alone. No scope creep beyond the defect boundary.

### Verification Claims

Never claim checks passed without running them. Every verification report includes:

- Exact command executed
- Numeric exit code
- Relevant output summary
- What the check verifies
- What the check does not verify

### Handoff Format

Every task completion or session end includes:

- Changed files with reasons
- Verification commands with exit codes
- Unverified items with reasons
- Concrete risks (not speculative)
- Exact next entry point for the receiving agent or next session

### Completion Gate

No agent may declare a task complete until:

1. Implementation exists and is fully wired
2. Build/compile passes (or is explicitly `BLOCKED` with reason)
3. Tests pass (or explicitly `BLOCKED`)
4. No unapproved placeholders remain
5. No secrets or runtime artifacts introduced
6. Documentation updated if behavior changed
7. Handoff delivered

## File Reference

| File | Purpose |
|------|---------|
| `UNIVERSAL_EXECUTION_DOCTRINE.md` | Highest-authority rules: quality bar, execution modes, placeholders, verification, enforcement, completion criteria |
| `UNIVERSAL_AGENTS.md` | Multi-agent coordination: roles, delegation, conflict resolution, handoff format, completion gate |
| `UNIVERSAL_CLAUDE.md` | Claude protocol: architecture/planning lead, governance responsibility, architecture standards |
| `UNIVERSAL_CODEX.md` | Codex protocol: implementation/testing lead, review rules, completion reports |
| `UNIVERSAL_COPILOT.md` | Copilot protocol: inline assistant, allowed/prohibited work, insufficient-context handling |
| `UNIVERSAL_AAA_CONTINUATION_PROMPT.md` | Sustained production execution: operating loop, quality criteria, exploration/production rules |
| `DEV-PREFERENCES.md` | Shared developer preferences: communication, code style, git workflow, verification standards |
| `enforcement/PLACEHOLDER_REGISTRY.md` | Template for tracking user-approved placeholders |
| `enforcement/Invoke-StructuralValidator.ps1` | Reference structural validator (C++/UE5 — adapt for your stack) |
| `enforcement/Invoke-BuildIntegrityGate.ps1` | Reference build integrity gate (C++/UE5 — adapt for your stack) |

## Using This in Your Own Projects

1. Clone this repo or copy the documents into your workflow
2. Point your AI agent's system prompt at `UNIVERSAL_EXECUTION_DOCTRINE.md` as mandatory first-load context
3. Load the role-specific protocol matching your agent (Claude, Codex, or Copilot — or write your own)
4. Create a repo-local `AGENTS.md` in each project using the template in `UNIVERSAL_AGENTS.md` Section 2
5. Build enforcement validators appropriate to your tech stack
6. Run them before declaring work complete

## License

MIT
