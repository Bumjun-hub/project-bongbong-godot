extends SceneTree

const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")


func _initialize() -> void:
	var front := {"x": -1600, "y": 200, "width": 300, "height": 250, "platform": true}
	var back := {"x": -1850, "y": 300, "width": 950, "height": 300, "platform": true}
	var surfaces := WindowsPlatforms.visible_tops([front, back], Vector2(-1920, 0), Vector2(1920, 1080), 140, 1030, 60)
	if not _expect(surfaces.size() == 3, "An overlapping window should split the back window's top"):
		return
	if not _expect(surfaces.has(Rect2(70, 300, 250, 300)) and surfaces.has(Rect2(620, 300, 400, 300)), "Negative monitor coordinates or hidden top spans were incorrect"):
		return
	var scaled := WindowsPlatforms.visible_tops([back], Vector2(-1920, 0), Vector2(960, 540), 70, 515, 30, Vector2(0.5, 0.5))
	if not _expect(scaled == [Rect2(35, 150, 475, 150)], "Native-to-viewport size conversion was incorrect"):
		return
	var fullscreen := {"x": -1920, "y": 0, "width": 1920, "height": 1080, "platform": false}
	if not _expect(WindowsPlatforms.visible_tops([fullscreen, back], Vector2(-1920, 0), Vector2(1920, 1080), 140, 1030, 60).is_empty(), "A fullscreen window did not cover platforms behind it"):
		return
	var too_high := {"x": 200, "y": 80, "width": 400, "height": 300, "platform": true}
	if not _expect(WindowsPlatforms.visible_tops([too_high], Vector2.ZERO, Vector2(1920, 1080), 140, 1030, 60).is_empty(), "Window tops without headroom should not be platforms"):
		return
	var provider := WindowsPlatforms.new()
	provider.host_window = root
	var snapshot := JSON.stringify({"version": 1, "client": {"x": 0, "y": 0, "width": 640, "height": 480}, "idle_ms": 21000, "windows": []})
	if not _expect(provider.call("_accept_snapshot", snapshot) and is_equal_approx(provider.input_idle_seconds, 21.0), "Windows input idle time was not read from the native snapshot"):
		return
	provider.free()
	print("Window surfaces passed: negative monitor origin, overlapping top segments, fullscreen coverage, headroom, Windows input idle time")
	quit()


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition
