extends SceneTree

const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")
var pet: Node2D
var sprite: AnimatedSprite2D
var failed := false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	pet = load("res://scenes/main.tscn").instantiate()
	pet.native_windows_enabled = false
	root.add_child(pet)
	pet.set_process(false)
	pet._wander_enabled = false
	sprite = pet.bongbong
	check(sprite.sprite_frames.get_frame_count(&"lower_over_edge") == pet.DescentMotion.ROOT_OFFSETS.size(), "Lowering contact track is incomplete")
	check(sprite.sprite_frames.get_animation_loop(&"climb_down"), "Descending wall animation does not repeat")
	check(sprite.sprite_frames.get_frame_count(&"climb_down") >= 24, "Sliding hair animation is missing")
	check(sprite.sprite_frames.get_frame_texture(&"climb_down", 0) == sprite.sprite_frames.get_frame_texture(&"lower_over_edge", 96), "Sliding changed the last lowering pose")
	for right in [false, true]:
		reset(right)
		var start := sprite.position
		check(pet._descent.request(), "Could not request descent from a window top")
		await until_phase("lower", 200)
		check(pet._descent.active() and sprite.animation == &"lower_over_edge", "Approach did not start the lowering animation")
		check(sprite.flip_h == right, "Lowering faces the wrong ledge")
		var before := sprite.position
		snapshot(Rect2(210, 190, 250, 190))
		check(sprite.position == before + Vector2(10, 10), "Lowering did not follow a moving corner")
		await until_phase("down", 400)
		check(pet._descent.active() and sprite.animation == &"climb_down", "Lowering did not connect to the descending loop")
		check(float(pet._descent.state["velocity"]) < pet.DescentController.SPEED, "Sliding starts abruptly at full speed")
		before = sprite.position
		await tick(35)
		check(sprite.position.y > before.y and sprite.position.x == before.x, "Wall descent did not move down steadily")
		check(is_equal_approx(float(pet._descent.state["velocity"]), pet.DescentController.SPEED), "Sliding did not reach its steady speed")
		check(not pet._descent.dust.is_empty(), "Sliding feet did not emit dust")
		var wall_x := 460.0 if right else 210.0
		for puff in pet._descent.dust:
			check((Vector2(puff["position"]).x - wall_x) * (-1 if right else 1) < 0, "Dust appeared inside the window instead of beside the shoes")
			check(is_equal_approx(Vector2(puff["origin"]).x, wall_x), "Dust did not originate at the shoe-wall contact")
			check(Vector2(puff["position"]).y < Vector2(puff["origin"]).y, "Friction dust did not rise above the contacting foot")
		for frame in 800:
			await tick(1)
			if not pet._descent.active():
				break
		check(not pet._descent.active() and sprite.position.y == 400 and not pet._falling and sprite.animation == &"idle_default", "Descent did not put its feet on the desktop")
		check(sprite.position.x != start.x, "Descent never crossed the window corner")
		await tick(25)
		check(pet._descent.dust.is_empty(), "Sliding dust remained after stopping")

	# A floating window ends in the existing falling and landing sequence.
	reset(false, Rect2(200, 180, 250, 110))
	pet._descent.request()
	await until_phase("down", 400)
	for frame in 400:
		await tick(1)
		if pet._falling:
			break
	check(pet._falling and not pet._descent.active() and pet._fall_velocity >= 0, "Bottom of a floating wall did not release into FALL")
	await tick(220)
	check(not pet._falling and not pet._landing and sprite.animation == &"idle_default", "Released descent did not complete LAND")

	for phase in ["approach", "lower", "down"]:
		for interruption in ["remove", "drag", "space"]:
			reset(false)
			pet._descent.request()
			if phase != "approach":
				await until_phase(phase, 500)
			var before := sprite.position
			match interruption:
				"remove": pet.set_window_platforms([])
				"drag": pet._begin_drag(sprite.position)
				"space":
					var event := InputEventKey.new()
					event.pressed = true
					event.keycode = KEY_SPACE
					pet._unhandled_key_input(event)
			check(not pet._descent.active(), "Interruption did not stop descent")
			check(pet._descent.dust.is_empty(), "Interrupted descent left dust behind")
			check(sprite.position == before, "Cancellation teleported the pet")
			check(pet._dragging if interruption == "drag" else (pet._falling if phase != "approach" or interruption == "remove" else not pet._falling), "Cancellation left the pet in the wrong state")

	# No descent into a covered corner or from the desktop floor.
	reset(false)
	snapshot(Rect2(200, 180, 250, 200), true)
	check(pet._descent.target_for(-1).is_empty(), "Covered corner is still a descent target")
	pet._begin_drag(sprite.position)
	sprite.position = Vector2(120, 400)
	pet._end_drag()
	check(not pet._descent.request(), "Desktop floor allowed a window-top descent")

	# Automatic movement uses the new corner action on either side, for each gait.
	for right in [false, true]:
		for gait in [0, 1, 2]:
			reset(right)
			pet._auto_walk = gait == 0
			pet._auto_run = gait == 1
			pet._auto_run_bouncy = gait == 2
			pet._set_facing(1 if right else -1)
			await until_phase("lower", 200)
			check(pet._descent.active() and sprite.animation == &"lower_over_edge", "Automatic gait did not descend at the corner")
	if not failed:
		print("Descent passed: both corners, two-hand lowering, repeating down motion, moving windows, desktop feet, floating-wall FALL/LAND, all cancellations, covered/floor rejection and six automatic gait cases")
	quit(1 if failed else 0)


func reset(right: bool, bounds: Rect2 = Rect2(200, 180, 250, 200)) -> void:
	pet._clear_side_motion()
	pet._stop_walking()
	pet._dragging = false
	pet._falling = false
	pet._landing = false
	pet._greeting = false
	pet._auto_climb_cooldown = 0
	snapshot(bounds)
	sprite.position = Vector2(bounds.end.x - 85 if right else bounds.position.x + 85, bounds.position.y)
	pet._falling = false
	pet._landing = false
	pet._position_x = sprite.position.x
	pet._fall_position_y = sprite.position.y
	pet._set_facing(1 if right else -1)
	pet._begin_idle(&"idle_default")


func snapshot(bounds: Rect2, cover: bool = false) -> void:
	var windows: Array = []
	if cover:
		windows.append({"id":"cover","x":180,"y":150,"width":70,"height":100,"platform":true})
	windows.append({"id":"support","x":bounds.position.x,"y":bounds.position.y,"width":bounds.size.x,"height":bounds.size.y,"platform":true})
	pet.set_window_platforms(WindowsPlatforms.visible_platforms(windows,Vector2.ZERO,Vector2(640,400),140,400,60))


func until_phase(phase: String, limit: int) -> void:
	for frame in limit:
		if pet._descent.active() and pet._descent.state["phase"] == phase:
			return
		await tick(1)


func tick(count: int) -> void:
	for frame in count:
		await process_frame
		pet._process(1.0/60.0)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
