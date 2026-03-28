extends Node2D

## Owns one spawned hazard's visual and authored collision shape.


# Constants
const HazardDefinitionType := preload(ProjectPaths.HAZARD_DEFINITION_SCRIPT_PATH)


# Private Fields

var _definition: HazardDefinitionType


# Private Fields: OnReady

@onready
var _visual: AnimatedSprite2D = %Visual

@onready
var _collision_shape: CollisionShape2D = %CollisionShape


# Lifecycle Methods

## Applies any cached definition once the scene-owned child references are ready.
func _ready() -> void:
	_apply_definition_if_ready()


# Public Methods

## Applies one authored hazard definition to the shared hazard scene instance.
func apply_definition(definition: HazardDefinitionType) -> void:
	_definition = definition
	_apply_definition_if_ready()


## Returns the animated visual node that presents this hazard.
func get_visual() -> AnimatedSprite2D:
	return _visual


## Returns the current authored collision rect in global space.
func get_collision_rect() -> Rect2:
	var collision_size := Vector2.ZERO
	if _collision_shape != null:
		var rectangle_shape := _collision_shape.shape as RectangleShape2D
		collision_size = Vector2.ZERO if rectangle_shape == null else rectangle_shape.size
	var collision_shape_position := global_position if _collision_shape == null else _collision_shape.global_position
	return Rect2(collision_shape_position - (collision_size * 0.5), collision_size)

# Private Methods

## Applies the cached hazard definition once both scene-owned child references are initialized.
func _apply_definition_if_ready() -> void:
	if _definition == null or _visual == null or _collision_shape == null:
		return

	_apply_visual_definition()

## Applies the authored sprite frames and playback state to the shared hazard visual.
func _apply_visual_definition() -> void:
	var visual := get_visual()
	visual.sprite_frames = _build_sprite_frames()
	visual.animation = &"default"
	visual.frame = 0
	visual.speed_scale = 1.0
	visual.play()


## Builds runtime sprite frames from either a static texture or authored animation regions.
func _build_sprite_frames() -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.set_animation_loop(&"default", true)
	sprite_frames.set_animation_speed(
		&"default",
		1.0 if _definition == null or _definition.animation_fps <= 0.0 else _definition.animation_fps
	)

	if _definition == null or _definition.texture == null:
		return sprite_frames

	if _definition.uses_animation():
		for frame_region in _definition.frame_regions:
			sprite_frames.add_frame(&"default", _make_sheet_frame(frame_region))
		return sprite_frames

	sprite_frames.add_frame(&"default", _definition.texture)
	return sprite_frames


## Creates one atlas-backed frame from the authored hazard sheet region.
func _make_sheet_frame(region: Rect2i) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = _definition.texture
	atlas_texture.region = region
	return atlas_texture
