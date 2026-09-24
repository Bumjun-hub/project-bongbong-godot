extends Node2D

const IDLE_DEFAULT: StringName = &"idle_default"
const IDLE_POCKETS: StringName = &"idle_pockets"
const IDLE_ARMS_CROSSED: StringName = &"idle_arms_crossed"
const WALK: StringName = &"walk"
const WALK_FRAMES: SpriteFrames = preload("res://scenes/walk_frames.tres")
const RUN: StringName = &"run"
const RUN_FRAMES: SpriteFrames = preload("res://scenes/run_frames.tres")
const RUN_LIGHT: StringName = &"run_light"
const RUN_LIGHT_FRAMES: SpriteFrames = preload("res://scenes/run_light_frames.tres")
const RUN_BOUNCY: StringName = &"run_bouncy"
const RUN_BOUNCY_FRAMES: SpriteFrames = preload("res://scenes/run_bouncy_frames.tres")
const CANVAS_SIZE := Vector2(192, 192)
const FOOT_ANCHOR := Vector2(95, 174)
# Native movement speeds; both Walk and active Run variants play at 1.25x.
const WALK_SPEED := 72.0
# Keep the existing faster Run available as a separate animation variant.
const RUN_SPEED := 144.0
const LIGHT_RUN_SPEED := 108.0
const MOVEMENT_SCALE := 1.25
const EDGE_MARGIN := 12.0

# Weights apply only when the default Idle completes its allotted loops.
const DEFAULT_WEIGHT := 60
const POCKETS_WEIGHT := 20
const ARMS_CROSSED_WEIGHT := 20
const DEFAULT_LOOPS := Vector2i(2, 4)
const POCKETS_LOOPS := Vector2i(1, 2)
const ARMS_CROSSED_LOOPS := Vector2i(1, 2)

var _rng := RandomNumberGenerator.new()
var _completed_loops := 0
var _target_loops := 0
var _requested_idle: StringName = &""
var _left_pressed := false
var _right_pressed := false
var _auto_walk := false
var _auto_run := false
var _auto_run_bouncy := false
var _run_pressed := false
var _facing := 1
var _position_x := 320.0
var _edge_inset := 64.0
var _test_view := false
var _character_bounds := Rect2i()
var _last_mouse_region := Rect2()

@onready var bongbong: AnimatedSprite2D = $Bongbong
@onready var help_label: Label = $Help


func _ready() -> void:
	# Keep authored resources intact; add complete movement frames to this instance.
	bongbong.sprite_frames = bongbong.sprite_frames.duplicate()
	bongbong.sprite_frames.add_animation(WALK)
	bongbong.sprite_frames.set_animation_speed(WALK, WALK_FRAMES.get_animation_speed(WALK))
	bongbong.sprite_frames.set_animation_loop(WALK, true)
	for index in WALK_FRAMES.get_frame_count(WALK):
		bongbong.sprite_frames.add_frame(WALK, WALK_FRAMES.get_frame_texture(WALK, index), WALK_FRAMES.get_frame_duration(WALK, index))
	bongbong.sprite_frames.add_animation(RUN)
	bongbong.sprite_frames.set_animation_speed(RUN, RUN_FRAMES.get_animation_speed(RUN))
	bongbong.sprite_frames.set_animation_loop(RUN, true)
	for index in RUN_FRAMES.get_frame_count(RUN):
		bongbong.sprite_frames.add_frame(RUN, RUN_FRAMES.get_frame_texture(RUN, index), RUN_FRAMES.get_frame_duration(RUN, index))
	bongbong.sprite_frames.add_animation(RUN_LIGHT)
	bongbong.sprite_frames.set_animation_speed(RUN_LIGHT, RUN_LIGHT_FRAMES.get_animation_speed(RUN_LIGHT))
	bongbong.sprite_frames.set_animation_loop(RUN_LIGHT, true)
	for index in RUN_LIGHT_FRAMES.get_frame_count(RUN_LIGHT):
		bongbong.sprite_frames.add_frame(RUN_LIGHT, RUN_LIGHT_FRAMES.get_frame_texture(RUN_LIGHT, index), RUN_LIGHT_FRAMES.get_frame_duration(RUN_LIGHT, index))
	bongbong.sprite_frames.add_animation(RUN_BOUNCY)
	bongbong.sprite_frames.set_animation_speed(RUN_BOUNCY, RUN_BOUNCY_FRAMES.get_animation_speed(RUN_BOUNCY))
	bongbong.sprite_frames.set_animation_loop(RUN_BOUNCY, true)
	for index in RUN_BOUNCY_FRAMES.get_frame_count(RUN_BOUNCY):
		bongbong.sprite_frames.add_frame(RUN_BOUNCY, RUN_BOUNCY_FRAMES.get_frame_texture(RUN_BOUNCY, index), RUN_BOUNCY_FRAMES.get_frame_duration(RUN_BOUNCY, index))
	_position_x = bongbong.position.x
	# Use every pose's visible bounds, in both directions, so a turn cannot clip.
	var extent := 0.0
	for animation_name in bongbong.sprite_frames.get_animation_names():
		for index in bongbong.sprite_frames.get_frame_count(animation_name):
			var rect := bongbong.sprite_frames.get_frame_texture(animation_name, index).get_image().get_used_rect()
			extent = maxf(extent, maxf(FOOT_ANCHOR.x - rect.position.x, rect.end.x - FOOT_ANCHOR.x))
			_character_bounds = _character_bounds.merge(rect) if _character_bounds.has_area() else rect
	_edge_inset = ceilf(extent + EDGE_MARGIN)
	_rng.randomize()
	bongbong.animation_looped.connect(_on_animation_looped)
	_begin_idle(IDLE_DEFAULT)
	_configure_desktop_window()


