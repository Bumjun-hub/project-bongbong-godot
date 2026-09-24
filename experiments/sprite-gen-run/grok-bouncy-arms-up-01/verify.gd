extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Headless Godot defaults to a 64px window; movement uses the project's 640px view.
	root.size = Vector2i(640, 400)
	var frames: SpriteFrames = load("res://scenes/run_bouncy_frames.tres")
	assert(frames != null)
	assert(frames.get_frame_count(&"run_bouncy") == 28)
	assert(frames.get_animation_loop(&"run_bouncy"))
	assert(is_equal_approx(frames.get_animation_speed(&"run_bouncy"), 24.0))
	for i in 28:
		var imported: Image = frames.get_frame_texture(&"run_bouncy", i).get_image()
		var path := "res://assets/character/run/bouncy_arms_up_01/run_%02d.png" % (i + 1)
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert(imported.get_size() == Vector2i(192, 192))
		assert(source.get_size() == imported.get_size())
		for y in 192:
			for x in 192:
				assert(imported.get_pixel(x, y) == source.get_pixel(x, y))
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	assert(sprite.sprite_frames.get_frame_count(&"run_bouncy") == 28)
	assert(sprite.sprite_frames.get_frame_count(&"run_light") == 18)
	var key_6 := InputEventKey.new()
	key_6.keycode = KEY_6
	key_6.pressed = true
	main.call("_unhandled_key_input", key_6)
	assert(sprite.animation == &"run_bouncy")
	assert(not sprite.flip_h)
	assert(is_equal_approx(sprite.speed_scale, 1.25))
	assert(sprite.scale == Vector2.ONE)
	var run_x: float = main.get("_position_x")
	main._process(0.1)
	assert(is_equal_approx(float(main.get("_position_x")) - run_x, 13.5))
	main.call("_begin_walk", -1, true)
	assert(sprite.animation == &"run_bouncy")
	assert(sprite.flip_h)
	var key_5 := InputEventKey.new()
	key_5.keycode = KEY_5
	key_5.pressed = true
	main.call("_unhandled_key_input", key_5)
	assert(sprite.animation == &"run_light")
	assert(is_equal_approx(sprite.speed_scale, 1.25))
	assert(sprite.scale == Vector2.ONE)
	main.call("_stop_walking")
	assert(sprite.animation == &"idle_default")
	assert(is_equal_approx(sprite.speed_scale, 1.0))
	assert(sprite.scale == Vector2.ONE)
	var key_4 := InputEventKey.new()
	key_4.keycode = KEY_4
	key_4.pressed = true
	main.call("_unhandled_key_input", key_4)
	assert(sprite.animation == &"walk")
	assert(is_equal_approx(sprite.speed_scale, 1.25))
	var walk_x: float = main.get("_position_x")
	main._process(0.1)
	assert(is_equal_approx(absf(float(main.get("_position_x")) - walk_x), 9.0))
	print("RUN_BOUNCY_OK 28 frames, imported pixels, walk 90 px/s, runs 135 px/s, 1.25x playback, native scale, transitions")
	quit(0)
