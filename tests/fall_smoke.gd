extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node2D = scene.instantiate()
	root.add_child(main)
	await process_frame
	var sprite: AnimatedSprite2D = main.get_node("Bongbong")
	if sprite.sprite_frames.get_frame_count(&"fall_intro") != 12 or sprite.sprite_frames.get_frame_count(&"fall_air") != 8:
		push_error("FALL frame counts do not match the imported assets")
		quit(1)
		return
	if not await _check_drop(main, sprite, 150.0, true):
		quit(1)
		return
	if not await _check_drop(main, sprite, 25.0, false):
		quit(1)
		return
	print("FALL smoke passed: long drop loops in air; short drop lands from intro")
	quit()


func _check_drop(main: Node2D, sprite: AnimatedSprite2D, height: float, expect_air: bool) -> bool:
	var floor_y: float = float(main.get("_floor_y"))
	sprite.position.y = floor_y - height
	main.set("_dragging", true)
	main.call("_end_drag")
	if not bool(main.get("_falling")) or sprite.animation != &"fall_intro":
		push_error("Releasing DRAG did not start FALL")
		return false
	var saw_air := false
	for step in range(180):
		await process_frame
		if sprite.animation == &"fall_air":
			saw_air = true
		if not bool(main.get("_falling")):
			break
	if bool(main.get("_falling")) or sprite.animation != &"idle_default" or not is_equal_approx(sprite.position.y, floor_y):
		push_error("FALL did not finish at the floor in Idle")
		return false
	if saw_air != expect_air:
		push_error("FALL air-loop transition was incorrect")
		return false
	return true
