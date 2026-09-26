extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Platform demo rendering check requires a display")
		quit(1)
		return
	var scene: Node2D = load("res://scenes/platform_test.tscn").instantiate()
	root.add_child(scene)
	for step in 90:
		await process_frame
	var sprite: AnimatedSprite2D = scene.get_node("Bongbong")
	if root.size != Vector2i(960, 640) or root.borderless or root.always_on_top or root.transparent_bg:
		push_error("Platform demo did not open as a normal 960x640 window")
		quit(1)
		return
	if sprite.position.y != 350 or sprite.animation != &"idle_default":
		push_error("Platform demo did not land on its upper test window")
		quit(1)
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/platform_test")
	var screenshot := root.get_texture().get_image()
	var result := screenshot.save_png("res://.godot/platform_test/preview.png")
	if result != OK:
		push_error("Could not save platform demo preview")
		quit(1)
		return
	print("Platform demo passed: normal window, visible landing, preview saved to .godot/platform_test/preview.png")
	quit()
