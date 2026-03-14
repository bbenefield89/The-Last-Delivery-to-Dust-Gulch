---
name: implement-plan
description: Implement the latest already-discussed plan for this repository without re-planning it. Use this skill when the user explicitly asks to "implement the plan", "implement-plan", or otherwise says to execute a plan that was already agreed in the current conversation.
---

# Implement Plan

Follow this workflow for this repository when the user explicitly asks to implement an already-discussed plan.

## Workflow

1. Identify the plan to execute before making changes.
   - Prefer the latest `<proposed_plan>` in the current conversation.
   - If there is no `<proposed_plan>`, use the latest clearly agreed implementation plan from the conversation.
   - If no concrete plan exists, stop and report that there is no plan to implement yet.
2. Treat the plan as authoritative.
   - Do not re-plan the work unless the plan is internally inconsistent or the repo state has drifted enough to block implementation.
   - Preserve user choices made during the planning conversation.
3. Ground in the current repo state before editing.
   - Inspect the relevant files, current branch, worktree state, and any ticket context the plan depends on.
   - If the plan was tied to an active kanban step or skill workflow, honor that workflow rather than bypassing it.
4. Implement the plan end-to-end.
   - Make the required code, test, scene, data, and documentation changes directly.
   - Keep changes focused on the agreed plan.
   - Add or update automated tests for all new public-facing behavior.
5. Run verification after implementation when feasible.
   - Use the repo verification order from `AGENTS.md` unless the plan or changed scope requires something narrower or broader.
6. Perform a self-review before reporting completion.
   - Review the changed code with explicit focus on:
     - SOLID principles
     - self-documenting names for classes, methods, and variables
     - `##` doc comments on all added or changed methods
     - top-level doc comments on all added classes
     - removal of public fields or methods that are only used by tests
     - if a new public field or method is only used by tests for now but is intentionally meant for real near-future use, ensure it has a short comment saying so
     - thorough automated test coverage for all new public-facing code
   - If the review finds issues that are feasible to fix within the current task, fix them before reporting back.
7. Report the implementation only after code, verification, and self-review are complete.
   - Summarize what changed.
   - Report verification results and any remaining known failures or risks.
   - Include a focused `Manual Verification` section with ordered human test steps for only the changes from this implementation pass.

## Repo Notes

- Follow `AGENTS.md` and keep repo-specific coding and verification rules intact.
- Do not widen public API purely to satisfy tests.
- Test private and protected behavior through meaningful public behavior rather than exposing internals.
- If the repo already has a skill-driven workflow for the task, use that workflow rather than competing with it.

## Required Outcome

- The latest agreed plan is implemented without unnecessary re-planning.
- The implementation includes meaningful automated verification for new public-facing behavior.
- A self-review pass is completed before the final report.
- Public API added only for tests is removed or explicitly documented as near-future runtime API.
- The final report includes verification results and a focused `Manual Verification` section.
