extends SceneTree

const APP_ROOT_SCENE := preload("res://Scenes/AppRoot/AppRoot.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var app_root = APP_ROOT_SCENE.instantiate()
	get_root().add_child(app_root)
	await process_frame

	var run_scene = app_root.get_node_or_null("RunScene")
	if app_root.run_state == null:
		push_error("Smoke test failed: AppRoot did not create a run state.")
		quit(1)
		return

	if run_scene == null:
		push_error("Smoke test failed: AppRoot did not add the run scene.")
		quit(1)
		return

	print("Smoke test passed: AppRoot bootstrapped the run scene.")
	quit(0)
