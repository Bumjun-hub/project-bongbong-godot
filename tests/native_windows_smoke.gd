extends SceneTree

var _main: Node2D
var _provider: Node
var _fixture: Window
var _occluder: Window


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Native windows test requires the Windows display server")
		return
	root.gui_embed_subwindows = false
	_main = load("res://scenes/main.tscn").instantiate()
	_main.set("auto_climb_enabled", false)
	root.add_child(_main)
	_main.set("_wander_enabled", false)
	_provider = _main.get("_windows_provider")
	_fixture = _create_window("Bongbong native platform test", Vector2i(500, 380), Vector2i(600, 250))
	var handle := str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, _fixture.get_window_id()))
	if not await _wait_for_window(handle, true):
		return
	var entry := _find_window(handle)
	var native_client: Rect2 = _provider.get("native_client_rect")
	var top := float(entry["y"]) - native_client.position.y
	var left := float(entry["x"]) - native_client.position.x
	var width := float(entry["width"])
	var excluded := str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, root.get_window_id()))
	if not _find_window(excluded).is_empty():
		_fail("The pet's transparent window was included as a platform")
		return
	if top < 320 or top > 400 or width < 590:
		_fail("Native visible bounds did not match the test window")
		return
	print("Native desktop origin: %s; Godot origin: %s; platform top: %.0f" % [native_client.position, root.position, top])
	var sprite: AnimatedSprite2D = _main.get_node("Bongbong")
	_main.call("_begin_drag", sprite.position)
	sprite.position = Vector2(left + width * 0.25, top - 50)
	_main.call("_end_drag")
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline and (bool(_main.get("_falling")) or bool(_main.get("_landing"))):
		await process_frame
	if sprite.position.y != top or sprite.animation != &"idle_default":
		_fail("Pet did not land on the actual native window: y=%s, top=%s, animation=%s" % [sprite.position.y, top, sprite.animation])
		return
	var start_x := sprite.position.x
	_main.set("_auto_walk", true)
	_main.call("_set_facing", 1)
	deadline = Time.get_ticks_msec() + 400
	while Time.get_ticks_msec() < deadline:
		await process_frame
	_main.call("_stop_walking")
	if sprite.position.y != top or sprite.position.x <= start_x + 5:
		_fail("Pet did not walk across the actual native window")
		return

	var initial_position := _fixture.position
	var initial_bounds := Rect2(float(entry["x"]), float(entry["y"]), width, float(entry["height"]))
	var pet_before_move := sprite.position
	_fixture.position += Vector2i(90, -55)
	var moved_bounds := Rect2(initial_bounds.position + Vector2(90, -55), initial_bounds.size)
	if not await _wait_for_bounds(handle, moved_bounds):
		return
	if sprite.position != pet_before_move + Vector2(90, -55) or bool(_main.get("_falling")):
		_fail("Pet did not follow the actual native window's movement: %s" % sprite.position)
		return

	# Put it near the right edge before reducing the actual native window width.
	_place_on_top(sprite, Vector2(left + 90 + width - 30, top - 55))
	_fixture.size = Vector2i(300, 250)
	var smaller_bounds := Rect2(moved_bounds.position, moved_bounds.size - Vector2(300, 0))
	if not await _wait_for_bounds(handle, smaller_bounds):
		return
	if sprite.position.x >= left + 90 + width - 300 or sprite.position.y != top - 55 or bool(_main.get("_falling")):
		_fail("Pet left the actual window when it was narrowed")
		return
	_fixture.size = Vector2i(600, 250)
	_fixture.position = initial_position
	if not await _wait_for_bounds(handle, initial_bounds):
		return
	# The new pose must also grip and follow a real native side, not only a fixture rectangle.
	_place_on_top(sprite, Vector2(left - 35, top + 150))
	if _main.get("_side_hold").is_empty() or sprite.animation != &"side_hold":
		_fail("Releasing beside the actual native window did not grab its side")
		return
	var held_position := sprite.position
	_fixture.position += Vector2i(60, -20)
	if not await _wait_for_bounds(handle, Rect2(initial_bounds.position + Vector2(60, -20), initial_bounds.size)):
		return
	if _main.get("_side_hold").is_empty() or sprite.position != held_position + Vector2(60, -20):
		_fail("Side hold did not follow the actual native window")
		return
	_fixture.hide()
	if not await _wait_for_window(handle, false):
		return
	if not _main.get("_side_hold").is_empty() or not bool(_main.get("_falling")):
		_fail("Hiding the native side did not release the hold")
		return
	_fixture.show()
	_fixture.position = initial_position
	# Godot may recreate the native HWND when a hidden Window is shown again.
	handle = str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, _fixture.get_window_id()))
	if not await _wait_for_bounds(handle, initial_bounds):
		return
	# Run the full authored climb against an actual HWND before occlusion tests.
	_main.set("auto_climb_enabled", true)
	_place_on_top(sprite, Vector2(left - 35, top + 105))
	var saw_climb := false
	var saw_pull_up := false
	deadline = Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline and not _main.get("_side_hold").is_empty():
		saw_climb = saw_climb or sprite.animation == &"climb"
		saw_pull_up = saw_pull_up or sprite.animation == &"pull_up"
		await process_frame
	var standing_window: Dictionary = _main._platform_surfaces.supporting_window(sprite.position)
	if not saw_climb or not saw_pull_up or sprite.animation != &"idle_default" or standing_window.get("id") != handle:
		_fail("Actual native window climb did not finish on top: %s at %s" % [sprite.animation, sprite.position])
		return
	# DWM can settle the non-client border by one pixel after hide/show.
	# Assert live support above, then base the next move on its current bounds.
	entry = _find_window(handle)
	initial_bounds = Rect2(float(entry["x"]), float(entry["y"]), float(entry["width"]), float(entry["height"]))
	top = initial_bounds.position.y - native_client.position.y
	left = initial_bounds.position.x - native_client.position.x
	width = initial_bounds.size.x
	# Bring the real window's bottom to the desktop floor. Roaming must find
	# and approach its side, grab without a drag release, and finish on top.
	var floor_y: float = _main.get("_floor_y")
	var down := roundf(floor_y - top - initial_bounds.size.y)
	_fixture.position = initial_position + Vector2i(0, int(down))
	if not await _wait_for_bounds(handle, Rect2(initial_bounds.position + Vector2(0, down), initial_bounds.size)):
		return
	_place_on_top(sprite, Vector2(left - 110, floor_y))
	_main.set("_wander_enabled", true)
	# The preceding climb has just finished; respect its re-grab cooldown
	# before asking roaming to choose its next direction.
	_main.set("_wander_time_left", float(_main.get("_auto_climb_cooldown")) + 0.1)
	_main.call("_set_facing", -1)
	var saw_auto_hold := false
	var saw_auto_reach := false
	saw_climb = false
	saw_pull_up = false
	deadline = Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		saw_auto_hold = saw_auto_hold or sprite.animation == &"side_hold"
		saw_auto_reach = saw_auto_reach or sprite.animation == &"climb_entry"
		saw_climb = saw_climb or sprite.animation == &"climb"
		saw_pull_up = saw_pull_up or sprite.animation == &"pull_up"
		if saw_pull_up and _main.get("_side_hold").is_empty():
			break
		await process_frame
	if not saw_auto_reach or not saw_auto_hold or not saw_climb or not saw_pull_up or sprite.animation != &"idle_default" or sprite.position.y != top + down:
		_fail("Autonomous native window approach/climb did not finish: %s at %s" % [sprite.animation, sprite.position])
		return
	_main.set("_wander_enabled", false)
	_main.call("_stop_walking")
	_fixture.position = initial_position
	if not await _wait_for_bounds(handle, initial_bounds):
		return
	_main.set("auto_climb_enabled", false)
	_place_on_top(sprite, Vector2(left + 350, top))

	_occluder = _create_window("Bongbong occlusion test", Vector2i(750, 300), Vector2i(300, 200))
	var front_handle := str(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, _occluder.get_window_id()))
	if not await _wait_for_window(front_handle, true):
		return
	for surface in _provider.get("surfaces"):
		if is_equal_approx(surface.position.y, top) and surface.position.x <= 800 and surface.end.x > 800:
			_fail("A covered part of the native window remained a platform")
			return
	if not bool(_main.get("_falling")):
		_fail("Covering the pet's supporting top did not release it")
		return
	_occluder.hide()
	if not await _wait_for_window(front_handle, false):
		return
	_place_on_top(sprite, Vector2(left + 150, top))
	_fixture.mode = Window.MODE_MINIMIZED
	if not await _wait_for_window(handle, false):
		return
	if not bool(_main.get("_falling")):
		_fail("Minimizing the supporting window did not start FALL")
		return
	_fixture.mode = Window.MODE_WINDOWED
	if not await _wait_for_window(handle, true):
		return
	_place_on_top(sprite, Vector2(left + 150, top))
	_fixture.queue_free()
	if not await _wait_for_window(handle, false):
		return
	if not bool(_main.get("_falling")):
		_fail("Closing the supporting window did not start FALL")
		return
	_occluder.queue_free()
	var helper_pid: int = _provider.get("helper_pid")
	_main.queue_free()
	await process_frame
	deadline = Time.get_ticks_msec() + 2000
	while OS.is_process_running(helper_pid) and Time.get_ticks_msec() < deadline:
		await process_frame
	if OS.is_process_running(helper_pid):
		_fail("Window helper stayed running after the pet closed")
		return
	print("Native windows passed: HWND bounds, FALL/LAND, walking, movement, resize, side hold/follow/release, climb/pull-up/Idle, autonomous floor approach/climb, occlusion, hide/minimize/close, helper cleanup")
	quit()


