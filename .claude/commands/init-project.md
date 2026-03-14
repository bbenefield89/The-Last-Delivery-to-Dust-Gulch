---
name: init-project
description: Initialize a new project from the template by filling in all placeholders interactively. Asks the user a structured set of questions, then replaces every [FILL IN: ...] block and [PROJ] placeholder across all template files.
---

# Init Project

Follow this workflow when invoked as `/init-project`.

## Purpose

Replace all placeholder content in the template files with real project-specific values. This command is run once, immediately after copying the template into a new project.

## Workflow

1. Scan the following files for `[FILL IN: ...]` blocks and `[PROJ]` occurrences:
   - `CLAUDE.md`
   - `AGENTS.md`
   - `.claude/commands/write-ticket.md`
   - `.agents/skills/merge-it/SKILL.md`
   - `.agents/skills/start-next-task/SKILL.md`

2. Ask the user the following questions **one group at a time**, waiting for answers before continuing:

   **Group 1 — Identity**
   - What is the project name?
   - What is the ticket prefix? (e.g. `WMFC`, `LDDG`, `ABC` — must be short and unique to this project)
   - Write one paragraph describing what this project is, what it does, and the goal of this repository.

   **Group 2 — Intent and Loop**
   - What is the intended experience or product intent? (For a game: describe the core loop step by step.)
   - What is the target scope or run length? (e.g. "10–15 minute prototype run", "single-level demo")

   **Group 3 — Priorities and Guardrails**
   - List 3–6 development priorities in order. (e.g. "Complete loop over polish", "Readability over feature count")
   - What systems ARE in scope for the current milestone?
   - What systems are NOT in scope unless explicitly requested?

   **Group 4 — References**
   - What is the path to the primary design document? (e.g. `Docs/GDD.md`)
   - Are there any other key reference files? (UI mockups, tone references, concept art paths — or "none")

   **Group 5 — Language and Engine** *(optional but recommended)*
   - What language and engine does this project use? (e.g. GDScript + Godot 4, C# + Unity, TypeScript + Phaser)
   - This is used to flag that the coding standards section in `AGENTS.md` may need updating.

3. Before making any changes, display a summary of all answers and ask the user to confirm.

4. On confirmation, apply all replacements:
   - Replace every `[PROJ]` occurrence with the chosen ticket prefix across all five files listed above.
   - Replace each `[FILL IN: ...]` block in `CLAUDE.md` and `AGENTS.md` with the appropriate answer. Remove the `[FILL IN: ...]` wrapper text entirely — replace the whole block with the real content.
   - If the language/engine is not GDScript + Godot, append a note in `AGENTS.md` under `## UI Direction` (or at the end of the file if that section is absent) reminding Codex to check the coding standards section and update it for the current stack.

5. Also update `CLAUDE.md` under `## Custom Commands` to add `/init-project` to the list:
   ```
   ### `/init-project`

   Fill in all project placeholders interactively. Run once after copying the template into a new project.
   ```

6. Report which files were changed and which placeholders were replaced.

## Required Outcome

- No `[FILL IN: ...]` blocks remain in any file.
- No `[PROJ]` occurrences remain in any file.
- All five files are updated consistently with the same ticket prefix.
- `CLAUDE.md` and `AGENTS.md` both contain the same project description, intent, priorities, guardrails, and references.
- The user confirmed the answers before any file was modified.
- A clear report lists every file touched and every placeholder replaced.
