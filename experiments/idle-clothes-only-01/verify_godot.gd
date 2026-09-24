extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var main = load("res://scenes/main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var sprite = main.get_node("Bongbong") as AnimatedSprite2D
    var data = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/idle-clothes-only-01/mapping.json"))
    var count = 0
    for entry in data:
        var anim = entry.name
        assert(sprite.sprite_frames.get_frame_count(anim) == entry.frames.size())
        assert(is_equal_approx(sprite.sprite_frames.get_animation_speed(anim), entry.fps))
        for i in range(entry.frames.size()):
            var texture = sprite.sprite_frames.get_frame_texture(anim, i)
            assert(texture != null and texture.get_size() == Vector2(192, 192))
            assert(texture.resource_path == "res://" + entry.frames[i].output)
            var seconds = sprite.sprite_frames.get_frame_duration(anim, i) / sprite.sprite_frames.get_animation_speed(anim)
            assert(is_equal_approx(seconds, entry.frames[i].duration))
            count += 1
    assert(count == 12)
    print("PASS: all 12 processed frames loaded in Main; original frame order, durations and FPS retained.")
    quit(0)
