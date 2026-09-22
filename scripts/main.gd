extends Node2D

@onready var bongbong: AnimatedSprite2D = $Bongbong
@onready var help_label: Label = $Help


func _ready() -> void:
	play_idle(&"idle_default")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_1, KEY_KP_1:
			play_idle(&"idle_default")
		KEY_2, KEY_KP_2:
			play_idle(&"idle_pockets")
		KEY_3, KEY_KP_3:
			play_idle(&"idle_arms_crossed")


func play_idle(animation_name: StringName) -> void:
	bongbong.stop()
	bongbong.play(animation_name)
	bongbong.set_frame_and_progress(0, 0.0)
	help_label.text = "Current: %s\n1: Default    2: Pockets    3: Arms crossed\n192 x 192  |  1:1 pixels  |  Baseline + center guides" % animation_name


func _draw() -> void:
	# Guides sit behind the full 192x192 canvas; the sprite is never cropped.
	var guide := Color(0.42, 0.48, 0.57, 0.5)
	draw_rect(Rect2(225.5, 146.5, 192.0, 192.0), guide, false, 1.0)
	draw_line(Vector2(200.0, 320.5), Vector2(440.0, 320.5), guide, 1.0)
	draw_line(Vector2(320.5, 138.0), Vector2(320.5, 346.0), guide, 1.0)
