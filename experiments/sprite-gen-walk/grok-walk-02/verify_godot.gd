extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var frames: SpriteFrames = load("res://scenes/walk_frames.tres")
	assert(frames.get_frame_count(&"walk") == 24)
	assert(frames.get_animation_speed(&"walk") == 24.0)
	assert(frames.get_animation_loop(&"walk"))
	var top_min := 192
	var top_max := 0
	for i in 24:
		assert(frames.get_frame_duration(&"walk", i) == 1.0)
		var imported: Image = frames.get_frame_texture(&"walk", i).get_image()
		var original := Image.load_from_file(ProjectSettings.globalize_path("res://assets/character/walk/grok_right_calm/walk_%02d.png" % (i+1)))
		assert(imported.get_size() == Vector2i(192, 192))
		assert(imported.get_data() == original.get_data())
		var top: int = original.get_used_rect().position.y
		top_min = mini(top_min, top)
		top_max = maxi(top_max, top)
	assert(top_max - top_min >= 3)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	assert(sprite.sprite_frames.get_frame_count(&"walk") == 24)
	main.call("_begin_walk", 1)
	assert(sprite.animation == &"walk" and not sprite.flip_h)
	main.call("_begin_walk", -1)
	assert(sprite.animation == &"walk" and sprite.flip_h)
	main.call("_stop_walking")
	assert(sprite.animation == &"idle_default")
	print("WALK_WHOLE_BODY_OK: 24 frames, 1 second, final asset pixels, moving head and body, both directions, idle transition")
	quit()
