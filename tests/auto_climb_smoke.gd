extends SceneTree

const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")
var main: Node2D
var sprite: AnimatedSprite2D
var failed := false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.native_windows_enabled = false
	root.add_child(main)
	main.set_process(false)
	sprite = main.get_node("Bongbong")
	main._rng.seed = 20260926
	# Random roaming notices a reachable side without any key or drag input.
	for right in [false, true]:
		reset(Vector2(530 if right else 100, 400))
		snapshot([window("target", Rect2(230, 180, 180, 220))])
		main._set_facing(1 if right else -1)
		main._wander_time_left = 0.0
		var started := false
		for frame in 200:
			var before := sprite.position
			await tick(1)
			check(absf(sprite.position.x - before.x) <= 1.5, "Walk-to-grab jumped horizontally")
			check(sprite.position.y == 400, "Approaching a side changed floor height")
			if not main._side_hold.is_empty():
				started = true
				break
		check(started and main._reaching_wall and sprite.animation == &"climb_entry", "Roaming did not begin the reach-to-grab transition")
		check(main._side_hold.get("edge") == ("right" if right else "left"), "Automatic grab chose the wrong side")
		check(sprite.flip_h == right, "Automatic hold faces away from the wall")
		var contact := sprite.position
		await tick(15)
		check(main._reaching_wall and not main._climbing and sprite.position == contact, "Climbed or slid before the hands finished reaching")
		var saw_climb := false
		var saw_pull := false
		for frame in 850:
			await tick(1)
			saw_climb = saw_climb or main._climbing
			saw_pull = saw_pull or main._pulling_up
			if main._side_hold.is_empty():
				break
		check(saw_climb and saw_pull and sprite.position.y == 180 and main._has_support(), "Autonomous climb did not finish on the top")
		check(sprite.animation == &"idle_default", "Climb did not finish with Idle")
		await tick(310)
		check(main._wander_moving and main._has_support() and not main._falling, "Roaming did not resume safely on the top")

	# Walking and both runs brake before contact, with the gait slowed by the
	# same ratio as translation. Bouncy run keeps its raised-arm pose.
	for motion in [&"walk", &"run_light", &"run_bouncy"]:
		for right in [false, true]:
			reset(Vector2(530 if right else 100, 400))
			snapshot([window("target", Rect2(230, 180, 180, 220))])
			main._wander_enabled = false
			main._auto_walk = motion == &"walk"
			main._auto_run = motion == &"run_light"
			main._auto_run_bouncy = motion == &"run_bouncy"
			main._set_facing(-1 if right else 1)
			var full_speed := 60.0 if motion == &"walk" else 135.0
			var saw_braking := false
			var finished_walking := false
			var previous_speed := full_speed
			for frame in 300:
				var before: float = main._position_x
				await tick(1)
				if not main._side_hold.is_empty():
					break
				var speed: float = absf(main._position_x - before) * 60.0
				saw_braking = saw_braking or speed < full_speed * 0.5
				var expected_gait := &"run_bouncy" if motion == &"run_bouncy" else &"walk"
				var final_step_limit := 65.0 if motion == &"run_bouncy" else 25.0
				finished_walking = sprite.animation == expected_gait and speed < final_step_limit
				if motion == &"run_bouncy":
					check(speed >= full_speed * 0.45 - 0.01, "Bouncy approach slowed to a crawl")
					check(previous_speed - speed < 3.0, "Bouncy braking dropped speed abruptly")
				previous_speed = speed
				var expected_scale := speed / (108.0 if sprite.animation != &"walk" else 60.0)
				check(absf(sprite.speed_scale - expected_scale) < 0.001, "Slowed gait does not match approach speed")
			check(saw_braking and finished_walking and not main._side_hold.is_empty(), "Approach did not brake and settle to a final step: %s" % motion)
			check(sprite.animation == (&"climb_bouncy_entry" if motion == &"run_bouncy" else &"climb_entry"), "Incorrect reach selected for " + String(motion))

	# Both runs sweep through contact, even when one frame crosses two windows.
	for bouncy in [false, true]:
		reset(Vector2(100, 400))
		snapshot([window("far", Rect2(420, 180, 100, 220)), window("near", Rect2(230, 180, 100, 220))])
		main._wander_enabled = false
		main._auto_run = not bouncy
		main._auto_run_bouncy = bouncy
		main._set_facing(1)
		main._process(3.0)
		check(main._side_hold.get("id") == "near" and absf(sprite.position.x - 198) <= 1, "Fast run skipped the first reachable side")

	# Inaccessible or covered routes must not attract the pet or start a climb.
	for kind in ["floating", "covered_side", "covered_top", "no_headroom", "outside_screen"]:
		reset(Vector2(100, 400))
		var entries := [window("target", Rect2(230, 180, 180, 220))]
		match kind:
			"floating":
				entries = [window("target", Rect2(230, 180, 180, 100))]
			"covered_side":
				entries.push_front(window("cover", Rect2(210, 270, 40, 30), false))
			"covered_top":
				entries.push_front(window("cover", Rect2(240, 170, 60, 25), false))
			"no_headroom":
				entries = [window("target", Rect2(230, 60, 180, 340))]
			"outside_screen":
				entries = [window("target", Rect2(45, 180, 20, 220))]
		snapshot(entries)
		check(main._find_climb_approach().is_empty(), "Selected an inaccessible route: " + kind)
		main._wander_enabled = false
		main._auto_walk = true
		main._set_facing(1)
		main._process(3.0)
		check(main._side_hold.is_empty(), "Started an inaccessible climb: " + kind)

	reset(Vector2(300, 400))
	snapshot([window("target", Rect2(230, 180, 180, 220))])
	check(main._find_climb_approach().is_empty(), "Selected a side through the window interior")
	reset(Vector2(170, 400))
	snapshot([window("target", Rect2(230, 180, 180, 220))])
	main._wander_enabled = false
	main._right_pressed = true
	main._process(0.6)
	check(main._side_hold.is_empty(), "Automatic climbing interrupted manual walking")
	reset(Vector2(170, 400))
	snapshot([window("target", Rect2(230, 180, 180, 220))])
	main.auto_climb_enabled = false
	main._auto_walk = true
	main._set_facing(1)
	main._process(0.6)
	check(main._side_hold.is_empty(), "Disabled auto climbing still grabbed a wall")
	main.auto_climb_enabled = true

	# The new reaching phase must share the side's live anchor and be fully
	# interruptible before the first upward climbing step.
	for interruption in ["drag", "space", "remove", "move"]:
		reset(Vector2(198, 400))
		snapshot([window("target", Rect2(230, 180, 180, 220))])
		main._wander_enabled = false
		main._auto_walk = true
		main._set_facing(1)
		await tick(3)
		check(main._reaching_wall, "Did not start reaching before interruption test")
		match interruption:
			"drag":
				main._begin_drag(sprite.position)
				check(main._dragging and not main._reaching_wall and main._side_hold.is_empty(), "Drag did not cancel reaching")
			"space":
				press(KEY_SPACE)
				check(main._falling and not main._reaching_wall and main._side_hold.is_empty(), "Space did not cancel reaching")
			"remove":
				main.set_window_platforms([])
				check(main._falling and not main._reaching_wall, "Removed window retained a reaching pose")
			"move":
				var before := sprite.position
				snapshot([window("target", Rect2(245, 170, 180, 220))])
				check(main._reaching_wall and sprite.position == before + Vector2(15, -10), "Reaching did not track the moving side")

	# A higher window is reachable while walking on a lower window, without
	# stepping beyond the supporting platform's safe edge.
	reset(Vector2(120, 320))
	snapshot([window("high", Rect2(240, 160, 180, 240)), window("base", Rect2(80, 320, 250, 80))])
	main._falling = false
	main._auto_walk = true
	main._wander_moving = true
	main._wander_time_left = 10.0
	main._set_facing(1)
	await tick(110)
	check(main._side_hold.get("id") == "high", "Did not climb from a lower window")
	press(KEY_SPACE)
	check(main._falling and main._side_hold.is_empty(), "Space did not release automatic climbing")
	await tick(420)
	check(main._side_hold.is_empty() and not main._wander_moving, "Paused pet reattached automatically")
	press(KEY_R)
	await tick(400)
	check(main._climbing or main._pulling_up, "Resuming roaming did not allow climbing again")
	main._begin_drag(sprite.position)
	check(main._dragging and main._side_hold.is_empty(), "Dragging did not interrupt automatic climbing")
	check(main._auto_climb_cooldown > 0.0 and main._find_climb_approach().is_empty(), "Detached pet can reattach immediately")

	if not failed:
		print("Auto climb passed: autonomous approach, both sides, floor contact, full top-out and roaming, both runs, swept nearest contact, occlusion/headroom/reach, manual control, higher window, pause/resume and drag")
	quit(1 if failed else 0)


func reset(position: Vector2) -> void:
	main._clear_side_motion()
	main._stop_walking()
	main._dragging = false
	main._falling = false
	main._landing = false
	main._auto_climb_cooldown = 0.0
	main._wander_enabled = true
	main._wander_time_left = 10.0
	sprite.position = position
	main._position_x = position.x
	main._fall_position_y = position.y
	main._begin_idle(&"idle_default")


func window(id: String, bounds: Rect2, platform: bool = true) -> Dictionary:
	return {"id": id, "x": bounds.position.x, "y": bounds.position.y, "width": bounds.size.x, "height": bounds.size.y, "platform": platform}


func snapshot(entries: Array) -> void:
	main.set_window_platforms(WindowsPlatforms.visible_platforms(entries, Vector2.ZERO, Vector2(640, 400), 140, 400, 60))


func tick(count: int) -> void:
	for frame in count:
		await process_frame
		main._process(1.0 / 60.0)


func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	main._unhandled_key_input(event)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
