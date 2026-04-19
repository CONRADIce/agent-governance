# Placeholder Registry

Master tracking file for all user-approved placeholders across the project.
Referenced by Doctrine Section 4 and Section 12.

## Format

Each approved placeholder is a row in the table below. Agents add entries when the user approves a placeholder. Agents remove entries when the placeholder is replaced with a real implementation.

## Active Placeholders

| ID | File Path | Description | Reason | Replacement Plan | Approved By | Approved Date | Expiration Condition |
|----|-----------|-------------|--------|-----------------|-------------|---------------|---------------------|
| — | — | No active placeholders | — | — | — | — | — |

## Resolved Placeholders (History)

| ID | File Path | Description | Resolved Date | Resolution |
|----|-----------|-------------|---------------|------------|
| — | — | No resolved placeholders yet | — | — |

## Rules

1. Only the user can approve new entries. Agents propose, user decides.
2. Each placeholder gets a unique sequential ID (PH-001, PH-002, etc.).
3. Expired placeholders (expiration condition met but not resolved) are violations.
4. Agents must check this registry before declaring work complete.
5. The Structural Validator script reads this file to audit compliance.