func _configure_desktop_window() -> void:
	var window := get_window()
	window.borderless = true
	window.always_on_top = true
	window.transparent = true
	window.transparent_bg = true
	help_label.hide()
	_update_mouse_region()


func _toggle_test_view() -> void:
	_test_view = not _test_view
	help_label.visible = _test_view
	get_window().transparent_bg = not _test_view
	_update_mouse_region()
	queue_redraw()


func _update_mouse_region() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	if _test_view:
		# Let the full test view receive clicks, and avoid clipping its guides.
		window.mouse_passthrough_polygon = PackedVector2Array()
		_last_mouse_region = Rect2()
		return
	# A stable union of all poses keeps the character clickable without a large
	# invisible window blocking the desktop. Include breathing, Walk and Run poses.
	var region := Rect2(_character_bounds)
	if bongbong.flip_h:
		region.position.x = CANVAS_SIZE.x - region.end.x
	region.position += bongbong.position + bongbong.offset
	region = region.grow(2.0)
	if region == _last_mouse_region:
		return
	_last_mouse_region = region
	window.mouse_passthrough_polygon = PackedVector2Array([
		region.position,
		Vector2(region.end.x, region.position.y),
		region.end,
		Vector2(region.position.x, region.end.y),
	])


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.keycode == KEY_SHIFT:
		_run_pressed = event.is_pressed()
		return
	if event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
		if event.is_pressed():
			_auto_walk = false
			_auto_run = false
			_auto_run_bouncy = false
		if event.keycode == KEY_LEFT:
			_left_pressed = event.is_pressed()
		else:
			_right_pressed = event.is_pressed()
		_update_help()
		return
	if not event.is_pressed():
		return
	match event.keycode:
		KEY_1, KEY_KP_1:
			_request_idle(IDLE_DEFAULT)
		KEY_2, KEY_KP_2:
			_request_idle(IDLE_POCKETS)
		KEY_3, KEY_KP_3:
			_request_idle(IDLE_ARMS_CROSSED)
		KEY_4, KEY_KP_4:
			_auto_walk = not _auto_walk
			_auto_run = false
			_auto_run_bouncy = false
			_run_pressed = false
			_left_pressed = false
			_right_pressed = false
			if _auto_walk:
				_begin_walk(_facing)
				_update_help()
			else:
				_stop_walking()
		KEY_5, KEY_KP_5:
			_auto_run = not _auto_run
			_auto_walk = false
			_auto_run_bouncy = false
			_left_pressed = false
			_right_pressed = false
			if _auto_run:
				_begin_walk(_facing, true)
				_update_help()
			else:
				_stop_walking()
		KEY_6, KEY_KP_6:
			_auto_run_bouncy = not _auto_run_bouncy
			_auto_walk = false
			_auto_run = false
			_left_pressed = false
			_right_pressed = false
			if _auto_run_bouncy:
				_begin_walk(_facing, true)
				_update_help()
			else:
				_stop_walking()
		KEY_SPACE:
			_stop_walking()
		KEY_F1:
			_toggle_test_view()
		KEY_ESCAPE:
			get_tree().quit()


