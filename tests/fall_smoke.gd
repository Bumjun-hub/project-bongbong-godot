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
	if sprite.sprite_frames.get_frame_count(&"land_low") != 13 or sprite.sprite_frames.get_animation_loop(&"land_low"):
		push_error("LAND low must be a 13-frame one-shot")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count(&"land_high") != 52 or sprite.sprite_frames.get_animation_loop(&"land_high"):
		push_error("LAND high must be a 52-frame one-shot")
		quit(1)
		return
	if not await _check_drop(main, sprite, 150.0, true, &"land_high"):
		quit(1)
		return
	if not await _check_drop(main, sprite, 25.0, false, &"land_low"):
		quit(1)
		return
	if not await _check_drop(main, sprite, 800.0, true, &"land_high"):
		quit(1)
		return
	print("FALL/LAND smoke passed: accelerating drop, speed limit, soft/high LAND, return to Idle")
	quit()


func _check_drop(main: Node2D, sprite: AnimatedSprite2D, height: float, expect_air: bool, expected_land: StringName) -> bool:
	var floor_y: float = float(main.get("_floor_y"))
	sprite.position.y = floor_y - height
	main.set("_dragging", true)
	main.call("_end_drag")
	if not bool(main.get("_falling")) or sprite.animation != &"fall_intro":
		push_error("Releasing DRAG did not start FALL")
		return false
	var saw_air := false
	var previous_speed := 0.0
	var peak_speed := 0.0
	var first_distance := 0.0
	var second_distance := 0.0
	var fall_steps := 0
	for step in range(180):
		await process_frame
		fall_steps = step + 1
		var speed: float = main.get("_fall_velocity")
		if bool(main.get("_falling")):
			if speed + 0.001 < previous_speed or speed > 1000.001:
				push_error("FALL slowed before landing or exceeded the speed limit")
				return false
			previous_speed = speed
			peak_speed = maxf(peak_speed, speed)
		if step == 5:
			first_distance = float(main.get("_fall_position_y")) - (floor_y - height)
		elif step == 11:
			second_distance = float(main.get("_fall_position_y")) - (floor_y - height) - first_distance
		if sprite.animation == &"fall_air":
			saw_air = true
		if not bool(main.get("_falling")):
			break
	if bool(main.get("_falling")) or not bool(main.get("_landing")) or sprite.animation != expected_land or absf(sprite.position.y - floor_y) > 0.5:
		push_error("FALL did not hand off to LAND at the floor: %s, landing=%s, y=%.3f, floor=%.3f" % [sprite.animation, main.get("_landing"), sprite.position.y, floor_y])
		return false
	if saw_air != expect_air:
		push_error("FALL air-loop transition was incorrect")
		return false
	if height >= 800.0:
		if first_distance <= 0.0 or second_distance < first_distance * 2.0:
			push_error("High drop did not visibly accelerate after release")
			return false
		if peak_speed < 999.0 or fall_steps > 96:
			push_error("High drop did not reach its intended speed within 1.6 seconds at 60 FPS")
			return false
	print("Drop %.0f px: %d frames, peak %.1f px/s, %s" % [height, fall_steps, peak_speed, expected_land])
	for step in range(150):
		await process_frame
		if not bool(main.get("_landing")):
			break
	if bool(main.get("_landing")) or sprite.animation != &"idle_default":
		push_error("LAND did not finish in Idle")
		return false
	return true
