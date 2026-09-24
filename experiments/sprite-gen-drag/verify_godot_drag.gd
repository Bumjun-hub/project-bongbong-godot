extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	assert(scene != null)
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	var sprite := main.get_node("Bongbong") as AnimatedSprite2D
	assert(sprite.sprite_frames.has_animation(&"drag"))
	assert(sprite.sprite_frames.get_frame_count(&"drag") == 20)
	assert(is_equal_approx(sprite.sprite_frames.get_animation_speed(&"drag"), 25.0))
	assert(sprite.sprite_frames.get_animation_loop(&"drag"))
	var image := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).get_image()
	var hit := Vector2.ZERO
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.9:
				hit = sprite.position + sprite.offset + Vector2(x, y)
				break
		if hit != Vector2.ZERO:
			break
	assert(hit != Vector2.ZERO)
	assert(main._is_character_hit(hit))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = hit
	main._unhandled_input(press)
	assert(main._dragging)
	assert(sprite.animation == &"drag")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = hit
	main._unhandled_input(release)
	assert(not main._dragging)
	assert(sprite.animation == &"idle_default")
	print("DRAG OK: 20 frames, 25 fps, mouse grab/release")
	quit()
