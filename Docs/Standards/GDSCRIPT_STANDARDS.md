# GDScript Standards

Shared Godot and GDScript implementation and review standards for this repository.

## GDScript Code Order

Organize top-level script contents in this order when present:

01. `@tool`, `@icon`, `@static_unload`
02. `class_name` when needed
03. `extends`
04. `##` class doc comment
05. `# Signals`
06. `# Enums`
07. `# Constants`
08. `# Static Variables`
09. `# Private Fields: Export`
10. `# Protected Fields: Export`
11. `# Public Fields: Export`
12. `# Private Fields`
13. `# Protected Fields`
14. `# Public Fields`
15. `# Private Fields: OnReady`
16. `# Protected Fields: OnReady`
17. `# Public Fields: OnReady`
18. `# Lifecycle Methods`
19. `# Public Static Methods`
20. `# Protected Static Methods`
21. `# Private Static Methods`
22. `# Public Methods`
23. `# Protected Methods`
24. `# Private Methods`
25. `# Inner Classes`

## Section Comments

Use an explicit section comment for sections 05 through 25 whenever that section exists.
Examples:
- `# Signals`
- `# Enums`
- `# Private Fields: Export`
- `# Lifecycle Methods`
- `# Public Methods`

Do not add empty section comments for sections that are not present.

## Class Names

Use `class_name` only when a script genuinely benefits from global registration or repeated direct cross-file
script-class access.

Do not add `class_name` by default.

Scene-owned scripts that are primarily loaded through `PackedScene` usually do not need `class_name` unless another
part of the codebase materially depends on that script class directly.

Constants-only modules are a valid exception. Prefer referring to shared constants files by `class_name` instead of
preloading the constants file into every consumer.

When a project-owned script is referenced without `class_name`, prefer a local named preload constant such as
`const RunStateType := preload("res://Systems/RunState/run_state.gd")`.

## Visibility Prefixes

Use visibility prefixes consistently for project-owned symbols when feasible:

- public: no prefix
- protected: single leading underscore, such as `_value`
- private: double leading underscore, such as `__value`

Exception:
Do not rename Godot engine callback methods to fit the visibility-prefix rule. Keep engine-required names such as
`_ready()`, `_process()`, `_physics_process()`, `_enter_tree()`, `_exit_tree()`, `_input()`, `_unhandled_input()`,
and similar built-in virtual methods exactly as Godot expects.

## Field Ordering

Fields come before methods.

Within field sections, order by visibility from most restrictive to least restrictive:

1. private
2. protected
3. public

Group fields by attribute type first:

- exported fields in `... Fields: Export`
- non-attribute fields in `... Fields`
- onready fields in `... Fields: OnReady`

Place field attributes on their own line above the field instead of keeping the attribute and field on the same line.
Example:

```gdscript
@export
var __my_export_field := 0
```

## Scene References And Injection

When a script depends on a scene, prefer injecting a `PackedScene` through an exported field and setting it in the
editor when practical.

Prefer this:

```gdscript
@export
var app_shell_scene: PackedScene
```

Instead of this:

```gdscript
@export_file("*.tscn")
var app_shell_scene_path: String = "res://shared/scenes/gdtrakka_app_shell/gdtrakka_app_shell.tscn"
```

Avoid hardcoded default scene path strings for project-owned scenes when an exported `PackedScene` reference would
work. Hardcoded paths are fragile when files move or are renamed.

Use string file-path exports only when the runtime genuinely needs a raw path string instead of a scene resource
reference.

When project-owned code genuinely needs reusable raw `res://` or `user://` path strings, centralize them in const
files under `res://Constants/` instead of repeating the literal path across multiple scripts.

## Spacing

Use one blank line between fields inside the same section.

Use two blank lines between sections.

Use two blank lines between methods, including lifecycle methods, static methods, regular methods, and inner-class
methods when they appear sequentially in the same file.

## Method Ordering

Methods come after fields.

Order methods like this:

1. lifecycle methods
2. static methods
3. remaining methods
4. inner classes

Within non-lifecycle method groups, order by visibility:

1. public
2. protected
3. private

## Lifecycle Methods

Place lifecycle methods before all other methods.

Order lifecycle methods by the order they occur for a newly created instance, not by partial reload behavior. Use the
natural first-instantiation flow, for example:

1. `_init()`
2. `_enter_tree()`
3. `_ready()`
4. `_process()`
5. `_physics_process()`
6. `_input()`, `_unhandled_input()`, and other built-in runtime callbacks as needed
7. `_exit_tree()`

If additional built-in virtual callbacks are overridden, place them in the position that best matches when they first
matter during the lifetime of a newly created instance.

## Line Length

Keep lines at 120 characters or fewer when feasible to reduce horizontal scrolling.

## Example Layout

```gdscript
class_name ExampleNode
extends Node

## Example doc comment.

# Signals

signal action_started


# Enums

enum Mode {
	IDLE,
	RUNNING,
}


# Constants

const DEFAULT_SPEED := 120.0


# Static Variables

static var __instance_count := 0


# Private Fields: Export

@export
var __debug_enabled := false


# Public Fields: Export

@export
var speed := DEFAULT_SPEED

@export
var splash_scene: PackedScene


# Private Fields

var __state := Mode.IDLE

var __previous_state := Mode.IDLE


# Protected Fields

var _target_position := Vector2.ZERO


# Public Fields

var display_name := "Runner"


# Private Fields: OnReady

@onready
var __sprite: Sprite2D = %Sprite


# Public Fields: OnReady

@onready
var label: Label = %Label


# Lifecycle Methods

func _init() -> void:
	__instance_count += 1


func _enter_tree() -> void:
	pass


func _ready() -> void:
	label.text = display_name


func _process(delta: float) -> void:
	pass


func _exit_tree() -> void:
	pass


# Public Static Methods

static func reset_instance_count() -> void:
	__instance_count = 0


# Public Methods

func start() -> void:
	__state = Mode.RUNNING
	action_started.emit()


# Protected Methods

func _move_to_target() -> void:
	pass


# Private Methods

func __sync_visuals() -> void:
	__sprite.visible = __debug_enabled


# Inner Classes

class Helper:
	extends RefCounted

	## Example inner helper.

	var value := 0
```