func _process(delta: float) -> void:
	var automatic := _auto_walk or _auto_run or _auto_run_bouncy
	var running := _auto_run or _auto_run_bouncy or _run_pressed
	var direction := _facing if automatic else int(_right_pressed) - int(_left_pressed)
	if direction == 0:
		if _is_moving():
			_position_x = bongbong.position.x
			_begin_idle(IDLE_DEFAULT)
		return

	var left_limit := _edge_inset
	var right_limit := get_viewport_rect().size.x - 1.0 - _edge_inset
	var next_x := _position_x + direction * (LIGHT_RUN_SPEED if running else WALK_SPEED) * MOVEMENT_SCALE * delta
	if next_x <= left_limit or next_x >= right_limit:
		next_x = clampf(next_x, left_limit, right_limit)
		if automatic:
			direction = 1 if next_x <= left_limit else -1
		else:
			# Holding into a boundary stops the feet as well as the position.
			_set_facing(direction)
			_position_x = next_x
			bongbong.position.x = roundf(next_x)
			if _is_moving():
				_begin_idle(IDLE_DEFAULT)
			else:
				_update_help()
			_update_mouse_region()
			queue_redraw()
			return
	_begin_walk(direction, running)
	_position_x = next_x
	bongbong.position.x = roundf(_position_x)
	_update_mouse_region()
	queue_redraw()


func _set_facing(direction: int) -> void:
	_facing = direction
	bongbong.flip_h = direction < 0
	# The source anchor is x=95, not the canvas midpoint. Mirror around that
	# same pixel centre instead of shifting the character by one pixel.
	bongbong.offset = Vector2(-(CANVAS_SIZE.x - 1.0 - FOOT_ANCHOR.x) if bongbong.flip_h else -FOOT_ANCHOR.x, -FOOT_ANCHOR.y)
	queue_redraw()


func _is_moving() -> bool:
	return bongbong.animation == WALK or bongbong.animation == RUN or bongbong.animation == RUN_LIGHT or bongbong.animation == RUN_BOUNCY


func _begin_walk(direction: int, running: bool = false) -> void:
	var animation_name := (RUN_BOUNCY if _auto_run_bouncy else RUN_LIGHT) if running else WALK
	var turned := direction != _facing
	_set_facing(direction)
	if bongbong.animation == animation_name:
		if turned:
			_update_help()
		return
	var keep_phase := _is_moving()
	var previous_frame := bongbong.frame
	var previous_progress := bongbong.frame_progress
	var previous_count := bongbong.sprite_frames.get_frame_count(bongbong.animation) if keep_phase else 0
	_requested_idle = &""
	_completed_loops = 0
	bongbong.speed_scale = MOVEMENT_SCALE
	bongbong.play(animation_name)
	# Keep the relative gait phase when switching between different frame counts.
	if keep_phase:
		var next_count := bongbong.sprite_frames.get_frame_count(animation_name)
		var next_phase := (float(previous_frame) + previous_progress) * float(next_count) / float(previous_count)
		bongbong.set_frame_and_progress(mini(int(floorf(next_phase)), next_count - 1), fposmod(next_phase, 1.0))
	_update_help()


func _stop_walking() -> void:
	_auto_walk = false
	_auto_run = false
	_auto_run_bouncy = false
	_run_pressed = false
	_left_pressed = false
	_right_pressed = false
	_position_x = bongbong.position.x
	if _is_moving():
		_begin_idle(IDLE_DEFAULT)
	else:
		_update_help()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		_stop_walking()


func _request_idle(animation_name: StringName) -> void:
	# Stop motion immediately; keep the existing Idle-to-Idle loop boundaries.
	var was_walking := _is_moving()
	_stop_walking()
	if was_walking and animation_name == IDLE_DEFAULT:
		_requested_idle = &""
		return
	_requested_idle = animation_name
	if was_walking:
		_begin_idle(IDLE_DEFAULT, 1)
	_update_help()


