extends SceneTree

# Run with --headless --fixed-fps 60 --script res://tests/platform_smoke.gd.
var _main: Node2D
var _sprite: AnimatedSprite2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_main.set("_wander_enabled", false)
	_sprite = _main.get_node("Bongbong")
	var surfaces: Array[Rect2] = [Rect2(200, 290, 300, 50), Rect2(120, 230, 260, 50)]
	_main.call("set_platform_surfaces", surfaces)
	var floor_y: float = _main.get("_floor_y")

	# A delayed frame crosses both platforms; the first top must catch the pet.
	_main.set_process(false)
	_drop(Vector2(240, 80))
	_main.call("_process", 1.0)
	_main.set_process(true)
	if not await _finish_landing(230, &"land_high"):
		return

	_press(KEY_RIGHT, true)
	for step in 60:
		await process_frame
	_press(KEY_RIGHT, false)
	await process_frame
	if not _expect(_sprite.position.x > 290 and _sprite.position.y == 230, "Walking did not stay on the upper platform"):
		return

	_main.set("_auto_walk", true)
	_main.call("_set_facing", 1)
	var turned := false
	for step in 420:
		await process_frame
		turned = turned or int(_main.get("_facing")) == -1
		if not _expect(_sprite.position.y == 230 and _sprite.position.x >= 120 and _sprite.position.x < 380, "Automatic walking left its platform"):
			return
	if not _expect(turned, "Automatic walking never turned at the platform edge"):
		return
	_main.call("_stop_walking")

	# Being placed beyond the safe margin must not cause a position jump.
	_drop(Vector2(378, 230))
	_main.set("_auto_walk", true)
	_main.call("_set_facing", -1)
	_main.call("_process", 1.0 / 60.0)
	if not _expect(_sprite.position.x >= 376, "A pet near the edge snapped inward"):
		return
	_main.call("_stop_walking")

	# Manual movement can leave the top and land on the lower one.
	_drop(Vector2(378, 230))
	_press(KEY_RIGHT, true)
	if not await _finish_landing(290, &"land_low"):
		return
	_press(KEY_RIGHT, false)

	# Releasing below a top must not teleport the pet up to it.
	_drop(Vector2(150, 250))
	if not await _finish_landing(floor_y, &"land_high"):
		return
	_drop(Vector2(95, 100))
	if not await _finish_landing(floor_y, &"land_high"):
		return

	# A vanished support also releases a stationary pet into FALL.
	_drop(Vector2(260, 290))
	var no_surfaces: Array[Rect2] = []
	_main.call("set_platform_surfaces", no_surfaces)
	if not await _finish_landing(floor_y, &"land_high"):
		return
	print("Platform smoke passed: fast crossing, nearest top, walking, edge turn, step-off to lower top, below-top release, missing support")
	quit()


func _drop(position: Vector2) -> void:
	_main.call("_begin_drag", _sprite.position)
	_sprite.position = position
	_main.call("_end_drag")


func _press(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = pressed
	_main.call("_unhandled_key_input", event)


func _finish_landing(y: float, animation: StringName) -> bool:
	for step in 180:
		if bool(_main.get("_landing")):
			break
		await process_frame
	if not _expect(bool(_main.get("_landing")) and _sprite.position.y == y and _sprite.animation == animation, "Unexpected landing: y=%s animation=%s, expected y=%s %s" % [_sprite.position.y, _sprite.animation, y, animation]):
		return false
	for step in 240:
		await process_frame
		if not bool(_main.get("_landing")):
			break
	return _expect(_sprite.animation == &"idle_default" and _sprite.position.y == y, "Landing did not settle into Idle on the same support")


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition
