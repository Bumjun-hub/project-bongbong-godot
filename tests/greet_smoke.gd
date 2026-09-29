extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node2D = scene.instantiate()
	root.add_child(main)
	await process_frame
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	if sprite.sprite_frames.get_frame_count(&"greet_wave") != 54 or sprite.sprite_frames.get_animation_loop(&"greet_wave"):
		push_error("Greeting must be a 54-frame one-shot")
		quit(1)
		return
	var hit := sprite.position + (sprite.offset + Vector2(95, 90)) * sprite.scale
	if not main.call("_is_character_hit", hit):
		push_error("Greeting smoke test point must hit the character")
		quit(1)
		return
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = hit
	main.call("_unhandled_input", press)
	if bool(main.get("_dragging")) or not bool(main.get("_press_pending")):
		push_error("Mouse press started Drag before the pointer moved")
		quit(1)
		return
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = hit
	main.call("_unhandled_input", release)
	if sprite.animation != &"greet_wave" or not bool(main.get("_greeting")):
		push_error("A click did not begin the greeting")
		quit(1)
		return
	for step in range(250):
		await process_frame
		if not bool(main.get("_greeting")):
			break
	if sprite.animation != &"idle_default" or bool(main.get("_greeting")):
		push_error("Greeting did not return to Idle")
		quit(1)
		return
	main.call("_unhandled_input", press)
	var motion := InputEventMouseMotion.new()
	motion.position = hit + Vector2(12, 0)
	main.call("_unhandled_input", motion)
	if sprite.animation != &"drag" or not bool(main.get("_dragging")):
		push_error("Moving after a press did not begin Drag")
		quit(1)
		return
	main.call("_unhandled_input", release)
	if bool(main.get("_dragging")) or sprite.animation != &"idle_default":
		push_error("Releasing a grounded Drag did not return to Idle")
		quit(1)
		return
	print("Greeting smoke passed: click waves, completes in Idle, movement still drags")
	quit()
