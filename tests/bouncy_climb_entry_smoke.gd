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
	main._wander_enabled = false
	sprite = main.get_node("Bongbong")
	for right in [false, true]:
		for pose in [0, 7, 15, 19, 25]:
			reset(Vector2(530 if right else 100, 400), right, pose)
			var previous_phase := float(pose)
			var reached := false
			for frame in 240:
				await tick(1)
				if main._reaching_wall:
					reached = true
					break
				check(sprite.animation == &"run_bouncy", "Bouncy approach lowered its arms into a different gait")
				var phase := float(sprite.frame) + sprite.frame_progress
				var phase_step := fposmod(phase - previous_phase, 28.0)
				check(phase_step < 2.0, "Final bouncy steps skipped or reversed poses")
				if not main._bouncy_approach.is_empty():
					check(phase_step > 0.07, "Pose alignment stalled the feet during braking")
				previous_phase = phase
			check(reached and sprite.animation == &"climb_bouncy_entry", "Bouncy run did not use its dedicated reach")
			check(fposmod(3.0 - previous_phase, 28.0) < 1.0, "Arrival did not match the raised-arm source pose")
			check(main._bouncy_approach.is_empty(), "Distance-driven gait survived the transition")
			check(sprite.flip_h == right, "Bouncy reach faces away from the wall")
			var contact := sprite.position
			await tick(10)
			check(main._reaching_wall and sprite.position == contact and not main._climbing, "Bouncy reach moved up before hand contact")
			for frame in 100:
				await tick(1)
				if main._climbing:
					break
			check(main._climbing and sprite.animation == &"climb", "Dedicated reach did not continue into the existing climb")

	for interruption in ["remove", "drag", "space"]:
		reset(Vector2(150,400), false, 12)
		await tick(5)
		check(not main._bouncy_approach.is_empty(), "Did not establish an approach for interruption check")
		match interruption:
			"remove":
				main.set_window_platforms([])
				await tick(1)
				check(main._bouncy_approach.is_empty() and sprite.is_playing() and sprite.animation == &"run_bouncy", "Removed wall left the run paused")
			"drag":
				main._begin_drag(sprite.position)
				check(main._bouncy_approach.is_empty() and main._dragging, "Drag did not release approach control")
			"space":
				var key := InputEventKey.new()
				key.keycode = KEY_SPACE
				key.pressed = true
				main._unhandled_key_input(key)
				check(main._bouncy_approach.is_empty() and not main._auto_run_bouncy, "Space did not stop the bouncy approach")
	if not failed:
		print("Bouncy reach passed: raised arms through gradual braking, ten arrival cases without stalled feet, exact source-pose contact, both directions, existing climb continuation, wall removal, drag and Space")
	quit(1 if failed else 0)


func reset(position: Vector2, right: bool, pose: int) -> void:
	main._clear_side_motion()
	main._stop_walking()
	main._dragging = false
	main._falling = false
	main._landing = false
	main._greeting = false
	main._auto_climb_cooldown = 0.0
	sprite.position = position
	main._position_x = position.x
	main._fall_position_y = position.y
	main.set_window_platforms(WindowsPlatforms.visible_platforms([
		{"id":"target","x":230,"y":180,"width":180,"height":220,"platform":true}
	], Vector2.ZERO, Vector2(640,400),140,400,60))
	main._auto_run_bouncy = true
	main._begin_walk(-1 if right else 1,true)
	sprite.set_frame_and_progress(pose,0.0)


func tick(count: int) -> void:
	for frame in count:
		await process_frame
		main._process(1.0/60.0)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
