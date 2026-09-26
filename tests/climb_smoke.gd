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
	check(main.PullUpMotion.ROOT_OFFSETS.size() == sprite.sprite_frames.get_frame_count(&"pull_up"), "Pull-up contact track does not match frame count")
	for right in [false, true]:
		snapshot(Rect2(200, 180, 250, 180))
		drop(Vector2(488 if right else 163, 330))
		check(not main._side_hold.is_empty(), "Did not grab side")
		await tick(90)
		check(main._climbing and sprite.animation == &"climb" and sprite.position.y < 310, "Did not climb automatically")
		check(sprite.flip_h == right, "Climb facing is reversed")
		var before := sprite.position
		snapshot(Rect2(220, 170, 250, 180))
		check(sprite.position == before + Vector2(20, -10), "Climbing pet did not follow window movement")
		await until_pull()
		check(main._pulling_up and sprite.animation == &"pull_up", "Did not switch to pull-up")
		var corner := Vector2(470 if right else 220, 170)
		var mirrored := Vector2(-1 if right else 1, 1)
		for pose in [0, 20, 40, 58, 76, 85, 96]:
			sprite.set_frame_and_progress(pose, 0.0)
			var authored: Vector2 = main.PullUpMotion.ROOT_OFFSETS[pose] * mirrored * main.CHARACTER_SCALE
			check(sprite.position.distance_to(corner + authored) <= 1.5, "Pose and contact track drifted at frame %d" % pose)
			sprite.set_frame_and_progress(pose, 0.8)
			main._sync_pull_up()
			check(sprite.position.distance_to(corner + authored) <= 1.5, "Contact slid between authored frames")
			sprite.set_frame_and_progress(0, 0.0)
		await tick(35)
		before = sprite.position
		snapshot(Rect2(230, 180, 220, 180))
		# Right corner moves left by 20 after shrinking; left corner moves right 10.
		check(sprite.position == before + Vector2(-20 if right else 10, 10), "Pull-up did not follow moved/resized corner")
		await until_standing()
		check(not main._pulling_up and main._side_hold.is_empty(), "Pull-up did not finish")
		check(sprite.animation == &"idle_default" and sprite.position.y == 180, "Did not finish standing on top")
		check(main._has_support() and not main._falling, "Finished feet lack support")

	# A long frame must not skip a covered gap in the same side.
	snapshot(Rect2(200, 180, 250, 180), true)
	drop(Vector2(163, 330))
	await tick(30)
	main._process(5.0)
	check(not main._side_hold.is_empty() and float(main._side_hold.height) >= 45, "Climbed through an occluded side segment")
	var blocked := sprite.position
	await tick(60)
	check(sprite.position == blocked and not main._pulling_up, "Moved through a blocked corner")
	snapshot(Rect2(200, 180, 250, 180))
	await until_pull()
	check(main._pulling_up, "Did not resume after occluder was removed")
	main.set_window_platforms([])
	check(main._falling and not main._pulling_up and main._side_hold.is_empty(), "Removed window did not interrupt pull-up")

	snapshot(Rect2(200, 180, 250, 180))
	drop(Vector2(163, 330))
	await tick(40)
	var release := InputEventKey.new()
	release.keycode = KEY_SPACE
	release.pressed = true
	main._unhandled_key_input(release)
	check(main._falling and not main._climbing and main._side_hold.is_empty(), "Space did not cancel climb")
	drop(Vector2(163, 330))
	await until_pull()
	main._begin_drag(sprite.position)
	check(main._dragging and not main._pulling_up and main._side_hold.is_empty(), "Drag did not cancel pull-up")
	if not failed:
		print("Climb passed: left/right loop, upward travel, top-out to Idle, moving/resizing windows, covered gaps, resume, removal, Space and drag interruption")
	quit(1 if failed else 0)


func snapshot(bounds: Rect2, covered: bool = false) -> void:
	var windows: Array = []
	if covered:
		windows.append({"id": "cover", "x": 170, "y": 150, "width": 70, "height": 65, "platform": true})
	windows.append({"id": "support", "x": bounds.position.x, "y": bounds.position.y, "width": bounds.size.x, "height": bounds.size.y, "platform": true})
	main.set_window_platforms(WindowsPlatforms.visible_platforms(windows, Vector2.ZERO, Vector2(640, 400), 140, 400, 60))


func drop(position: Vector2) -> void:
	main._begin_drag(sprite.position)
	sprite.position = position
	main._end_drag()


func tick(count: int) -> void:
	for i in count:
		await process_frame
		main._process(1.0 / 60.0)


func until_pull() -> void:
	for i in 500:
		if main._pulling_up or main._side_hold.is_empty():
			return
		await tick(1)


func until_standing() -> void:
	for i in 360:
		if not main._pulling_up:
			return
		await tick(1)


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
