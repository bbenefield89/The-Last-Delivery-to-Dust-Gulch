# GDScript Standards

## File Order

All project-owned `.gd` files must follow this top-level order when the relevant sections exist:

1. tool or icon annotations
2. class_name
3. extends
4. top-level script doc comment
5. signals
6. enums
7. imports loaded with `preload(...)`
8. constants
9. static variables
10. exported fields
11. regular fields
12. onready fields
13. lifecycle methods
14. event handlers
15. remaining methods
16. inner classes

## Required Documentation

- Every project-owned `.gd` file must include a top-level `##` doc comment near the top of the file.
- Every project-owned method must include a `##` doc comment directly above the method definition.
- Add or update method doc comments when changing an existing method.

## Required Section Headers

- Every project-owned `.gd` file must use section comments for the sections that exist in that file.
- Use these labels when relevant: `# Signals`, `# Enums`, `# Imports`, `# Constants`, `# Static Variables`, `# Public Fields: Export`, `# Private Fields: Export`, `# Public Fields`, `# Private Fields`, `# Public Fields: OnReady`, `# Private Fields: OnReady`, `# Lifecycle Methods`, `# Event Handlers`, `# Public Static Methods`, `# Public Methods`, `# Protected Methods`, `# Private Methods`, and `# Inner Classes`.
- Do not omit section comments just because a file is small. If a section exists, mark it explicitly.
- Put event-handler methods in a dedicated `# Event Handlers` section immediately after `# Lifecycle Methods` when the file has any event handlers.

## Spacing

- Project-owned `.gd` files must use Godot/Python-style double-newline spacing between top-level sections.
- Leave a blank line between `extends` and the top-level script doc comment.
- Leave a blank line between the top-level script doc comment and the next section comment or code.
- Leave a blank line between each section comment and the code that follows it.
- Leave a blank line between top-level method definitions.
- Leave a blank line before each new section comment.

## class_name

- Use `class_name` only when you intentionally want a script globally accessible by name.
- Default to `preload(...)` for project-owned script references.
- Add `class_name` sparingly rather than as a default habit.

## Imports

- Treat preloaded dependencies as imports, not as general constants.
- Keep `preload(...)` references grouped in their own import section instead of mixing them into unrelated constants.

## General Rules

- Keep project-owned symbols typed.
- Use small focused methods and straightforward control flow.
- Treat missing required section comments, missing doc comments, and missing top-level spacing as standards violations.
- Prefer readable scene-and-script solutions over clever abstractions.
- Keep important gameplay state queryable from code.
- Add or update tests for meaningful gameplay or systems changes.

## Visibility

- public: no prefix
- protected: single leading underscore
- private: double leading underscore

Within `regular fields`, order members by visibility as:
- private
- protected
- public

Within `remaining methods`, order members by visibility as:
- public
- protected
- private

Do not rename Godot engine callbacks like `_ready()` or `_physics_process()` to fit the visibility rule.
