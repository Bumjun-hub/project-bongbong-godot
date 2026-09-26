extends SceneTree

const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")
var _main: Node2D
var _sprite: AnimatedSprite2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	_main.set("native_windows_enabled", false)
	_main.set("auto_climb_enabled", false)
	root.add_child(_main)
	_main.set_process(false)
	_main.set("_wander_enabled", false)
	_sprite = _main.get_node("Bongbong")
	_snapshot(Rect2(200, 180, 250, 180))
	_drop(Vector2(163, 300))
	if not _expect(_holding() and _sprite.animation == &"side_hold" and not _sprite.flip_h, "Left side release did not grab facing right"):
		return
	if not _expect(absf(_hand().x - 200) <= 0.6, "Left-side hands do not touch the edge"):
		return
	var before := _sprite.position
	_main.call("_process", 5.0)
	if not _expect(_sprite.position == before and _holding(), "Static hold fell or wandered"):
		return
	_snapshot(Rect2(240, 160, 250, 180))
	if not _expect(_holding() and _sprite.position == before + Vector2(40, -20), "Side hold did not follow the window"):
		return
	_main.call("_begin_drag", _sprite.position)
	if not _expect(not _holding() and _main.get("_dragging"), "Dragging did not detach the held window"):
		return

	_snapshot(Rect2(200, 180, 250, 180))
	_drop(Vector2(488, 300))
	if not _expect(_holding() and _sprite.flip_h and absf(_hand().x - 450) <= 0.6, "Right side release did not mirror its hand contact"):
		return
	_snapshot(Rect2(200, 180, 200, 180))
	if not _expect(_holding() and absf(_hand().x - 400) <= 0.6, "Right-side resize did not keep the hands on the new edge"):
		return
	var release := InputEventKey.new()
	release.keycode = KEY_SPACE
	release.pressed = true
	_main.call("_unhandled_key_input", release)
	if not _expect(not _holding() and _main.get("_falling"), "Space did not release into FALL"):
		return
	_main.call("_process", 0.05)
	if not _expect(not _holding(), "Released pet immediately grabbed the side again"):
		return

	_snapshot(Rect2(200, 180, 250, 180))
	_drop(Vector2(163, 300))
	_snapshot(Rect2(200, 180, 250, 180), [{"id": "cover", "x": 150, "y": 225, "width": 70, "height": 65, "platform": true}])
	if not _expect(not _holding() and _main.get("_falling"), "Occluded hands remained attached"):
		return
	_drop(Vector2(163, 300))
	if not _expect(not _holding(), "A hidden side could still be grabbed"):
		return

	_snapshot(Rect2(200, 180, 250, 180))
	_drop(Vector2(235, 300))
	if not _expect(not _holding(), "Pet grabbed a side from inside the window"):
		return
	_drop(Vector2(110, 300))
	if not _expect(not _holding(), "Distant pet teleported to a window side"):
		return
	_drop(Vector2(163, 300))
	_main.call("set_window_platforms", [])
	if not _expect(not _holding() and _main.get("_falling"), "Removed window did not release the side hold"):
		return
	print("Side grab passed: both edges, contact anchors, stable pose, movement/resize, drag/Space release, occlusion, reach and removal")
	quit()


func _snapshot(bounds: Rect2, front: Array = []) -> void:
	var windows := front.duplicate(true)
	windows.append({"id": "support", "x": bounds.position.x, "y": bounds.position.y, "width": bounds.size.x, "height": bounds.size.y, "platform": true})
	_main.call("set_window_platforms", WindowsPlatforms.visible_platforms(windows, Vector2.ZERO, Vector2(640, 400), 140, 400, 60))


func _drop(position: Vector2) -> void:
	_main.call("_begin_drag", _sprite.position)
	_sprite.position = position
	_main.call("_end_drag")


func _holding() -> bool:
	return not _main.get("_side_hold").is_empty()


func _hand() -> Vector2:
	var anchor: Vector2 = _main.SIDE_HAND_ANCHOR
	if _sprite.flip_h:
		anchor.x = 191.0 - anchor.x
	return _sprite.position + (anchor + _sprite.offset) * _sprite.scale


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition
