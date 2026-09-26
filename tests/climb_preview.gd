extends SceneTree


func _initialize() -> void:
	call_deferred("render_preview")


func render_preview() -> void:
	var arguments := OS.get_cmdline_user_args()
	var scenario := arguments[1] if arguments.size() > 1 else "manual"
	var automatic := scenario.begins_with("auto")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(480, 400)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("303845")
	background.size = Vector2(480, 400)
	viewport.add_child(background)
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	main.platform_demo = true
	main.native_windows_enabled = false
	viewport.add_child(main)
	main.set_process(false)
	main._wander_enabled = false
	main._play_area_size = Vector2(480, 400)
	main._floor_y = 390
	main.get_node("Help").hide()
	root.size = Vector2i(480, 400)
	root.title = "봉봉이 오르기 미리보기 생성"
	var window := {"id": "preview", "bounds": Rect2(245, 150, 200, 230), "surfaces": [Rect2(245, 150, 200, 230)], "sides": [{"edge": "left", "x": 245.0, "span": Vector2(150, 380)}]}
	main.set_window_platforms([window])
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	main._begin_drag(sprite.position)
	sprite.position = Vector2(100, 390) if automatic else Vector2(208, 335)
	main._end_drag()
	if automatic:
		main._wander_enabled = true
		main._wander_time_left = 0.3
		main._rng.seed = 20260926
		main._set_facing(-1)
		if scenario in ["auto-run", "auto-bouncy"]:
			main._wander_enabled = false
			main._auto_run = scenario == "auto-run"
			main._auto_run_bouncy = scenario == "auto-bouncy"
			main._set_facing(1)
	var folder := arguments[0] if not arguments.is_empty() else "res://experiments/sprite-gen-climb/grok-climb-01/runtime_preview"
	DirAccess.make_dir_recursive_absolute(folder)
	var notes: Array = []
	var frame_count := int(arguments[2]) if arguments.size() > 2 else (1020 if automatic else 660)
	for frame in frame_count:
		await process_frame
		main._process(1.0 / 60.0)
		if frame % 4 == 0:
			await RenderingServer.frame_post_draw
			var index := frame / 4
			viewport.get_texture().get_image().save_png(folder + "/frame_%03d.png" % index)
			notes.append({"image": index, "animation": sprite.animation, "frame": sprite.frame, "speed_scale": sprite.speed_scale, "position": [sprite.position.x, sprite.position.y]})
	var file := FileAccess.open(folder + "/frames.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(notes, "\t"))
	file.close()
	print("Climb runtime preview saved: %d frames; final %s at %s" % [notes.size(), sprite.animation, sprite.position])
	quit()
