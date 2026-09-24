extends SceneTree

func _initialize() -> void:
    var frames = load("res://scenes/idle_frames.tres") as SpriteFrames
    assert(frames != null)
    var expected = {"idle_default": 3.0, "idle_pockets": 3.6, "idle_arms_crossed": 3.3}
    for anim in expected:
        assert(frames.get_frame_count(anim) == 6)
        assert(frames.get_animation_loop(anim))
        var duration = 0.0
        for i in range(6):
            var texture = frames.get_frame_texture(anim, i)
            assert(texture != null and texture.get_size() == Vector2(192, 192))
            assert("soft_three_quarter_right" in texture.resource_path)
            duration += frames.get_frame_duration(anim, i) / frames.get_animation_speed(anim)
        assert(is_equal_approx(duration, expected[anim]))
    var scene = load("res://scenes/main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    var sprite = scene.get_node("Bongbong") as AnimatedSprite2D
    assert(sprite != null)
    for anim in expected:
        for i in range(6):
            assert(sprite.sprite_frames.get_frame_texture(anim, i) == frames.get_frame_texture(anim, i))
    print("PASS: 18 soft IDLE textures loaded; original loop times retained; main scene uses updated resource.")
    quit(0)
