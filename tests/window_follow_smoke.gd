extends SceneTree

const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")
var _main: Node2D
var _sprite: AnimatedSprite2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	_main.set("native_windows_enabled", false)
	root.add_child(_main)
	_main.set_process(false)
	_main.set("_wander_enabled", false)
	_sprite = _main.get_node("Bongbong")
	var initial := Rect2(100, 230, 400, 100)
	_snapshot(initial)
	_stand(Vector2(220, 230))
	_snapshot(Rect2(180, 275, 400, 100))
	if not _expect(_sprite.position == Vector2(300, 275) and not _main.get("_falling"), "Standing pet did not follow its window in both axes"):
		return

	_main.set("_auto_walk", true)
	_main.call("_set_facing", 1)
	_main.call("_process", 0.1)
	var walking_x := _sprite.position.x
	_snapshot(Rect2(140, 250, 400, 100))
	if not _expect(_sprite.position == Vector2(walking_x - 40, 250) and _sprite.animation == &"walk", "Window movement interrupted walking or lost its position"):
		return
	_main.call("_stop_walking")
	_main.call("_begin_idle", &"idle_default")
	_snapshot(initial)
	if not _expect(_sprite.animation == &"idle_default" and _sprite.position.y == 230, "Idle did not ride along with its supporting window"):
		return

	_stand(Vector2(480, 230))
	_snapshot(Rect2(100, 230, 200, 100))
	if not _expect(_sprite.position == Vector2(280, 230) and not _main.get("_falling"), "Narrowing the window did not keep the pet on its remaining top"):
		return
	_snapshot(initial)
	if not _expect(_sprite.position.x == 280, "Enlarging a window unnecessarily moved the pet"):
		return

	# Losing part of a top must not snap the pet to a separate visible segment.
	_stand(Vector2(350, 230))
	_snapshot(initial, [{"id": "front", "x": 300, "y": 180, "width": 120, "height": 100, "platform": true}])
	if not _expect(_main.get("_falling") and _sprite.position == Vector2(350, 230), "Occlusion did not release the pet where it stood"):
		return
	_snapshot(Rect2(170, 260, 400, 100))
	if not _expect(_sprite.position == Vector2(350, 230), "An airborne pet was pulled by a previously supporting window"):
		return

	_snapshot(initial)
	_stand(Vector2(220, 230))
	_main.call("_begin_drag", _sprite.position)
	_snapshot(Rect2(170, 260, 400, 100))
	if not _expect(_main.get("_dragging") and _sprite.position == Vector2(220, 230), "Window movement pulled a pet held by the mouse"):
		return

	_snapshot(initial)
	_stand(Vector2(220, 230))
	_main.call("set_window_platforms", [])
	if not _expect(_main.get("_falling"), "Closing or minimizing the supporting window did not start FALL"):
		return
	_snapshot(initial)
	if not _expect(_main.get("_falling"), "Restoring a window canceled an ongoing fall"):
		return

	_stand(Vector2(220, 230))
	_snapshot(Rect2(100, 40, 400, 100))
	if not _expect(_main.get("_falling") and _sprite.position.y == 230, "Window movement without headroom hid the pet beyond the screen"):
		return
	print("Window follow passed: translation, walking/idle continuity, resize, occlusion, drag/airborne detachment, removal, headroom")
	quit()


func _snapshot(bounds: Rect2, front: Array = []) -> void:
	var windows := front.duplicate(true)
	windows.append({"id": "support", "x": bounds.position.x, "y": bounds.position.y, "width": bounds.size.x, "height": bounds.size.y, "platform": true})
	var platforms := WindowsPlatforms.visible_platforms(windows, Vector2.ZERO, Vector2(640, 400), 140, 400, 60)
	_main.call("set_window_platforms", platforms)


func _stand(position: Vector2) -> void:
	_main.call("_begin_drag", _sprite.position)
	_sprite.position = position
	_main.call("_end_drag")


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition
