# GDScript Standards

## File Order

Prefer this top-level order when sections exist:

1. tool or icon annotations
2. class_name
3. extends
4. class doc comment
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
- Use concise section comments when a section exists.
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