func _place_on_top(sprite: AnimatedSprite2D, position: Vector2) -> void:
	_main.call("_begin_drag", sprite.position)
	sprite.position = position
	_main.call("_end_drag")


func _wait_for_bounds(handle: String, expected: Rect2) -> bool:
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		var entry := _find_window(handle)
		if not entry.is_empty():
			var actual := Rect2(float(entry["x"]), float(entry["y"]), float(entry["width"]), float(entry["height"]))
			if actual == expected:
				return true
		await process_frame
	_fail("Native window movement/resize did not update: expected=%s, actual=%s" % [expected, _find_window(handle)])
	return false


func _create_window(title_text: String, position: Vector2i, dimensions: Vector2i) -> Window:
	var window := Window.new()
	window.title = title_text
	window.size = dimensions
	window.always_on_top = true
	root.add_child(window)
	window.show()
	window.position = root.position + position
	var label := Label.new()
	label.text = title_text + "\nThis temporary test window closes automatically."
	label.position = Vector2(24, 40)
	window.add_child(label)
	return window


func _find_window(handle: String) -> Dictionary:
	for entry in _provider.get("last_windows"):
		if entry.get("id") == handle:
			return entry
	return {}


func _wait_for_window(handle: String, present: bool) -> bool:
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		if str(_provider.get("status")) not in ["starting", "ready"]:
			_fail("Window provider failed: %s" % _provider.get("status"))
			return false
		if str(_provider.get("status")) == "ready" and (not _find_window(handle).is_empty()) == present:
			return true
		await process_frame
	_fail("Native window visibility did not update: present=%s, windows=%s" % [present, _provider.get("last_windows")])
	return false


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
