extends SceneTree

const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	main.set("native_windows_enabled", false)
	root.add_child(main)
	main.set_process(false)
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	if not _check(sprite.sprite_frames.get_frame_count(&"sit_down") == 16 and sprite.sprite_frames.get_frame_count(&"sit_rest") == 5 and sprite.sprite_frames.get_frame_count(&"sit_up") == 63, "Window rest frame counts changed"):
		return
	if not _check(is_equal_approx(sprite.sprite_frames.get_animation_speed(&"sit_down"), 20.0) and is_equal_approx(sprite.sprite_frames.get_animation_speed(&"sit_up"), 40.0), "Window sit playback speeds changed"):
		return
	if not _check(not main.call("_begin_sitting"), "Sitting started on the desktop instead of a window"):
		return
	_window(main, Rect2(100, 230, 400, 100))
	sprite.position = Vector2(220, 230)
	main.set("_position_x", 220.0)
	main.call("_begin_idle", &"idle_default")
	if not _check(main.call("_begin_sitting") and sprite.animation == &"sit_down", "Window idle did not enter sitting"):
		return
	sprite.set_frame_and_progress(7, 0.0)
	if not _check(sprite.offset.y == -174.0, "The low hop changed the window anchor"):
		return
	for index in range(1, 5):
		sprite.set_frame_and_progress(index, 0.0)
		var crouch_bottom := sprite.sprite_frames.get_frame_texture(&"sit_down", index).get_image().get_used_rect().end.y
		if not _check(absf(float(crouch_bottom) + sprite.offset.y) <= 1.0, "An anticipation shoe left the ledge at frame %d" % (index + 1)):
			return
	sprite.set_frame_and_progress(7, 0.0)
	var airborne_bottom := sprite.sprite_frames.get_frame_texture(&"sit_down", 7).get_image().get_used_rect().end.y
	if not _check(float(airborne_bottom) + sprite.offset.y <= -8.0 and float(airborne_bottom) + sprite.offset.y >= -12.0, "The low hop height drifted"):
		return
	sprite.set_frame_and_progress(15, 0.0)
	if not _check(sprite.offset.y == -140.0, "The seat did not stay on the window top"):
		return
	main.call("_on_animation_finished")
	if not _check(sprite.animation == &"sit_rest" and main.get("_sitting"), "Sitting did not enter its rest loop"):
		return
	var seated_image := sprite.sprite_frames.get_frame_texture(&"sit_down", 15).get_image()
	var seated_pose := seated_image.get_data()
	var idle_pose: Image = load("res://assets/character/idle/soft_three_quarter_right/default/idle_01.png").get_image()
	var idle_bounds := idle_pose.get_used_rect()
	var seated_bounds := seated_image.get_used_rect()
	if not _check(sprite.sprite_frames.get_frame_texture(&"sit_down", 1).get_image().get_data() != sprite.sprite_frames.get_frame_texture(&"sit_down", 3).get_image().get_data(), "Anticipation reused the same frozen pose"):
		return
	for index in range(1, 10):
		var hop_bounds := sprite.sprite_frames.get_frame_texture(&"sit_down", index).get_image().get_used_rect()
		if not _check(hop_bounds.size.y <= idle_bounds.size.y + 2, "A hop frame stretched the SD legs at frame %d" % (index + 1)):
			return
	if not _check(seated_bounds.size.y <= idle_bounds.size.y + 4 and seated_bounds.end.y <= idle_bounds.end.y + 1, "Seated legs grew beyond the IDLE SD proportions"):
		return
	if not _check(seated_bounds.end.y <= idle_bounds.end.y - 5, "The seated shins were not shortened"):
		return
	var dust_bounds := sprite.sprite_frames.get_frame_texture(&"sit_down", 12).get_image().get_used_rect()
	if not _check(dust_bounds.position.x < idle_bounds.position.x and dust_bounds.end.x > idle_bounds.end.x + 15, "The landing dust did not spread to both sides"):
		return
	if not _check(sprite.sprite_frames.get_frame_texture(&"sit_rest", 0).get_image().get_data() == seated_pose and sprite.sprite_frames.get_frame_texture(&"sit_up", 0).get_image().get_data() == seated_pose, "The seated pose shifted before standing"):
		return
	if not _check(sprite.sprite_frames.get_frame_texture(&"sit_rest", 2).get_image().get_data() != seated_pose and sprite.sprite_frames.get_frame_texture(&"sit_rest", 4).get_image().get_data() == seated_pose, "The seated breathing loop froze or failed to return"):
		return
	if not _check(sprite.sprite_frames.get_frame_count(&"sit_sleep_enter") == 8 and sprite.sprite_frames.get_frame_count(&"sit_sleep_loop") == 24 and sprite.sprite_frames.get_frame_count(&"sit_sleep_wake") == 24, "The seated sleep transitions are missing"):
		return
	if not _check(sprite.sprite_frames.get_animation_speed(&"sit_sleep_wake") == 24.0, "The wake-up animation speed changed"):
		return
	if not _check(sprite.sprite_frames.get_animation_speed(&"sit_sleep_loop") == 10.0 and is_equal_approx(sprite.sprite_frames.get_frame_duration(&"sit_sleep_loop", 0), 0.9) and is_equal_approx(sprite.sprite_frames.get_frame_duration(&"sit_sleep_loop", 15), 0.9) and is_equal_approx(sprite.sprite_frames.get_frame_duration(&"sit_sleep_loop", 16), 1.0) and is_equal_approx(sprite.sprite_frames.get_frame_duration(&"sit_sleep_loop", 23), 0.5), "The sleepy nod must lower slowly and recover smoothly across the loop"):
		return
	if not _check(sprite.sprite_frames.get_frame_texture(&"sit_sleep_enter", 0).get_image().get_data() == seated_pose and sprite.sprite_frames.get_frame_texture(&"sit_sleep_wake", 23).get_image().get_data() == seated_pose, "Sleep did not join the seated pose seamlessly"):
		return
	for pair in [[0, 16], [1, 15], [10, 6], [16, 0], [23, 14]]:
		if not _check(sprite.sprite_frames.get_frame_texture(&"sit_sleep_loop", pair[0]).get_image().get_data() == sprite.sprite_frames.get_frame_texture(&"sit_sleep_wake", pair[1]).get_image().get_data(), "Waking changed the current sleeping pose at loop frame %d" % (pair[0] + 1)):
			return
	for index in range(1, 8):
		if not _check(sprite.sprite_frames.get_frame_texture(&"sit_sleep_loop", index * 2).get_image().get_data() == sprite.sprite_frames.get_frame_texture(&"sit_sleep_loop", 24 - index).get_image().get_data(), "The sleepy nod skipped a return pose near the loop seam"):
			return
	for index in 8:
		if not _check(sprite.sprite_frames.get_frame_texture(&"sit_sleep_enter", index).get_image().get_data() == sprite.sprite_frames.get_frame_texture(&"sit_sleep_wake", 23 - index).get_image().get_data(), "Waking changed the current falling-asleep pose at frame %d" % (index + 1)):
			return
	for animation_name in [&"sit_sleep_enter", &"sit_sleep_loop", &"sit_sleep_wake"]:
		for index in sprite.sprite_frames.get_frame_count(animation_name):
			if not _check(sprite.sprite_frames.get_frame_texture(animation_name, index).get_image().get_used_rect().end.y == seated_bounds.end.y, "A sleeping shoe lifted off the seat at %s frame %d" % [animation_name, index + 1]):
				return
	main.call("_on_animation_looped")
	if not _check(sprite.animation == &"sit_rest", "The ordinary idle loop interrupted window rest"):
		return
	_window(main, Rect2(130, 250, 400, 100))
	if not _check(sprite.position == Vector2(250, 250), "Sitting did not follow its window"):
		return
	main.call("_process", 10.0)
	if not _check(sprite.animation == &"sit_up", "Window rest did not begin standing immediately"):
		return
	for index in range(50, 63):
		sprite.set_frame_and_progress(index, 0.0)
		var bottom := sprite.sprite_frames.get_frame_texture(&"sit_up", index).get_image().get_used_rect().end.y
		if not _check(absf(float(bottom) + sprite.offset.y) <= 3.0, "A standing shoe left the window top at frame %d" % (index + 1)):
			return
	var final_pose := sprite.sprite_frames.get_frame_texture(&"sit_up", 62).get_image()
	if not _check(final_pose.get_data() == idle_pose.get_data(), "Standing did not finish on the exact IDLE pose"):
		return
	main.call("_on_animation_finished")
	if not _check(not main.get("_sitting") and sprite.animation == &"idle_default" and sprite.offset.y == -174.0, "Standing up did not restore idle and its foot anchor"):
		return
	main.call("_on_system_idle_changed", 21.0)
	main.call("_process", 0.1)
	if not _check(sprite.animation == &"sit_down", "Windows input inactivity did not automatically start sitting on a window"):
		return
	sprite.set_frame_and_progress(15, 0.0)
	main.call("_on_animation_finished")
	if not _check(sprite.animation == &"sit_sleep_enter" and sprite.offset.y == -140.0, "Inactivity did not continue the sitting animation into sleep"):
		return
	main.call("_on_animation_finished")
	if not _check(sprite.animation == &"sit_sleep_loop" and sprite.sprite_frames.get_animation_loop(&"sit_sleep_loop"), "Sleep did not enter its nodding loop"):
		return
	main.call("_process", 10.0)
	if not _check(sprite.animation == &"sit_sleep_loop", "Sleep stopped without user input"):
		return
	sprite.set_frame_and_progress(16, 0.0)
	var sleepy_pose := sprite.sprite_frames.get_frame_texture(&"sit_sleep_loop", 16).get_image().get_data()
	main.call("_on_system_idle_changed", 0.1)
	if not _check(sprite.animation == &"sit_sleep_wake" and sprite.frame == 0 and sprite.sprite_frames.get_frame_texture(&"sit_sleep_wake", sprite.frame).get_image().get_data() == sleepy_pose, "Windows input did not wake immediately from the current nod pose"):
		return
	main.call("_on_animation_finished")
	if not _check(sprite.animation == &"sit_up", "Waking did not continue into standing up"):
		return
	main.call("_on_animation_finished")
	if not _check(sprite.animation == &"idle_default" and not main.get("_sitting"), "Waking did not finish at IDLE"):
		return
	main.call("_on_system_idle_changed", -1.0)
	if not _check(main.call("_begin_sitting"), "Window rest could not start again"):
		return
	sprite.set_frame_and_progress(15, 0.0)
	main.call("_on_animation_finished")
	main.call("_start_sit_up")
	if not _check(sprite.animation == &"sit_up", "Manual exit did not begin standing immediately"):
		return
	main.call("_on_animation_finished")
	if not _check(main.call("_begin_sitting"), "Window rest could not restart after manual exit"):
		return
	main.call("_begin_drag", sprite.position)
	if not _check(not main.get("_sitting") and sprite.animation == &"drag", "Dragging did not interrupt sitting"):
		return
	main.call("_end_drag")
	if not _check(main.call("_begin_sitting"), "Window rest did not resume after drag"):
		return
	main.call("set_window_platforms", [])
	if not _check(main.get("_falling") and not main.get("_sitting") and sprite.animation == &"fall_intro", "Removing the window did not release the sitter into FALL"):
		return
	print("Window rest passed: window-only, low hop, short legs, seated sleep, input wake, planted shoes, exact IDLE, moving window, drag and falling release")
	quit()


func _window(main: Node2D, bounds: Rect2) -> void:
	var windows := [{"id": "support", "x": bounds.position.x, "y": bounds.position.y, "width": bounds.size.x, "height": bounds.size.y, "platform": true}]
	main.call("set_window_platforms", WindowsPlatforms.visible_platforms(windows, Vector2.ZERO, Vector2(640, 400), 140, 400, 60))


func _check(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok
