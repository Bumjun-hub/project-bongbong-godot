extends SceneTree

# Run with --headless --fixed-fps 60 --script res://tests/wander_smoke.gd.
var _main: Node2D
var _sprite: AnimatedSprite2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_sprite = _main.get_node("Bongbong")
	var rng: RandomNumberGenerator = _main.get("_rng")
	rng.seed = 20260926
	var start := _sprite.position
	if not await _wait_for_movement(180):
		_fail("Pet did not start wandering without input")
		return
	_main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var before_focus_change := _sprite.position
	for step in 30:
		await process_frame
	if _sprite.position == before_focus_change or not bool(_main.get("_wander_moving")):
		_fail("Using another app stopped autonomous movement")
		return

	var seen := {}
	var turned := false
	var initial_facing: int = _main.get("_facing")
	for step in 7200:
		await process_frame
		seen[_sprite.animation] = true
		turned = turned or int(_main.get("_facing")) != initial_facing
		var inset: float = _main.get("_edge_inset")
		var area: Vector2 = _main.get("_play_area_size")
		if _sprite.position.x < inset - 0.5 or _sprite.position.x > area.x - 1.0 - inset + 0.5:
			_fail("Pet moved outside the desktop")
			return
	for animation in [&"idle_default", &"walk", &"run_light", &"run_bouncy"]:
		if not seen.has(animation):
			_fail("Random behavior never used %s" % animation)
			return
	if not turned or _sprite.position == start:
		_fail("Pet did not explore in both directions")
		return

	_main.call("_begin_greeting")
	var greeting_position := _sprite.position
	while bool(_main.get("_greeting")):
		await process_frame
		if _sprite.position != greeting_position or bool(_main.get("_wander_moving")):
			_fail("Wandering interrupted the greeting")
			return
	if not await _wait_for_movement(360):
		_fail("Wandering did not resume after the greeting")
		return

	_main.call("_begin_drag", _sprite.position)
	_sprite.position.y -= 150.0
	_main.call("_end_drag")
	var drop_x := _sprite.position.x
	var finished_drop := false
	for step in 480:
		await process_frame
		if _sprite.position.x != drop_x or bool(_main.get("_wander_moving")):
			_fail("Wandering interrupted FALL or LAND")
			return
		if not bool(_main.get("_falling")) and not bool(_main.get("_landing")):
			finished_drop = true
			break
	if not finished_drop or not await _wait_for_movement(360):
		_fail("Wandering did not resume after landing")
		return

	_press(KEY_SPACE)
	var paused_position := _sprite.position
	for step in 420:
		await process_frame
		if _sprite.position != paused_position or bool(_main.get("_wander_moving")):
			_fail("Space did not keep wandering paused")
			return
	_press(KEY_R)
	if not await _wait_for_movement(90):
		_fail("R did not resume wandering")
		return
	print("Wander smoke passed: autonomous rest/walk/both runs, bounds, focus loss, greeting and landing recovery, pause/resume")
	quit()


func _wait_for_movement(frames: int) -> bool:
	var previous := _sprite.position
	for step in frames:
		await process_frame
		if bool(_main.get("_wander_moving")) and _sprite.position != previous:
			return true
	return false


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	_main.call("_unhandled_key_input", event)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
