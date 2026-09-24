extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var frames: SpriteFrames = load("res://scenes/run_light_frames.tres")
	assert(frames != null)
	assert(frames.get_frame_count(&"run_light") == 18)
	assert(frames.get_animation_loop(&"run_light"))
	assert(is_equal_approx(frames.get_animation_speed(&"run_light"), 20.0))
	for i in 18:
		var imported: Image = frames.get_frame_texture(&"run_light", i).get_image()
		var path := "res://assets/character/run/light_jog_02/run_%02d.png" % (i + 1)
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
	assert(sprite.sprite_frames.get_frame_count(&"run_light") == 18)
	assert(sprite.sprite_frames.get_frame_count(&"run_bouncy") == 28)
	main.call("_begin_walk", 1, true)
	assert(sprite.animation == &"run_light")
	assert(not sprite.flip_h)
	main.call("_begin_walk", -1, true)
	assert(sprite.animation == &"run_light")
	assert(sprite.flip_h)
	main.call("_begin_walk", 1, false)
	assert(sprite.animation == &"walk")
	sprite.set_frame_and_progress(23, 0.5)
	main.call("_begin_walk", 1, true)
	assert(sprite.frame >= 0 and sprite.frame < 18)
	main.call("_stop_walking")
	assert(sprite.animation == &"idle_default")
	print("RUN_LIGHT_OK 18 frames, 20 fps, identical imported pixels, walk/run/idle transitions, left flip")
	quit(0)
