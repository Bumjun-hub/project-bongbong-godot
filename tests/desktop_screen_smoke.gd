extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node2D = scene.instantiate()
	main.set("native_windows_enabled", false)
	root.add_child(main)
	await process_frame
	if DisplayServer.get_name() == "headless":
		push_error("Desktop screen smoke must run with the Windows display server")
		quit(1)
		return
	var expected := Rect2i()
	for screen in DisplayServer.get_screen_count():
		var usable := DisplayServer.screen_get_usable_rect(screen)
		if usable.has_area():
			expected = expected.merge(usable) if expected.has_area() else usable
	var window := root
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	if window.position != expected.position or window.size != expected.size:
		push_error("Desktop window does not cover every usable screen: %s %s vs %s" % [window.position, window.size, expected])
		quit(1)
		return
	if not is_equal_approx(sprite.scale.x, 0.72) or not is_equal_approx(sprite.scale.y, 0.72):
		push_error("Character display scale is not 72 percent")
		quit(1)
		return
	if sprite.position.x < float(expected.size.x) * 0.75 or sprite.position.y < float(expected.size.y) * 0.75:
		push_error("Character did not start near the lower right")
		quit(1)
		return
	var idle_texture := sprite.sprite_frames.get_frame_texture(&"idle_default", 0)
	var sole_end := idle_texture.get_image().get_used_rect().end.y
	var visible_bottom := sprite.position.y + (sole_end + sprite.offset.y) * sprite.scale.y
	if absf(visible_bottom - expected.size.y) > 1.0:
		push_error("The visible sole floats above or clips below the taskbar boundary: %s vs %s" % [visible_bottom, expected.size.y])
		quit(1)
		return
	print("Taskbar contact: visible sole bottom=%.2f, usable desktop bottom=%d" % [visible_bottom, expected.size.y])
	if window.mouse_passthrough_polygon.size() != 4:
		push_error("Transparent desktop is not click-through outside the character")
		quit(1)
		return
	var start_x := sprite.position.x
	main.set("_auto_walk", true)
	main.call("_set_facing", -1)
	main.call("_process", 15.0)
	if expected.size.x > 1280 and start_x - sprite.position.x < 640.0:
		push_error("Character stopped at the former 640-pixel window boundary")
		quit(1)
		return
	if window.mouse_passthrough_polygon[0].x > sprite.position.x:
		push_error("Clickable character region did not follow the movement")
		quit(1)
		return
	print("Desktop screen smoke passed: window=%s, position=%s, moved_x=%.1f, scale=%s" % [window.size, window.position, start_x - sprite.position.x, sprite.scale])
	quit()
