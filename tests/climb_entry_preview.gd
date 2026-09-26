extends SceneTree


func _initialize() -> void:
	call_deferred("render_preview")


func render_preview() -> void:
	var jump_preview := OS.get_cmdline_user_args().has("--jump")
	var actors: Array = []
	var sprites: Array = []
	var viewports: Array = []
	for index in 3:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(480, 400)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		viewports.append(viewport)
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
		var right := index == 2
		var bounds := Rect2(35 if right else 245, 150, 200, 160 if jump_preview else 230)
		main.set_window_platforms([{"id": "preview", "bounds": bounds, "surfaces": [bounds],
			"sides": [{"edge": "right" if right else "left", "x": bounds.end.x if right else bounds.position.x, "span": Vector2(150, bounds.end.y)}]}])
		var sprite: AnimatedSprite2D = main.get_node("Bongbong")
		main._begin_drag(sprite.position)
		sprite.position = Vector2(380 if right else 100, 390)
		main._end_drag()
		main._auto_walk = index == 0
		main._auto_run = index == 1
		main._auto_run_bouncy = index == 2
		main._set_facing(-1 if right else 1)
		actors.append(main)
		sprites.append(sprite)
		var panel := TextureRect.new()
		panel.texture = viewport.get_texture()
		panel.position = Vector2(index*480, 0)
		panel.size = Vector2(480, 400)
		root.add_child(panel)
		var label := Label.new()
		label.text = ["Walk -> reach -> climb", "Light run -> reach -> climb", "Bouncy run -> reach -> climb (left)"][index]
		if jump_preview:
			label.text = label.text.replace("reach", "hop + catch")
		label.position = Vector2(index*480+12, 14)
		root.add_child(label)
	root.size = Vector2i(1440, 400)
	root.title = "Bongbong small jump review" if jump_preview else "Bongbong climb entry review"
	var folder := "res://.godot/jump_climb_preview" if jump_preview else "res://.godot/climb_entry_preview"
	DirAccess.make_dir_recursive_absolute(folder)
	var notes: Array = []
	for frame in 240:
		await process_frame
		for main in actors:
			main._process(1.0/60.0)
		if frame % 2 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"/frame_%03d.png" % (frame/2))
			var states: Array = []
			for sprite in sprites:
				states.append({"animation": sprite.animation, "frame": sprite.frame,
					"position": [sprite.position.x,sprite.position.y], "speed_scale": sprite.speed_scale})
			notes.append({"image": frame/2, "states": states})
	var output := FileAccess.open(folder+"/frames.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(notes, "\t"))
	output.close()
	print("Rendered walk, light run and mirrored bouncy run entries: %d captures at 30 fps" % notes.size())
	quit()
