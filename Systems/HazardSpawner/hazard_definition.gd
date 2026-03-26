extends Resource

## Stores authored hazard visuals and damage data for one spawnable hazard type.


# Public Fields: Export

@export
var hazard_type: StringName

@export
var damage := 0

@export
var cargo_damage := 0

@export
var texture: Texture2D

@export
var frame_regions: Array[Rect2i] = []

@export
var animation_fps := 0.0


# Public Methods

## Returns whether this hazard definition should animate through multiple sheet regions.
func uses_animation() -> bool:
	return frame_regions.size() > 1 and texture != null