func _on_animation_looped() -> void:
	_completed_loops += 1
	if _is_moving():
		_update_help()
		return
	if _requested_idle != &"":
		if bongbong.animation != IDLE_DEFAULT and _requested_idle != IDLE_DEFAULT and bongbong.animation != _requested_idle:
			# A manual sub-Idle request also returns through the home pose first.
			_begin_idle(IDLE_DEFAULT, 1)
		else:
			var requested := _requested_idle
			_requested_idle = &""
			_begin_idle(requested)
		return

	if _completed_loops >= _target_loops:
		if bongbong.animation == IDLE_DEFAULT:
			_begin_idle(_choose_idle())
		else:
			_begin_idle(IDLE_DEFAULT)
	else:
		_update_help()


func _choose_idle() -> StringName:
	var roll := _rng.randi_range(1, DEFAULT_WEIGHT + POCKETS_WEIGHT + ARMS_CROSSED_WEIGHT)
	if roll <= DEFAULT_WEIGHT:
		return IDLE_DEFAULT
	if roll <= DEFAULT_WEIGHT + POCKETS_WEIGHT:
		return IDLE_POCKETS
	return IDLE_ARMS_CROSSED


func _begin_idle(animation_name: StringName, bridge_loops: int = 0) -> void:
	# Idle posture changes happen on loop boundaries; stopping movement enters the
	# default pose immediately at the same foot anchor and facing direction.
	var limits := DEFAULT_LOOPS
	if animation_name == IDLE_POCKETS:
		limits = POCKETS_LOOPS
	elif animation_name == IDLE_ARMS_CROSSED:
		limits = ARMS_CROSSED_LOOPS
	_completed_loops = 0
	_target_loops = bridge_loops if bridge_loops > 0 else _rng.randi_range(limits.x, limits.y)
	bongbong.speed_scale = 1.0
	bongbong.play(animation_name)
	bongbong.set_frame_and_progress(0, 0.0)
	_update_help()


func _update_help() -> void:
	var mode := "Bouncy run" if bongbong.animation == RUN_BOUNCY else ("Light run" if bongbong.animation == RUN_LIGHT else ("Run" if bongbong.animation == RUN else ("Walk" if bongbong.animation == WALK else "Idle")))
	if _auto_walk or _auto_run or _auto_run_bouncy:
		mode = "Auto " + mode.to_lower()
	help_label.text = "%s | Facing: %s\n1: Default    2: Pockets    3: Arms crossed\nLeft/Right: Walk    Shift + Left/Right: Light run\n4: Auto walk    5: Auto light run    6: Auto bouncy run    Space: Stop" % [mode, "Left" if _facing < 0 else "Right"]
	help_label.text += "\nF1: Test view    Esc: Quit"
	help_label.text += "\nCurrent: %s | Loops: %d / %s" % [bongbong.animation, _completed_loops, "infinite" if _is_moving() else str(_target_loops)]
	if _requested_idle != &"":
		var next := String(_requested_idle)
		if not _is_moving() and bongbong.animation != IDLE_DEFAULT and _requested_idle != IDLE_DEFAULT and bongbong.animation != _requested_idle:
			next = "idle_default (1 loop) -> " + next
		help_label.text += "\nNext: %s [queued]" % next
	elif not _is_moving() and bongbong.animation != IDLE_DEFAULT:
		help_label.text += "\nNext: idle_default"


func _draw() -> void:
	if not _test_view:
		return
	# Guides sit behind the full 192x192 canvas; the sprite is never cropped.
	var guide := Color(0.42, 0.48, 0.57, 0.5)
	var feet := bongbong.position + Vector2(0.5, 0.5)
	draw_rect(Rect2(feet + bongbong.offset, CANVAS_SIZE), guide, false, 1.0)
	draw_line(Vector2(EDGE_MARGIN, feet.y), Vector2(get_viewport_rect().size.x - EDGE_MARGIN, feet.y), guide, 1.0)
	draw_line(feet + Vector2(0, -182), feet + Vector2(0, 26), guide, 1.0)
