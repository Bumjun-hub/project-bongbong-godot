extends SceneTree

const EXPECTED := [60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var frames: SpriteFrames = load("res://scenes/run_frames.tres")
	assert(frames != null)
	assert(frames.get_frame_count(&"run") == 8)
	assert(frames.get_animation_loop(&"run"))
	var durations: Array[float] = []
	var total := 0.0
	for i in 8:
		var texture := frames.get_frame_texture(&"run", i)
		assert(texture.get_size() == Vector2(192, 192))
		var ms: float = frames.get_frame_duration(&"run", i) / frames.get_animation_speed(&"run") * 1000.0
		assert(absf(ms - EXPECTED[i]) < 0.01)
		durations.append(ms)
		total += ms
		var imported: Image = texture.get_image()
		var source: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/character/run/right_three_quarter/run_%02d.png" % [i + 1]))
		assert(imported.get_size() == source.get_size())
		for y in 192:
			for x in 192:
				assert(imported.get_pixel(x, y) == source.get_pixel(x, y))
	assert(absf(total - 480.0) < 0.01)
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	assert(sprite.sprite_frames.get_frame_count(&"run") == 8)
	for i in 8:
		assert(sprite.sprite_frames.get_frame_texture(&"run", i) == frames.get_frame_texture(&"run", i))
	print("RUN_V8_OK ", JSON.stringify({"frame_count": 8, "durations_ms": durations, "total_ms": total}))
	quit(0)
