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
	for right in [false, true]:
		for gait in [&"walk", &"run_light", &"run_bouncy"]:
			reset(Vector2(530 if right else 100, 400), right, gait)
			snapshot([window(Rect2(230,180,180,140))])
			for frame in 300:
				var before := sprite.position
				await tick(1)
				check(absf(sprite.position.x-before.x) <= 3.0, "Run-up warped to the takeoff point")
				if not main._climb_jump.is_empty():
					break
			check(not main._climb_jump.is_empty() and sprite.position.y == 400, "Floating window did not start a supported jump")
			check(sprite.animation == (&"climb_jump_bouncy" if gait == &"run_bouncy" else &"climb_jump"), "Jump did not use its dedicated crouch motion")
			var planted := sprite.position
			await tick(10)
			check(sprite.position == planted and not main._climb_jump.get("airborne", true), "Feet left the floor before the preparation squat finished")
			check(sprite.frame > 0 and sprite.frame < int(main._climb_jump["takeoff_frame"]), "Squat poses did not advance before takeoff")
			var highest := sprite.position.y
			for frame in 80:
				var before := sprite.position
				await tick(1)
				highest = minf(highest, sprite.position.y)
				check(absf(sprite.position.y-before.y) <= 7.0, "Jump teleported vertically")
				check(not main._falling, "Supported jump fell before hand contact")
				if not main._side_hold.is_empty():
					break
			check(main._climb_jump.is_empty() and main._side_hold.get("id") == "target", "Jump missed its exposed side")
			check(highest < 350 and highest >= 331, "Hop height exceeded its small arc or did not leave the floor")
			var hand := sprite.position + Vector2(44.0*(-1 if right else 1), -62.0)*0.72
			check(absf(hand.x-(410.0 if right else 230.0)) < 0.6, "Jump catch did not line up with the wall")
			check(sprite.flip_h == right, "Jump faces away from its wall")
			await tick(6)
			check(main._climbing and sprite.animation == &"climb", "Jump did not continue into the existing climb")
			if gait == &"walk":
				for frame in 700:
					await tick(1)
					if main._side_hold.is_empty():
						break
				check(sprite.position.y == 180 and main._has_support() and not main._falling, "Jump/climb/top-out did not finish supported: position=%s animation=%s hold=%s falling=%s" % [sprite.position, sprite.animation, main._side_hold, main._falling])

	# The same reach calculation works from another window, not just the floor.
	reset(Vector2(120,320), false, &"walk")
	snapshot([window(Rect2(260,160,180,90)), window(Rect2(80,320,200,80), "base")])
	for frame in 250:
		await tick(1)
		if not main._side_hold.is_empty():
			break
	check(main._side_hold.get("id") == "target" and not main._falling, "Could not hop from a supporting window to a higher side")

	# Exact height boundary, too high, covered side and manual control.
	reset(Vector2(100,400), false, &"walk")
	snapshot([window(Rect2(230,180,180,129.44))])
	check(not main._find_climb_approach(1).is_empty(), "Maximum reachable jump was rejected")
	snapshot([window(Rect2(230,180,180,128.0))])
	check(main._find_climb_approach(1).is_empty(), "Selected a window above the jump limit")
	snapshot([window(Rect2(210,250,40,40), "cover", false), window(Rect2(230,180,180,140))])
	check(main._find_climb_approach(1).is_empty(), "Jumped to an occluded climbing route")
	snapshot([window(Rect2(230,180,180,140))])
	main._auto_walk = false
	main._right_pressed = true
	main._process(1.5)
	check(main._climb_jump.is_empty() and main._side_hold.is_empty(), "Manual movement unexpectedly started a jump")

	for interruption in ["remove", "move", "resize", "cover", "route_cover", "space", "drag"]:
		reset(Vector2(174,400), false, &"walk")
		snapshot([window(Rect2(230,180,180,140))])
		await tick(25)
		check(not main._climb_jump.is_empty(), "No active jump for interruption")
		var before := sprite.position
		match interruption:
			"remove":
				main.set_window_platforms([])
			"move":
				snapshot([window(Rect2(270,160,180,140))])
			"resize":
				snapshot([window(Rect2(230,180,180,100))])
			"cover":
				snapshot([window(Rect2(210,270,40,70), "cover", false), window(Rect2(230,180,180,140))])
			"route_cover":
				snapshot([window(Rect2(210,230,40,30), "cover", false), window(Rect2(230,180,180,140))])
			"space":
				var key := InputEventKey.new()
				key.keycode = KEY_SPACE
				key.pressed = true
				main._unhandled_key_input(key)
			"drag":
				main._begin_drag(sprite.position)
		check(main._climb_jump.is_empty() and main._side_hold.is_empty(), "Interrupted jump kept its target")
		check(sprite.position == before, "Interrupted jump warped the character")
		if interruption == "drag":
			check(main._dragging, "Could not drag during a jump")
		else:
			check(main._falling and main._fall_velocity < 0.0, "Missed grab discarded its upward momentum")
			await tick(1)
			check(sprite.position.y < before.y, "Missed jump instantly stopped rising")
			for frame in 100:
				await tick(1)
				if main._landing:
					break
			check(main._landing and sprite.position.y == 400, "Missed jump did not return to LAND")

	# Cancelling a grounded squat must not create upward velocity or a fall.
	for interruption in ["remove", "move", "space", "drag"]:
		reset(Vector2(174,400), false, &"walk")
		snapshot([window(Rect2(230,180,180,140))])
		await tick(5)
		var planted := sprite.position
		check(not main._climb_jump.is_empty() and not main._climb_jump["airborne"], "No grounded preparation to interrupt")
		match interruption:
			"remove": main.set_window_platforms([])
			"move": snapshot([window(Rect2(270,160,180,140))])
			"space":
				var key := InputEventKey.new()
				key.keycode = KEY_SPACE
				key.pressed = true
				main._unhandled_key_input(key)
			"drag": main._begin_drag(sprite.position)
		check(main._climb_jump.is_empty() and sprite.position == planted and not main._falling, "Grounded cancellation launched or displaced the pet")
		check(sprite.animation == (&"drag" if interruption == "drag" else &"idle_default"), "Grounded cancellation kept the squat pose")

	# A late render frame still ends at the intended hand contact.
	reset(Vector2(174,400), false, &"run_bouncy")
	snapshot([window(Rect2(230,180,180,140))])
	main._process(0.02)
	main._process(2.0)
	check(main._side_hold.get("id") == "target" and main._climb_jump.is_empty(), "Long frame overshot the jump catch")
	if not failed:
		print("Jump climb passed: both sides, walk/two runs, small arc, full top-out, elevated launch, reach boundary, occlusion, manual control, moving/removed/resized targets, drag/Space, preserved fall momentum and long frames")
	quit(1 if failed else 0)


func reset(position: Vector2, right: bool, gait: StringName) -> void:
	main._clear_side_motion()
	main._stop_walking()
	main._dragging = false
	main._falling = false
	main._landing = false
	main._wander_enabled = false
	main._auto_climb_cooldown = 0.0
	sprite.position = position
	main._position_x = position.x
	main._fall_position_y = position.y
	main._auto_walk = gait == &"walk"
	main._auto_run = gait == &"run_light"
	main._auto_run_bouncy = gait == &"run_bouncy"
	main._begin_walk(-1 if right else 1, gait != &"walk")


func window(bounds: Rect2, id: String = "target", platform: bool = true) -> Dictionary:
	return {"id":id,"x":bounds.position.x,"y":bounds.position.y,"width":bounds.size.x,"height":bounds.size.y,"platform":platform}


func snapshot(windows: Array) -> void:
	main.set_window_platforms(WindowsPlatforms.visible_platforms(windows, Vector2.ZERO, Vector2(640,400),140,400,60))


func tick(count: int) -> void:
	for frame in count:
		await process_frame
		main._process(1.0/60.0)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
