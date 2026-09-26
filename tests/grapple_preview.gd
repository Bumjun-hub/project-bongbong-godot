extends SceneTree

func _initialize() -> void:
	call_deferred("render_preview")

func render_preview() -> void:
	var actors: Array=[]
	var sprites: Array=[]
	var labels: Array=[]
	for index in 2:
		var viewport:=SubViewport.new()
		viewport.size=Vector2i(450,640)
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var background:=ColorRect.new()
		background.color=Color("303845")
		background.size=Vector2(450,640)
		viewport.add_child(background)
		var main: Node2D=load("res://scenes/main.tscn").instantiate()
		main.platform_demo=true
		main.native_windows_enabled=false
		viewport.add_child(main)
		main.set_process(false)
		main._wander_enabled=false
		main._play_area_size=Vector2(450,640)
		main._floor_y=620
		main.get_node("Help").hide()
		var right:=index==1
		var bounds:=Rect2(35 if right else 240,170,175,160)
		main.set_window_platforms([{"id":"target","bounds":bounds,"surfaces":[bounds],
			"sides":[{"edge":"right" if right else "left","x":bounds.end.x if right else bounds.position.x,"span":Vector2(170,330)}]}])
		var sprite: AnimatedSprite2D=main.bongbong
		main._begin_drag(sprite.position)
		sprite.position=Vector2(365 if right else 85,620)
		main._end_drag()
		main._auto_walk=not right
		main._auto_run_bouncy=right
		main._set_facing(-1 if right else 1)
		actors.append(main)
		sprites.append(sprite)
		var panel:=TextureRect.new()
		panel.texture=viewport.get_texture()
		panel.position=Vector2(index*450,0)
		panel.size=Vector2(450,640)
		root.add_child(panel)
		var label:=Label.new()
		label.position=Vector2(index*450+12,14)
		labels.append(label)
		root.add_child(label)
	root.size=Vector2i(900,640)
	root.title="Bongbong grappling hook review"
	var folder:="res://.godot/grapple_preview"
	DirAccess.make_dir_recursive_absolute(folder)
	var notes: Array=[]
	for frame in 780:
		await process_frame
		for i in 2:
			actors[i]._process(1.0/60.0)
			var phase: String=str(actors[i]._grapple.state.get("phase",sprites[i].animation))
			labels[i].text=("Walk -> grapple" if i==0 else "Bouncy run -> grapple (left)")+"\n"+phase
		if frame%3==0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"/frame_%03d.png"%(frame/3))
			var states: Array=[]
			for i in 2:
				var grapple: Node2D=actors[i]._grapple
				states.append({"animation":sprites[i].animation,"frame":sprites[i].frame,"position":[sprites[i].position.x,sprites[i].position.y],
					"phase":str(grapple.state.get("phase","")),"rope_visible":grapple.rope_visible()})
			notes.append({"image":frame/3,"states":states})
	var f:=FileAccess.open(folder+"/frames.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(notes,"\t"))
	f.close()
	print("Rendered both grapple directions: %d captures at 20 fps"%notes.size())
	quit()
