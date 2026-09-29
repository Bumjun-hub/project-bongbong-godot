extends Node2D

const PlatformSurfaces = preload("res://scripts/platform_surfaces.gd")
const WindowsPlatforms = preload("res://scripts/windows_platforms.gd")
const GrappleController = preload("res://scripts/grapple_controller.gd")
const DescentController = preload("res://scripts/descent_controller.gd")
const DescentMotion = preload("res://scripts/climb_down_motion.gd")

@export var platform_demo := false
@export var native_windows_enabled := true
@export var auto_climb_enabled := true

const IDLE_DEFAULT: StringName = &"idle_default"
const IDLE_POCKETS: StringName = &"idle_pockets"
const IDLE_ARMS_CROSSED: StringName = &"idle_arms_crossed"
const WALK: StringName = &"walk"
const WALK_FRAMES: SpriteFrames = preload("res://scenes/walk_frames.tres")
const RUN_LIGHT: StringName = &"run_light"
const RUN_LIGHT_FRAMES: SpriteFrames = preload("res://scenes/run_light_frames.tres")
const RUN_BOUNCY: StringName = &"run_bouncy"
const RUN_BOUNCY_FRAMES: SpriteFrames = preload("res://scenes/run_bouncy_frames.tres")
const DRAG: StringName = &"drag"
const DRAG_FRAMES: SpriteFrames = preload("res://scenes/drag_frames.tres")
const FALL_INTRO: StringName = &"fall_intro"
const FALL_AIR: StringName = &"fall_air"
const FALL_FRAMES: SpriteFrames = preload("res://scenes/fall_frames.tres")
const LAND_LOW: StringName = &"land_low"
const LAND_FRAMES: SpriteFrames = preload("res://scenes/land_frames.tres")
const LAND_HIGH: StringName = &"land_high"
const LAND_HIGH_FRAMES: SpriteFrames = preload("res://scenes/land_high_frames.tres")
const GREET_WAVE: StringName = &"greet_wave"
const GREET_FRAMES: SpriteFrames = preload("res://scenes/greet_frames.tres")
const SIT_DOWN: StringName = &"sit_down"
const SIT_REST: StringName = &"sit_rest"
const SIT_SLEEP_ENTER: StringName = &"sit_sleep_enter"
const SIT_SLEEP_LOOP: StringName = &"sit_sleep_loop"
const SIT_SLEEP_WAKE: StringName = &"sit_sleep_wake"
const SIT_UP: StringName = &"sit_up"
const SIT_FRAMES: SpriteFrames = preload("res://scenes/sit_frames.tres")
const SIDE_HOLD: StringName = &"side_hold"
const SIDE_HOLD_TEXTURE: Texture2D = preload("res://assets/character/climb/effort_03/side_grab.png")
const CLIMB_ENTRY: StringName = &"climb_entry"
const CLIMB_ENTRY_FRAMES: SpriteFrames = preload("res://scenes/climb_entry_frames.tres")
const CLIMB_BOUNCY_ENTRY: StringName = &"climb_bouncy_entry"
const CLIMB_BOUNCY_ENTRY_FRAMES: SpriteFrames = preload("res://scenes/climb_bouncy_entry_frames.tres")
# The dedicated reach begins on authored Bouncy run frame 4 (zero-based 3).
const BOUNCY_ENTRY_POSE := 3
const CLIMB: StringName = &"climb"
const PULL_UP: StringName = &"pull_up"
const CLIMB_FRAMES: SpriteFrames = preload("res://scenes/climb_frames.tres")
const PullUpMotion = preload("res://scripts/pull_up_motion.gd")
const CLIMB_SPEED := 43.0
const CLIMB_PLAYBACK_RATE := 1.34
const PULL_UP_PLAYBACK_RATE := 1.2
const CLIMB_START_DELAY := 0.35
const CLIMB_ENTRY_SETTLE := 0.05
const TOP_INSET := 34.0
const SIDE_HAND_ANCHOR := Vector2(139, 112)
const SIDE_HAND_MARGIN := 14.0
const SIDE_GRAB_REACH := 16.0
const AUTO_CLIMB_NOTICE_DISTANCE := 320.0
const AUTO_CLIMB_COOLDOWN := 3.0
const CLIMB_APPROACH_DECELERATION := 110.0
const CLIMB_APPROACH_MIN_SPEED := 16.0
const CLIMB_APPROACH_LOOKAHEAD := 96.0
const BOUNCY_APPROACH_MIN_RATIO := 0.45
const CLIMB_JUMP_MAX_RISE := 56.0
const CLIMB_JUMP_RUNUP := 24.0
const CLIMB_JUMP_ARC := 12.0
const CLIMB_JUMP_PREPARE_TIME := 0.32
const JumpMotion = preload("res://scripts/jump_motion.gd")
const CANVAS_SIZE := Vector2(192, 192)
const FOOT_ANCHOR := Vector2(95, 174)
const CHARACTER_SCALE := 0.72
const CLICK_DRAG_THRESHOLD := 7.0
# Translation is 60 px/s for walking and 135 px/s for either run.
const WALK_SPEED := 48.0
const LIGHT_RUN_SPEED := 108.0
const MOVEMENT_SCALE := 1.25
const WALK_ANIMATION_SCALE := 1.0
const EDGE_MARGIN := 12.0
const START_EDGE_MARGIN := 48.0
const PLATFORM_EDGE_MARGIN := 20.0
const FALL_GRAVITY := 900.0
const MAX_FALL_SPEED := 1000.0
# Keep soft landings below roughly 80 px despite the stronger gravity.
const HIGH_LAND_SPEED := 380.0
const WANDER_REST_SECONDS := Vector2(2.5, 5.0)
const WANDER_MOVE_SECONDS := Vector2(4.0, 12.0)
const SIT_REST_SECONDS := Vector2(4.0, 7.0)
const SIT_CHANCE := 0.35
const SLEEP_AFTER_NO_INPUT_SECONDS := 20.0
const SLEEP_Z_STAGES := [0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 1, 0]
const SLEEP_ENTER_WAKE_FRAMES := [23, 22, 21, 20, 19, 18, 17, 16]
const SLEEP_LOOP_WAKE_FRAMES := [16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 2, 4, 6, 8, 10, 12, 14]
const SLEEP_Z_GLYPH := ["11111", "00010", "00100", "01000", "11111"]
const SIT_SEAT_ANCHOR_Y := 140.0
const SIT_DOWN_ANCHOR_Y := [174.0, 174.0, 174.0, 174.0, 174.0, 174.0, 174.0, 174.0, 174.0, 174.0, 164.0, 150.0, 140.0, 140.0, 140.0, 140.0]

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
var _wander_enabled := true
var _wander_moving := false
var _wander_time_left := 1.5
var _run_pressed := false
var _facing := 1
var _position_x := 320.0
var _edge_inset := 64.0
var _play_area_size := Vector2(640, 400)
var _test_view := false
var _dragging := false
var _press_pending := false
var _press_position := Vector2.ZERO
var _drag_grab_offset := Vector2.ZERO
var _greeting := false
var _sitting := false
var _sit_time_left := 0.0
var _system_idle_seconds := -1.0
var _sleep_wake_requested := false
var _falling := false
var _landing := false
var _fall_velocity := 0.0
var _fall_position_y := 0.0
var _floor_y := 0.0
var _character_bounds := Rect2i()
var _last_mouse_region := Rect2()
var _platform_surfaces := PlatformSurfaces.new()
var _windows_provider: Node
var _side_hold: Dictionary = {}
var _climbing := false
var _reaching_wall := false
var _pulling_up := false
var _climb_delay := 0.0
var _pull_up_start := Vector2.ZERO
var _auto_climb_cooldown := 0.0
var _bouncy_approach: Dictionary = {}
var _climb_jump: Dictionary = {}
var _grapple: Node2D
var _descent = DescentController.new()

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
	bongbong.sprite_frames.add_animation(DRAG)
	bongbong.sprite_frames.set_animation_speed(DRAG, DRAG_FRAMES.get_animation_speed(DRAG))
	bongbong.sprite_frames.set_animation_loop(DRAG, true)
	for index in DRAG_FRAMES.get_frame_count(DRAG):
		bongbong.sprite_frames.add_frame(DRAG, DRAG_FRAMES.get_frame_texture(DRAG, index), DRAG_FRAMES.get_frame_duration(DRAG, index))
	for fall_animation in [FALL_INTRO, FALL_AIR]:
		bongbong.sprite_frames.add_animation(fall_animation)
		bongbong.sprite_frames.set_animation_speed(fall_animation, FALL_FRAMES.get_animation_speed(fall_animation))
		bongbong.sprite_frames.set_animation_loop(fall_animation, FALL_FRAMES.get_animation_loop(fall_animation))
		for index in FALL_FRAMES.get_frame_count(fall_animation):
			bongbong.sprite_frames.add_frame(fall_animation, FALL_FRAMES.get_frame_texture(fall_animation, index), FALL_FRAMES.get_frame_duration(fall_animation, index))
	for landing_animation in [LAND_LOW, LAND_HIGH]:
		var landing_frames: SpriteFrames = LAND_FRAMES if landing_animation == LAND_LOW else LAND_HIGH_FRAMES
		bongbong.sprite_frames.add_animation(landing_animation)
		bongbong.sprite_frames.set_animation_speed(landing_animation, landing_frames.get_animation_speed(landing_animation))
		bongbong.sprite_frames.set_animation_loop(landing_animation, false)
		for index in landing_frames.get_frame_count(landing_animation):
			bongbong.sprite_frames.add_frame(landing_animation, landing_frames.get_frame_texture(landing_animation, index), landing_frames.get_frame_duration(landing_animation, index))
	bongbong.sprite_frames.add_animation(GREET_WAVE)
	bongbong.sprite_frames.set_animation_speed(GREET_WAVE, GREET_FRAMES.get_animation_speed(GREET_WAVE))
	bongbong.sprite_frames.set_animation_loop(GREET_WAVE, false)
	for index in GREET_FRAMES.get_frame_count(GREET_WAVE):
		bongbong.sprite_frames.add_frame(GREET_WAVE, GREET_FRAMES.get_frame_texture(GREET_WAVE, index), GREET_FRAMES.get_frame_duration(GREET_WAVE, index))
	for animation_name in [SIT_DOWN, SIT_REST, SIT_SLEEP_ENTER, SIT_SLEEP_LOOP, SIT_SLEEP_WAKE, SIT_UP]:
		bongbong.sprite_frames.add_animation(animation_name)
		bongbong.sprite_frames.set_animation_speed(animation_name, SIT_FRAMES.get_animation_speed(animation_name))
		bongbong.sprite_frames.set_animation_loop(animation_name, SIT_FRAMES.get_animation_loop(animation_name))
		for index in SIT_FRAMES.get_frame_count(animation_name):
			bongbong.sprite_frames.add_frame(animation_name, SIT_FRAMES.get_frame_texture(animation_name, index), SIT_FRAMES.get_frame_duration(animation_name, index))
	bongbong.sprite_frames.add_animation(SIDE_HOLD)
	bongbong.sprite_frames.set_animation_loop(SIDE_HOLD, false)
	bongbong.sprite_frames.add_frame(SIDE_HOLD, SIDE_HOLD_TEXTURE)
	for animation_name in [CLIMB_ENTRY, CLIMB_BOUNCY_ENTRY, CLIMB, PULL_UP]:
		var motion_frames := CLIMB_BOUNCY_ENTRY_FRAMES if animation_name == CLIMB_BOUNCY_ENTRY else (CLIMB_ENTRY_FRAMES if animation_name == CLIMB_ENTRY else CLIMB_FRAMES)
		bongbong.sprite_frames.add_animation(animation_name)
		var playback_rate := PULL_UP_PLAYBACK_RATE if animation_name == PULL_UP else (CLIMB_PLAYBACK_RATE if animation_name == CLIMB else 1.0)
		bongbong.sprite_frames.set_animation_speed(animation_name, motion_frames.get_animation_speed(animation_name) * playback_rate)
		bongbong.sprite_frames.set_animation_loop(animation_name, motion_frames.get_animation_loop(animation_name))
		for index in motion_frames.get_frame_count(animation_name):
			bongbong.sprite_frames.add_frame(animation_name, motion_frames.get_frame_texture(animation_name, index), motion_frames.get_frame_duration(animation_name, index))
	for animation_name in [JumpMotion.NORMAL, JumpMotion.BOUNCY]:
		bongbong.sprite_frames.add_animation(animation_name)
		bongbong.sprite_frames.set_animation_speed(animation_name, JumpMotion.FRAMES.get_animation_speed(animation_name))
		bongbong.sprite_frames.set_animation_loop(animation_name, false)
		for index in JumpMotion.FRAMES.get_frame_count(animation_name):
			bongbong.sprite_frames.add_frame(animation_name, JumpMotion.FRAMES.get_frame_texture(animation_name, index), JumpMotion.FRAMES.get_frame_duration(animation_name, index))
	_grapple = GrappleController.new()
	_grapple.pet = self
	_grapple.motion = load("res://scripts/grapple_motion.gd")
	_grapple.z_index = 1
	add_child(_grapple)
	var grapple_frames: SpriteFrames = _grapple.motion.FRAMES
	var grapple_animation: StringName = _grapple.motion.ANIMATION
	bongbong.sprite_frames.add_animation(grapple_animation)
	bongbong.sprite_frames.set_animation_speed(grapple_animation, grapple_frames.get_animation_speed(grapple_animation))
	bongbong.sprite_frames.set_animation_loop(grapple_animation, false)
	for index in grapple_frames.get_frame_count(grapple_animation):
		bongbong.sprite_frames.add_frame(grapple_animation, grapple_frames.get_frame_texture(grapple_animation,index), grapple_frames.get_frame_duration(grapple_animation,index))
	_descent.pet = self
	_descent.motion = DescentMotion
	var dust_renderer: Node2D = load("res://scripts/slide_dust_renderer.gd").new()
	dust_renderer.controller = _descent
	dust_renderer.z_index = 1
	add_child(dust_renderer)
	_descent.dust_renderer = dust_renderer
	for animation_name in DescentMotion.FRAMES.get_animation_names():
		if animation_name == &"default":
			continue
		bongbong.sprite_frames.add_animation(animation_name)
		bongbong.sprite_frames.set_animation_speed(animation_name, DescentMotion.FRAMES.get_animation_speed(animation_name))
		bongbong.sprite_frames.set_animation_loop(animation_name, DescentMotion.FRAMES.get_animation_loop(animation_name))
		for index in DescentMotion.FRAMES.get_frame_count(animation_name):
			bongbong.sprite_frames.add_frame(animation_name, DescentMotion.FRAMES.get_frame_texture(animation_name, index), DescentMotion.FRAMES.get_frame_duration(animation_name, index))
	bongbong.scale = Vector2.ONE * CHARACTER_SCALE
	# Use every pose's visible bounds, in both directions, so a turn cannot clip.
	var extent := 0.0
	for animation_name in bongbong.sprite_frames.get_animation_names():
		for index in bongbong.sprite_frames.get_frame_count(animation_name):
			var rect := bongbong.sprite_frames.get_frame_texture(animation_name, index).get_image().get_used_rect()
			extent = maxf(extent, maxf(FOOT_ANCHOR.x - rect.position.x, rect.end.x - FOOT_ANCHOR.x))
			_character_bounds = _character_bounds.merge(rect) if _character_bounds.has_area() else rect
	_edge_inset = ceilf(extent * CHARACTER_SCALE + EDGE_MARGIN)
	_configure_desktop_window()
	_place_character_at_start()
	_rng.randomize()
	bongbong.animation_looped.connect(_on_animation_looped)
	bongbong.animation_finished.connect(_on_animation_finished)
	bongbong.frame_changed.connect(_on_sprite_frame_changed)
	_begin_idle(IDLE_DEFAULT)
	if platform_demo:
		set_platform_surfaces([
			Rect2(140, 350, 360, 170),
			Rect2(460, 470, 330, 122),
		])
		bongbong.position = Vector2(320, 300)
		_position_x = bongbong.position.x
		_begin_fall()
	_update_mouse_region()
	_start_windows_provider()


func _start_windows_provider() -> void:
	if platform_demo or not native_windows_enabled or OS.get_name() != "Windows" or DisplayServer.get_name() == "headless":
		return
	_windows_provider = WindowsPlatforms.new()
	_windows_provider.host_window = get_window()
	_windows_provider.minimum_top_y = (FOOT_ANCHOR.y - float(_character_bounds.position.y)) * CHARACTER_SCALE + EDGE_MARGIN
	_windows_provider.desktop_floor = _floor_y
	_windows_provider.edge_inset = _edge_inset
	_windows_provider.windows_changed.connect(set_window_platforms)
	_windows_provider.input_idle_changed.connect(_on_system_idle_changed)
	add_child(_windows_provider)


func _on_system_idle_changed(seconds: float) -> void:
	_system_idle_seconds = seconds
	if _sitting and seconds >= 0.0 and seconds < SLEEP_AFTER_NO_INPUT_SECONDS:
		if bongbong.animation == SIT_SLEEP_ENTER or bongbong.animation == SIT_SLEEP_LOOP:
			_sleep_wake_requested = true
			_start_sit_wake()


func _configure_desktop_window() -> void:
	var window := get_window()
	if platform_demo:
		window.title = "봉봉이 · 창 위 착지 테스트 (1단계)"
		window.borderless = false
		window.always_on_top = false
		window.transparent = false
		window.transparent_bg = false
		window.size = Vector2i(960, 640)
		_play_area_size = Vector2(window.size)
		if DisplayServer.get_name() != "headless":
			var usable := DisplayServer.screen_get_usable_rect()
			window.position = usable.position + (usable.size - window.size) / 2
		_test_view = true
		help_label.show()
		return
	window.borderless = true
	window.always_on_top = true
	window.transparent = true
	window.transparent_bg = true
	if DisplayServer.get_name() != "headless":
		var desktop := Rect2i()
		for screen in DisplayServer.get_screen_count():
			var usable := DisplayServer.screen_get_usable_rect(screen)
			if usable.has_area():
				desktop = desktop.merge(usable) if desktop.has_area() else usable
		if desktop.has_area():
			# The window spans every display; the mouse region remains only
			# around the character, so other apps still receive outside clicks.
			window.size = desktop.size
			window.position = desktop.position
			_play_area_size = Vector2(desktop.size)
	help_label.hide()


func _place_character_at_start() -> void:
	var right_edge := _play_area_size.x - 1.0 - _edge_inset
	var start_x := clampf(right_edge - START_EDGE_MARGIN * 0.5, _edge_inset, right_edge)
	# The desktop already excludes the taskbar. The authored sole ends exactly
	# at FOOT_ANCHOR, so no additional vertical margin is needed here.
	var start_y := _play_area_size.y - (START_EDGE_MARGIN if platform_demo else 0.0)
	bongbong.position = Vector2(roundf(start_x), roundf(start_y))
	_position_x = bongbong.position.x
	_floor_y = bongbong.position.y
	_fall_position_y = _floor_y


func _toggle_test_view() -> void:
	if platform_demo:
		return
	_test_view = not _test_view
	help_label.visible = _test_view
	get_window().transparent_bg = not _test_view
	_update_mouse_region()
	queue_redraw()


func set_platform_surfaces(rectangles: Array[Rect2]) -> void:
	_platform_surfaces.set_rectangles(rectangles)
	if is_node_ready():
		_update_help()
	queue_redraw()


func _has_support() -> bool:
	return absf(bongbong.position.y - _floor_y) <= 0.5 or _platform_surfaces.support_at(bongbong.position).has_area()


func set_window_platforms(windows: Array) -> void:
	if _descent.active():
		_platform_surfaces.set_windows(windows)
		_descent.refresh()
		_update_mouse_region()
		_update_help()
		queue_redraw()
		return
	if _grapple != null and _grapple.active():
		_platform_surfaces.set_windows(windows)
		if not _grapple.target_valid():
			_grapple.abort()
		_grapple.refresh()
		_update_help()
		queue_redraw()
		return
	if not _climb_jump.is_empty():
		_platform_surfaces.set_windows(windows)
		if not _jump_target_valid():
			_abort_climb_jump()
		_update_mouse_region()
		_update_help()
		queue_redraw()
		return
	if not _side_hold.is_empty():
		_platform_surfaces.set_windows(windows)
		var attached := _sync_pull_up() if _pulling_up else _sync_side_hold()
		if not attached:
			_begin_fall()
		_update_mouse_region()
		_update_help()
		return
	var support: Dictionary = _platform_surfaces.supporting_window(bongbong.position)
	var carried := false
	if not _dragging and not _falling and not support.is_empty():
		for window in windows:
			if window["id"] != support["id"]:
				continue
			var before: Rect2 = support["bounds"]
			var after: Rect2 = window["bounds"]
			var target_x := _position_x + after.position.x - before.position.x
			# Keep the same distance from the left edge. Only a width reduction
			# may pull the pet inward; occlusion must never teleport it sideways.
			if after.size.x < before.size.x:
				var margin := minf(PLATFORM_EDGE_MARGIN, after.size.x * 0.25)
				target_x = clampf(target_x, after.position.x + margin, after.end.x - margin)
			var target := Vector2(roundf(target_x), roundf(after.position.y))
			if target.x >= _edge_inset and target.x <= _play_area_size.x - 1.0 - _edge_inset and PlatformSurfaces.window_supports(window, target):
				bongbong.position = target
				_position_x = target_x
				_fall_position_y = target.y
				carried = true
			break
	_platform_surfaces.set_windows(windows)
	if not _dragging and not _falling and not carried and not _has_support():
		_begin_fall()
	_update_mouse_region()
	_update_help()
	queue_redraw()


func _try_begin_side_hold() -> bool:
	var offset := (SIDE_HAND_ANCHOR - FOOT_ANCHOR) * CHARACTER_SCALE
	var candidate: Dictionary = _platform_surfaces.side_grab_at(bongbong.position, offset, SIDE_GRAB_REACH, SIDE_HAND_MARGIN * CHARACTER_SCALE)
	return _begin_side_hold(candidate)


func _find_climb_approach(direction: int = 0, reach: float = AUTO_CLIMB_NOTICE_DISTANCE) -> Dictionary:
	if not auto_climb_enabled or _auto_climb_cooldown > 0.0:
		return {}
	var offset := (SIDE_HAND_ANCHOR - FOOT_ANCHOR) * CHARACTER_SCALE
	var foot := Vector2(_position_x, bongbong.position.y)
	var limits := _walking_limits(true)
	limits = Vector2(minf(limits.x, _position_x), maxf(limits.y, _position_x))
	var nearest: Dictionary = {}
	var nearest_distance := reach + 0.01
	for approach in _platform_surfaces.climb_approaches(foot, offset, SIDE_HAND_MARGIN * CHARACTER_SCALE, CLIMB_JUMP_MAX_RISE):
		var facing: int = approach["facing"]
		var point: Vector2 = approach["point"]
		var rise: float = approach["rise"]
		if rise > 0.01:
			var catch_point := point - Vector2(0.0, rise)
			if not _position_fits(catch_point - Vector2(0.0, CLIMB_JUMP_ARC)):
				continue
			# Take off from the current support; the short hop covers the last
			# horizontal gap as the hands reach the exposed side.
			point.x -= facing * minf(CLIMB_JUMP_RUNUP, maxf(0.0, (point.x - foot.x) * facing))
			approach["point"] = point
			approach["catch_point"] = catch_point
		var distance := (point.x - foot.x) * facing
		if direction != 0 and direction != facing:
			continue
		if distance < -0.01 or distance > nearest_distance:
			continue
		# The entire run-up must stay on the current supporting surface.
		if point.x < limits.x or point.x > limits.y or not _position_fits(point, true):
			continue
		var top: Dictionary = _platform_surfaces.pull_up_target(approach["hold"], TOP_INSET)
		if top.is_empty() or not _position_fits(top["point"]):
			continue
		nearest = approach
		nearest_distance = distance
	return nearest


func _find_auto_approach(direction: int = 0, reach: float = AUTO_CLIMB_NOTICE_DISTANCE) -> Dictionary:
	# Use direct contact or a small hop whenever one is available.
	var approach := _find_climb_approach(direction, reach)
	return approach if not approach.is_empty() else _grapple.find_approach(direction, reach)


func _begin_climb_jump(approach: Dictionary) -> bool:
	if not _has_support() or float(approach.get("rise", 0.0)) <= 0.01:
		return false
	var entry := JumpMotion.BOUNCY if _auto_run_bouncy else JumpMotion.NORMAL
	var start: Vector2 = approach["point"]
	var target: Vector2 = approach["catch_point"]
	var launch_speed := sqrt(2.0 * FALL_GRAVITY * (start.y - target.y + CLIMB_JUMP_ARC))
	# Catch just after the apex, with both arms already reaching forward.
	var duration := (launch_speed + sqrt(2.0 * FALL_GRAVITY * CLIMB_JUMP_ARC)) / FALL_GRAVITY
	_stop_walking()
	bongbong.position = start.round()
	_position_x = start.x
	_fall_position_y = start.y
	_falling = false
	_landing = false
	_greeting = false
	_requested_idle = &""
	_climb_jump = {"hold": approach["hold"].duplicate(), "start": start, "target": target,
		"elapsed": 0.0, "duration": duration, "launch_speed": launch_speed, "animation": entry,
		"prepare_elapsed": 0.0, "airborne": false, "takeoff_frame": JumpMotion.TAKEOFF_FRAME[entry]}
	_set_facing(int(approach["facing"]))
	bongbong.speed_scale = 1.0
	bongbong.play(entry)
	bongbong.set_frame_and_progress(0, 0.0)
	bongbong.pause()
	_update_mouse_region()
	_update_help()
	return true


func _jump_target_valid() -> bool:
	if _climb_jump.is_empty():
		return false
	if not _climb_jump["airborne"] and not _has_support():
		return false
	var hold: Dictionary = _climb_jump["hold"]
	var grip: Dictionary = _platform_surfaces.side_grip(hold, SIDE_HAND_MARGIN * CHARACTER_SCALE)
	var top: Dictionary = _platform_surfaces.pull_up_target(hold, TOP_INSET)
	if grip.is_empty() or top.is_empty() or not _position_fits(top["point"]):
		return false
	var offset := (SIDE_HAND_ANCHOR - FOOT_ANCHOR) * CHARACTER_SCALE
	var target := Vector2(grip["point"]) - Vector2(offset.x * int(grip["facing"]), offset.y)
	# A jump has a fixed flight path. Do not warp to a relocated window.
	if target.distance_to(Vector2(_climb_jump["target"])) > 0.75:
		return false
	# A newly covering window may leave the hands and corner visible while
	# hiding the middle of the route. Recheck its continuity before catching.
	for route in _platform_surfaces.climb_approaches(_climb_jump["start"], offset, SIDE_HAND_MARGIN * CHARACTER_SCALE, CLIMB_JUMP_MAX_RISE):
		var candidate: Dictionary = route["hold"]
		if candidate["id"] == hold["id"] and candidate["edge"] == hold["edge"] and absf(float(candidate["height"]) - float(hold["height"])) <= 0.75:
			return true
	return false


func _update_climb_jump(delta: float) -> void:
	if not _jump_target_valid():
		_abort_climb_jump()
		return
	var takeoff: int = _climb_jump["takeoff_frame"]
	if not _climb_jump["airborne"]:
		var remaining := CLIMB_JUMP_PREPARE_TIME - float(_climb_jump["prepare_elapsed"])
		var used := minf(delta, remaining)
		_climb_jump["prepare_elapsed"] = float(_climb_jump["prepare_elapsed"]) + used
		delta -= used
		var preparation := float(_climb_jump["prepare_elapsed"]) / CLIMB_JUMP_PREPARE_TIME
		var pose := preparation * takeoff
		bongbong.set_frame_and_progress(int(pose), fposmod(pose, 1.0))
		if preparation < 1.0:
			_update_mouse_region()
			return
		_climb_jump["airborne"] = true
	var duration: float = _climb_jump["duration"]
	var elapsed := minf(duration, float(_climb_jump["elapsed"]) + delta)
	_climb_jump["elapsed"] = elapsed
	var progress := elapsed / duration
	var start: Vector2 = _climb_jump["start"]
	var target: Vector2 = _climb_jump["target"]
	_position_x = lerpf(start.x, target.x, progress)
	_fall_position_y = start.y - float(_climb_jump["launch_speed"]) * elapsed + 0.5 * FALL_GRAVITY * elapsed * elapsed
	bongbong.position = Vector2(_position_x, _fall_position_y).round()
	var count := bongbong.sprite_frames.get_frame_count(_climb_jump["animation"])
	var phase := takeoff + progress * (count - 1 - takeoff)
	bongbong.set_frame_and_progress(int(phase), fposmod(phase, 1.0))
	if elapsed >= duration:
		var hold: Dictionary = _climb_jump["hold"].duplicate()
		_climb_jump.clear()
		if _begin_side_hold(hold):
			_climb_delay = CLIMB_ENTRY_SETTLE
		else:
			_begin_fall()
	_update_mouse_region()
	queue_redraw()


func _abort_climb_jump() -> void:
	if not _climb_jump["airborne"]:
		_clear_side_motion()
		_stop_walking()
		if _has_support():
			_begin_idle(IDLE_DEFAULT)
		else:
			_begin_fall()
		return
	var velocity := -float(_climb_jump["launch_speed"]) + FALL_GRAVITY * float(_climb_jump["elapsed"])
	var height := _fall_position_y
	_begin_fall()
	_fall_position_y = height
	_fall_velocity = velocity


func _begin_side_hold(candidate: Dictionary, from_movement: bool = false) -> bool:
	if candidate.is_empty():
		return false
	var entry_animation := CLIMB_BOUNCY_ENTRY if from_movement and _auto_run_bouncy else CLIMB_ENTRY
	_side_hold = candidate
	_climbing = false
	_reaching_wall = false
	_pulling_up = false
	_climb_delay = CLIMB_ENTRY_SETTLE if from_movement else CLIMB_START_DELAY
	if not _sync_side_hold():
		_side_hold.clear()
		return false
	_stop_walking()
	_greeting = false
	_landing = false
	_falling = false
	_fall_velocity = 0.0
	_requested_idle = &""
	bongbong.speed_scale = 1.0
	_reaching_wall = from_movement
	bongbong.play(entry_animation if from_movement else SIDE_HOLD)
	bongbong.set_frame_and_progress(0, 0.0)
	if not from_movement:
		bongbong.pause()
	_update_mouse_region()
	_update_help()
	return true


func _sync_side_hold() -> bool:
	var grip: Dictionary = _platform_surfaces.side_grip(_side_hold, SIDE_HAND_MARGIN * CHARACTER_SCALE)
	if grip.is_empty():
		return false
	var facing: int = grip["facing"]
	var offset := (SIDE_HAND_ANCHOR - FOOT_ANCHOR) * CHARACTER_SCALE
	var target: Vector2 = grip["point"] - Vector2(offset.x * facing, offset.y)
	if not _position_fits(target, true):
		return false
	bongbong.position = target.round()
	_position_x = bongbong.position.x
	_fall_position_y = bongbong.position.y
	_set_facing(facing)
	return true


func _update_side_climb(delta: float) -> void:
	if _pulling_up:
		if not _sync_pull_up():
			_begin_fall()
		return
	if not _sync_side_hold():
		_begin_fall()
		return
	if _reaching_wall or not auto_climb_enabled:
		return
	_climb_delay -= delta
	if _climb_delay > 0.0:
		return
	if not _climbing:
		_climbing = true
		bongbong.play(CLIMB)
		bongbong.set_frame_and_progress(0, 0.0)
		_update_help()
	var margin := SIDE_HAND_MARGIN * CHARACTER_SCALE
	var before := float(_side_hold["height"])
	# A small pulse follows the two alternating pulls without stopping translation.
	var phase := (float(bongbong.frame) + bongbong.frame_progress) / bongbong.sprite_frames.get_frame_count(CLIMB)
	var rise := CLIMB_SPEED * (1.0 - 0.25 * cos(phase * TAU * 2.0)) * delta
	_side_hold["height"] = _platform_surfaces.climb_height(_side_hold, rise, margin)
	if not _sync_side_hold():
		_begin_fall()
		return
	if float(_side_hold["height"]) <= margin + 0.01:
		# Finish the current reach before switching to the corner pull-up pose.
		if bongbong.frame == bongbong.sprite_frames.get_frame_count(CLIMB) - 1:
			if not _try_begin_pull_up():
				bongbong.pause()
	elif is_equal_approx(before, float(_side_hold["height"])):
		bongbong.pause()
	else:
		bongbong.play(CLIMB)


func _try_begin_pull_up() -> bool:
	var top: Dictionary = _platform_surfaces.pull_up_target(_side_hold, TOP_INSET)
	if top.is_empty() or not _position_fits(top["point"]):
		return false
	_pull_up_start = bongbong.position - Vector2(top["corner"])
	_pulling_up = true
	_climbing = false
	bongbong.play(PULL_UP)
	bongbong.set_frame_and_progress(0, 0.0)
	_sync_pull_up()
	_update_help()
	return true


func _position_fits(target: Vector2, allow_floor: bool = false) -> bool:
	var min_y := (FOOT_ANCHOR.y - float(_character_bounds.position.y)) * CHARACTER_SCALE + EDGE_MARGIN
	var below_limit := target.y <= _floor_y + 0.01 if allow_floor else target.y < _floor_y
	return target.x >= _edge_inset and target.x <= _play_area_size.x - 1.0 - _edge_inset and target.y >= min_y and below_limit


func _sync_pull_up(finished: bool = false) -> bool:
	var top: Dictionary = _platform_surfaces.pull_up_target(_side_hold, TOP_INSET)
	if top.is_empty() or not _position_fits(top["point"]):
		return false
	var count := bongbong.sprite_frames.get_frame_count(PULL_UP)
	var index := count - 1 if finished else bongbong.frame
	var progress := float(index) / float(count - 1)
	# Retain the side until the first leg has taken weight on the top.
	if index < PullUpMotion.SIDE_RELEASE_FRAME and _platform_surfaces.side_grip(_side_hold, SIDE_HAND_MARGIN * CHARACTER_SCALE).is_empty():
		return false
	var facing: int = top["facing"]
	var mirror := Vector2(facing, 1.0)
	# The clip contains the actual lift and weight transfers. Reapply its crop
	# offset with the matching pose; a separate easing curve would slide the hands.
	var offset: Vector2 = PullUpMotion.ROOT_OFFSETS[index] * mirror * CHARACTER_SCALE
	var first: Vector2 = PullUpMotion.ROOT_OFFSETS[0] * mirror * CHARACTER_SCALE
	var last: Vector2 = PullUpMotion.ROOT_OFFSETS[-1] * mirror * CHARACTER_SCALE
	var corner: Vector2 = top["corner"]
	offset += (_pull_up_start - first) * (1.0 - smoothstep(0.0, 0.15, progress))
	offset += (Vector2(top["point"]) - corner - last) * smoothstep(0.7, 1.0, progress)
	var target := corner + offset
	if not _position_fits(target):
		return false
	bongbong.position = target.round()
	_position_x = bongbong.position.x
	_fall_position_y = bongbong.position.y
	_set_facing(int(top["facing"]))
	return true


func _on_sprite_frame_changed() -> void:
	if _sitting:
		_set_facing(_facing)
		_update_mouse_region()
		queue_redraw()
	if _descent.active():
		_descent.refresh()
		_update_mouse_region()
		return
	# AnimatedSprite2D can advance after the parent's process callback.
	# Update contact in the same rendered frame, including on moving windows.
	if _pulling_up and bongbong.animation == PULL_UP:
		if not _sync_pull_up():
			_begin_fall()
		_update_mouse_region()


func _clear_side_motion() -> void:
	if _descent.active() or not _side_hold.is_empty() or not _climb_jump.is_empty() or (_grapple != null and _grapple.active()):
		_auto_climb_cooldown = AUTO_CLIMB_COOLDOWN
	if _grapple != null:
		_grapple.clear()
	_descent.clear()
	_climb_jump.clear()
	_side_hold.clear()
	_climbing = false
	_reaching_wall = false
	_pulling_up = false
	_climb_delay = 0.0


func _walking_limits(automatic: bool) -> Vector2:
	var limits := Vector2(_edge_inset, _play_area_size.x - 1.0 - _edge_inset)
	if automatic and bongbong.position.y < _floor_y - 0.5:
		var support: Rect2 = _platform_surfaces.support_at(bongbong.position)
		if support.has_area():
			var margin := minf(PLATFORM_EDGE_MARGIN, support.size.x * 0.25)
			limits.x = maxf(limits.x, support.position.x + margin)
			limits.y = minf(limits.y, support.end.x - margin)
	return limits


func _draw() -> void:
	if _sitting and bongbong.animation == SIT_SLEEP_LOOP:
		_draw_sleep_z()
	if not platform_demo:
		return
	for index in _platform_surfaces.rectangles.size():
		var rectangle: Rect2 = _platform_surfaces.rectangles[index]
		draw_rect(rectangle, Color("3c4b60"))
		draw_rect(rectangle, Color("64748b"), false, 1.0)
		draw_line(rectangle.position, Vector2(rectangle.end.x, rectangle.position.y), Color("83d6b0"), 3.0)
		draw_string(ThemeDB.fallback_font, rectangle.position + Vector2(16, 30), "TEST WINDOW %d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("dbe5ef"))
	draw_line(Vector2(24, _floor_y), Vector2(_play_area_size.x - 24, _floor_y), Color("64748b"), 2.0)


func _draw_sleep_z() -> void:
	var count: int = SLEEP_Z_STAGES[clampi(bongbong.frame, 0, SLEEP_Z_STAGES.size() - 1)]
	if count == 0:
		return
	var origin := bongbong.position + bongbong.offset * CHARACTER_SCALE
	draw_set_transform(origin, 0.0, Vector2.ONE * CHARACTER_SCALE)
	for letter in count:
		var x: int = [164, 172, 180][letter]
		if _facing < 0:
			x = 192 - x - 11
		var y: int = [80, 62, 44][letter]
		for row in 5:
			for column in 5:
				if SLEEP_Z_GLYPH[row].substr(column, 1) != "1":
					continue
				var pixel := Vector2(x + column * 2, y + row * 2)
				draw_rect(Rect2(pixel + Vector2.ONE, Vector2(2, 2)), Color("3d536a"))
				draw_rect(Rect2(pixel, Vector2(2, 2)), Color("daeefa"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
	# invisible window blocking the desktop. Include breathing and motion poses.
	var region := Rect2(_character_bounds)
	if bongbong.flip_h:
		region.position.x = CANVAS_SIZE.x - region.end.x
	region = Rect2(Vector2(region.position) * CHARACTER_SCALE, Vector2(region.size) * CHARACTER_SCALE)
	region.position += bongbong.position + bongbong.offset * CHARACTER_SCALE
	if _sitting and bongbong.animation == SIT_SLEEP_LOOP:
		var effect_origin := bongbong.position + bongbong.offset * CHARACTER_SCALE
		var effect_left := 2.0 if _facing < 0 else 164.0
		region = region.merge(Rect2(effect_origin + Vector2(effect_left, 44.0) * CHARACTER_SCALE, Vector2(27.0, 48.0) * CHARACTER_SCALE))
	region = region.grow(2.0)
	if region == _last_mouse_region and not _grapple.active():
		return
	_last_mouse_region = region
	if _grapple.active():
		# Windows clips rendering to this polygon too. Include only a narrow
		# cable corridor so the rope is visible without blocking its whole area.
		window.mouse_passthrough_polygon = _grapple.interaction_polygon(region)
		return
	window.mouse_passthrough_polygon = PackedVector2Array([
		region.position,
		Vector2(region.end.x, region.position.y),
		region.end,
		Vector2(region.position.x, region.end.y),
	])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _press_pending:
		if event.position.distance_to(_press_position) >= CLICK_DRAG_THRESHOLD:
			_press_pending = false
			_begin_drag(_press_position)
			get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if _dragging or not _is_character_hit(event.position):
			return
		_press_pending = true
		_press_position = event.position
	elif _press_pending:
		_press_pending = false
		if not _falling and not _landing and _side_hold.is_empty() and _climb_jump.is_empty() and not _grapple.active() and not _descent.active():
			_begin_greeting()
	elif _dragging:
		_end_drag()
	else:
		return
	get_viewport().set_input_as_handled()


func _is_character_hit(mouse_position: Vector2) -> bool:
	var texture := bongbong.sprite_frames.get_frame_texture(bongbong.animation, bongbong.frame)
	var pixel := (mouse_position - bongbong.position) / CHARACTER_SCALE - bongbong.offset
	if bongbong.flip_h:
		pixel.x = CANVAS_SIZE.x - 1.0 - pixel.x
	var position := Vector2i(floori(pixel.x), floori(pixel.y))
	if position.x < 0 or position.y < 0 or position.x >= int(CANVAS_SIZE.x) or position.y >= int(CANVAS_SIZE.y):
		return false
	return texture.get_image().get_pixelv(position).a > 0.2


func _begin_drag(mouse_position: Vector2) -> void:
	_cancel_sit()
	_clear_side_motion()
	_stop_walking()
	_greeting = false
	_falling = false
	_landing = false
	_fall_velocity = 0.0
	_dragging = true
	_drag_grab_offset = bongbong.position - mouse_position
	_requested_idle = &""
	_completed_loops = 0
	bongbong.speed_scale = 1.0
	bongbong.play(DRAG)
	bongbong.set_frame_and_progress(0, 0.0)
	_update_help()


func _begin_greeting() -> void:
	_cancel_sit()
	_stop_walking()
	_greeting = true
	_requested_idle = &""
	_completed_loops = 0
	bongbong.speed_scale = 1.0
	bongbong.play(GREET_WAVE)
	bongbong.set_frame_and_progress(0, 0.0)
	_update_help()


func _end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_position_x = bongbong.position.x
	var support: Rect2 = _platform_surfaces.support_at(bongbong.position)
	if support.has_area():
		bongbong.position.y = support.position.y
		_begin_idle(IDLE_DEFAULT)
	elif bongbong.position.y >= _floor_y - 1.0:
		bongbong.position.y = _floor_y
		_begin_idle(IDLE_DEFAULT)
	elif _try_begin_side_hold():
		pass
	else:
		_begin_fall()
	_update_mouse_region()


func _begin_fall() -> void:
	_cancel_sit()
	_clear_side_motion()
	_stop_walking()
	_greeting = false
	_landing = false
	_falling = true
	_fall_velocity = 0.0
	_fall_position_y = bongbong.position.y
	_requested_idle = &""
	_completed_loops = 0
	bongbong.speed_scale = 1.0
	bongbong.play(FALL_INTRO)
	bongbong.set_frame_and_progress(0, 0.0)
	_update_help()


func _begin_land(landing_animation: StringName) -> void:
	# The drop may meet the floor during either FALL animation. Keep its exact
	# visible pose for LAND's first frame before the impact begins.
	var contact_texture := bongbong.sprite_frames.get_frame_texture(bongbong.animation, bongbong.frame)
	bongbong.sprite_frames.set_frame(landing_animation, 0, contact_texture)
	_landing = true
	_requested_idle = &""
	_completed_loops = 0
	bongbong.speed_scale = 1.0
	bongbong.play(landing_animation)
	bongbong.set_frame_and_progress(0, 0.0)
	_update_help()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_pressed() and event.keycode == KEY_SPACE:
		_wander_enabled = false
		_stop_walking()
		if _sitting:
			_start_sit_up()
			return
		if _descent.active():
			_descent.abort()
		elif _grapple.active():
			_grapple.abort()
		elif not _climb_jump.is_empty():
			_abort_climb_jump()
		elif not _side_hold.is_empty():
			_begin_fall()
		else:
			_end_drag()
		return
	if event.is_pressed() and event.keycode == KEY_R:
		_wander_enabled = not _wander_enabled
		_stop_walking()
		if _sitting:
			_start_sit_up()
		if _wander_enabled:
			_wander_time_left = 0.5
		return
	if event.is_pressed() and event.keycode == KEY_D and not _dragging:
		_descent.request()
		return
	if _dragging:
		if event.is_pressed():
			match event.keycode:
				KEY_F1:
					_toggle_test_view()
				KEY_ESCAPE:
					get_tree().quit()
		return
	if _falling or _landing or not _side_hold.is_empty() or not _climb_jump.is_empty() or _grapple.active() or _descent.active():
		if event.is_pressed():
			match event.keycode:
				KEY_F1:
					_toggle_test_view()
				KEY_ESCAPE:
					get_tree().quit()
		return
	if event.keycode == KEY_SHIFT:
		_run_pressed = event.is_pressed()
		return
	if event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
		if event.is_pressed():
			_cancel_sit()
			_auto_walk = false
			_auto_run = false
			_auto_run_bouncy = false
			_wander_moving = false
			_wander_time_left = _rng.randf_range(WANDER_REST_SECONDS.x, WANDER_REST_SECONDS.y)
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
			_wander_moving = false
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
			_wander_moving = false
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
			_wander_moving = false
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
		KEY_F1:
			_toggle_test_view()
		KEY_ESCAPE:
			get_tree().quit()


func _process(delta: float) -> void:
	_descent.advance_dust(delta)
	_auto_climb_cooldown = maxf(0.0, _auto_climb_cooldown - delta)
	if _press_pending:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_press_pending = false
		elif get_viewport().get_mouse_position().distance_to(_press_position) >= CLICK_DRAG_THRESHOLD:
			_press_pending = false
			_begin_drag(_press_position)
		if _press_pending:
			return
	if _dragging:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_end_drag()
			return
		var target := get_viewport().get_mouse_position() + _drag_grab_offset
		var min_y := (FOOT_ANCHOR.y - float(_character_bounds.position.y)) * CHARACTER_SCALE + EDGE_MARGIN
		var max_y := minf(_play_area_size.y + (FOOT_ANCHOR.y - float(_character_bounds.end.y)) * CHARACTER_SCALE - EDGE_MARGIN, _floor_y)
		bongbong.position = Vector2(
			roundf(clampf(target.x, _edge_inset, _play_area_size.x - 1.0 - _edge_inset)),
			roundf(clampf(target.y, min_y, max_y))
		)
		_position_x = bongbong.position.x
		_update_mouse_region()
		queue_redraw()
		return
	if _descent.active():
		_descent.advance(delta)
		return
	if _grapple.active():
		_grapple.advance(delta)
		return
	if not _climb_jump.is_empty():
		_update_climb_jump(delta)
		return
	if not _side_hold.is_empty():
		_update_side_climb(delta)
		_update_mouse_region()
		return
	if not _falling and not _has_support():
		_begin_fall()
	if _falling:
		# A missed grab retains the upward part of its jump before falling.
		if _fall_velocity < 0.0:
			var rising_time := minf(delta, -_fall_velocity / FALL_GRAVITY)
			_fall_position_y += _fall_velocity * rising_time + 0.5 * FALL_GRAVITY * rising_time * rising_time
			_fall_velocity += FALL_GRAVITY * rising_time
			delta -= rising_time
			if delta <= 0.000001:
				bongbong.position.y = roundf(_fall_position_y)
				_update_mouse_region()
				queue_redraw()
				return
		# Accelerate from rest, then travel at the speed limit. Use the distance
		# actually fallen to find impact speed, even if contact is between frames.
		var accelerating_time := minf(delta, (MAX_FALL_SPEED - _fall_velocity) / FALL_GRAVITY)
		var fall_distance := _fall_velocity * accelerating_time + 0.5 * FALL_GRAVITY * accelerating_time * accelerating_time
		fall_distance += MAX_FALL_SPEED * (delta - accelerating_time)
		var landing_y: float = _platform_surfaces.landing_height(bongbong.position.x, _fall_position_y, _fall_position_y + fall_distance, _floor_y)
		fall_distance = minf(fall_distance, maxf(0.0, landing_y - _fall_position_y))
		_fall_velocity = minf(MAX_FALL_SPEED, sqrt(_fall_velocity * _fall_velocity + 2.0 * FALL_GRAVITY * fall_distance))
		_fall_position_y = minf(landing_y, _fall_position_y + fall_distance)
		bongbong.position.y = roundf(_fall_position_y)
		if _fall_position_y >= landing_y:
			_falling = false
			var landing_animation := LAND_HIGH if _fall_velocity >= HIGH_LAND_SPEED else LAND_LOW
			_fall_velocity = 0.0
			_begin_land(landing_animation)
		_update_mouse_region()
		queue_redraw()
		return
	if _greeting or _landing:
		return
	if _sitting:
		if bongbong.animation == SIT_REST:
			if _system_idle_seconds >= SLEEP_AFTER_NO_INPUT_SECONDS:
				_start_sit_sleep()
				return
			_sit_time_left -= delta
			if _sit_time_left <= 0.0:
				_start_sit_up()
		elif _system_idle_seconds >= 0.0 and _system_idle_seconds < SLEEP_AFTER_NO_INPUT_SECONDS:
			if bongbong.animation == SIT_SLEEP_ENTER or bongbong.animation == SIT_SLEEP_LOOP:
				_sleep_wake_requested = true
				_start_sit_wake()
		return
	if _system_idle_seconds >= SLEEP_AFTER_NO_INPUT_SECONDS and bongbong.animation == IDLE_DEFAULT:
		if not _platform_surfaces.supporting_window(bongbong.position).is_empty() and _begin_sitting():
			return
	_update_wandering(delta)
	var automatic := _auto_walk or _auto_run or _auto_run_bouncy
	var running := _auto_run or _auto_run_bouncy or _run_pressed
	var direction := _facing if automatic else int(_right_pressed) - int(_left_pressed)
	if direction == 0:
		if _is_moving():
			_position_x = bongbong.position.x
			_begin_idle(IDLE_DEFAULT)
		return

	var limits := _walking_limits(automatic)
	# A pet placed near the outer edge walks inward instead of snapping to a margin.
	var left_limit := minf(limits.x, _position_x) if automatic else limits.x
	var right_limit := maxf(limits.y, _position_x) if automatic else limits.y
	var base_speed := (LIGHT_RUN_SPEED if running else WALK_SPEED) * MOVEMENT_SCALE
	var move_speed := base_speed
	var approach: Dictionary = {}
	if automatic:
		approach = _find_auto_approach(direction, maxf(CLIMB_APPROACH_LOOKAHEAD, base_speed * delta))
		if not approach.is_empty():
			var distance := maxf(0.0, (Vector2(approach["point"]).x - _position_x) * direction)
			if _auto_run_bouncy:
				# Ease into braking, but keep enough momentum for the raised-arm
				# reach. Crawling at the shared 16 px/s made the last bounce stall.
				var approach_ratio := smoothstep(0.0, CLIMB_APPROACH_LOOKAHEAD, distance)
				move_speed = base_speed * lerpf(BOUNCY_APPROACH_MIN_RATIO, 1.0, approach_ratio)
			else:
				move_speed = minf(base_speed, sqrt(CLIMB_APPROACH_MIN_SPEED * CLIMB_APPROACH_MIN_SPEED + 2.0 * CLIMB_APPROACH_DECELERATION * distance))
	var exit_target: Dictionary = _descent.target_for(direction) if automatic and approach.is_empty() and auto_climb_enabled else {}
	if not exit_target.is_empty():
		var distance := maxf(0.0, (Vector2(exit_target["point"]).x - _position_x) * direction)
		move_speed = minf(move_speed, sqrt(pow(WALK_SPEED * MOVEMENT_SCALE, 2) + 2.0 * CLIMB_APPROACH_DECELERATION * distance))
	var next_x := _position_x + direction * move_speed * delta
	if not exit_target.is_empty() and (Vector2(exit_target["point"]).x - next_x) * direction <= 0.01:
		# Stop at the authored standing anchor before turning toward the ledge.
		bongbong.position.x = roundf(Vector2(exit_target["point"]).x)
		_position_x = bongbong.position.x
		if _descent.begin(exit_target):
			return
	if not approach.is_empty():
		# Check the whole movement step before turning at an edge. Even a fast
		# run or a late frame must stop at hand contact instead of passing through.
		var contact_x := Vector2(approach["point"]).x
		if (contact_x - clampf(next_x, left_limit, right_limit)) * direction <= 0.01:
			if approach.get("grapple",false):
				if _grapple.begin(approach):
					return
			elif float(approach.get("rise", 0.0)) > 0.01:
				if _begin_climb_jump(approach):
					return
			elif _begin_side_hold(approach["hold"], true):
				return
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
	# Bouncy run keeps its raised arms through braking and its dedicated reach.
	var still_running := running and (_auto_run_bouncy or move_speed > WALK_SPEED * MOVEMENT_SCALE)
	if not exit_target.is_empty() and move_speed <= WALK_SPEED * MOVEMENT_SCALE + 1.0:
		still_running = false
	_begin_walk(direction, still_running)
	var normal_speed := (LIGHT_RUN_SPEED if still_running else WALK_SPEED) * MOVEMENT_SCALE
	bongbong.speed_scale = (MOVEMENT_SCALE if still_running else WALK_ANIMATION_SCALE) * move_speed / normal_speed
	if _auto_run_bouncy and not approach.is_empty():
		_sync_bouncy_approach(approach, next_x)
	else:
		_clear_bouncy_approach()
	_position_x = next_x
	bongbong.position.x = roundf(_position_x)
	if not _has_support():
		_begin_fall()
	_update_mouse_region()
	queue_redraw()


func _sync_bouncy_approach(approach: Dictionary, next_x: float) -> void:
	var hold: Dictionary = approach["hold"]
	var contact_x := Vector2(approach["point"]).x
	var facing: int = approach["facing"]
	var count := bongbong.sprite_frames.get_frame_count(RUN_BOUNCY)
	if _bouncy_approach.is_empty() or _bouncy_approach["id"] != hold["id"] or _bouncy_approach["edge"] != hold["edge"] or absf(float(_bouncy_approach["contact_x"]) - contact_x) > 0.5:
		var start_phase := float(bongbong.frame) + bongbong.frame_progress
		var distance := maxf(0.01, (contact_x - _position_x) * facing)
		var phase_travel := fposmod(float(BOUNCY_ENTRY_POSE) - start_phase, float(count))
		var expected_travel := distance * RUN_BOUNCY_FRAMES.get_animation_speed(RUN_BOUNCY) / LIGHT_RUN_SPEED
		if absf(phase_travel + count - expected_travel) < absf(phase_travel - expected_travel):
			phase_travel += count
		# Do not stretch a nearly completed stride across the whole approach.
		# One more cycle keeps the feet moving through the pose correction.
		if phase_travel < expected_travel * (2.0 / 3.0):
			phase_travel += count
		_bouncy_approach = {"id": hold["id"], "edge": hold["edge"], "contact_x": contact_x,
			"distance": distance, "phase": start_phase, "travel": phase_travel, "natural_travel": expected_travel}
	var remaining := maxf(0.0, (contact_x - next_x) * facing)
	var progress := clampf(1.0 - remaining / float(_bouncy_approach["distance"]), 0.0, 1.0)
	var natural_travel := float(_bouncy_approach["natural_travel"])
	var correction := float(_bouncy_approach["travel"]) - natural_travel
	# Apply pose alignment gradually. Its correction has zero slope at both
	# ends, so entering distance control no longer changes the cadence at once.
	var phase := float(_bouncy_approach["phase"]) + natural_travel * progress + correction * smoothstep(0.0, 1.0, progress)
	# Drive the last steps by traveled distance. Contact lands on the exact
	# source pose of the new reach, regardless of the run's arrival phase.
	bongbong.pause()
	bongbong.set_frame_and_progress(posmod(int(floorf(phase)), count), fposmod(phase, 1.0))


func _clear_bouncy_approach() -> void:
	if _bouncy_approach.is_empty():
		return
	_bouncy_approach.clear()
	if bongbong.animation == RUN_BOUNCY:
		bongbong.play(RUN_BOUNCY)


func _begin_sitting() -> bool:
	if _sitting or bongbong.animation != IDLE_DEFAULT or not _has_support():
		return false
	if _platform_surfaces.supporting_window(bongbong.position).is_empty():
		return false
	_sitting = true
	_sit_time_left = _rng.randf_range(SIT_REST_SECONDS.x, SIT_REST_SECONDS.y)
	_sleep_wake_requested = false
	_wander_moving = false
	_requested_idle = &""
	_completed_loops = 0
	bongbong.speed_scale = 1.0
	bongbong.play(SIT_DOWN)
	bongbong.set_frame_and_progress(0, 0.0)
	_set_facing(_facing)
	_update_help()
	return true


func _start_sit_up() -> void:
	if not _sitting or bongbong.animation == SIT_UP:
		return
	_sit_time_left = 0.0
	if bongbong.animation == SIT_SLEEP_ENTER or bongbong.animation == SIT_SLEEP_LOOP:
		_sleep_wake_requested = true
		_start_sit_wake()
		return
	if bongbong.animation == SIT_DOWN or bongbong.animation == SIT_SLEEP_WAKE:
		return
	bongbong.play(SIT_UP)
	bongbong.set_frame_and_progress(0, 0.0)
	_set_facing(_facing)
	_update_help()


func _start_sit_sleep() -> void:
	if not _sitting or bongbong.animation != SIT_REST:
		return
	_sleep_wake_requested = false
	bongbong.play(SIT_SLEEP_ENTER)
	bongbong.set_frame_and_progress(0, 0.0)
	_set_facing(_facing)
	_update_help()


func _start_sit_wake() -> void:
	if not _sitting or (bongbong.animation != SIT_SLEEP_ENTER and bongbong.animation != SIT_SLEEP_LOOP):
		return
	var wake_frame: int
	if bongbong.animation == SIT_SLEEP_ENTER:
		wake_frame = SLEEP_ENTER_WAKE_FRAMES[clampi(bongbong.frame, 0, SLEEP_ENTER_WAKE_FRAMES.size() - 1)]
	else:
		wake_frame = SLEEP_LOOP_WAKE_FRAMES[clampi(bongbong.frame, 0, SLEEP_LOOP_WAKE_FRAMES.size() - 1)]
	bongbong.play(SIT_SLEEP_WAKE)
	bongbong.set_frame_and_progress(wake_frame, 0.0)
	_sleep_wake_requested = false
	_set_facing(_facing)
	queue_redraw()
	_update_help()


func _cancel_sit() -> void:
	if not _sitting:
		return
	_sitting = false
	_sit_time_left = 0.0
	_sleep_wake_requested = false
	_set_facing(_facing)
	queue_redraw()
	_update_help()


func _sit_anchor_y() -> float:
	if not _sitting:
		return FOOT_ANCHOR.y
	if bongbong.animation in [SIT_REST, SIT_SLEEP_ENTER, SIT_SLEEP_LOOP, SIT_SLEEP_WAKE]:
		return SIT_SEAT_ANCHOR_Y
	if bongbong.animation == SIT_DOWN:
		return SIT_DOWN_ANCHOR_Y[clampi(bongbong.frame, 0, SIT_DOWN_ANCHOR_Y.size() - 1)]
	if bongbong.animation == SIT_UP:
		# The feet lift once, then plant while both hands push the body upright.
		if bongbong.frame < 30:
			return SIT_SEAT_ANCHOR_Y
		return 146.0 + 28.0 * smoothstep(30.0, 58.0, float(bongbong.frame))
	return FOOT_ANCHOR.y


func _update_wandering(delta: float) -> void:
	if not _wander_enabled or _left_pressed or _right_pressed:
		return
	# The fixed walking/running shortcuts keep their requested mode until stopped.
	if not _wander_moving and (_auto_walk or _auto_run or _auto_run_bouncy):
		return
	_wander_time_left -= delta
	if _wander_time_left > 0.0:
		return
	if _wander_moving:
		_stop_walking()
		return
	var approach := _find_auto_approach()
	if approach.is_empty() and not _platform_surfaces.supporting_window(bongbong.position).is_empty() and (_system_idle_seconds >= SLEEP_AFTER_NO_INPUT_SECONDS or _rng.randf() < SIT_CHANCE) and _begin_sitting():
		return

	# Usually continue exploring in the same direction; turn inward near an edge.
	var direction := _facing if _rng.randf() < 0.75 else -_facing
	var limits := _walking_limits(true)
	var turn_margin := minf(100.0, (limits.y - limits.x) * 0.25)
	if _position_x < limits.x + turn_margin:
		direction = 1
	elif _position_x > limits.y - turn_margin:
		direction = -1
	if not approach.is_empty():
		direction = int(approach["facing"])
	var roll := _rng.randi_range(1, 100)
	_auto_walk = not approach.is_empty() or roll <= 60
	_auto_run = not _auto_walk and roll <= 80
	_auto_run_bouncy = not _auto_walk and not _auto_run
	_run_pressed = false
	_wander_moving = true
	_wander_time_left = _rng.randf_range(WANDER_MOVE_SECONDS.x, WANDER_MOVE_SECONDS.y)
	if not approach.is_empty():
		var walk_time := absf(Vector2(approach["point"]).x - _position_x) / (WALK_SPEED * MOVEMENT_SCALE)
		_wander_time_left = maxf(_wander_time_left, walk_time + 1.0)
	_begin_walk(direction, not _auto_walk)


func _set_facing(direction: int) -> void:
	_facing = direction
	bongbong.flip_h = direction < 0
	# The source anchor is x=95, not the canvas midpoint. Mirror around that
	# same pixel centre instead of shifting the character by one pixel.
	bongbong.offset = Vector2(-(CANVAS_SIZE.x - 1.0 - FOOT_ANCHOR.x) if bongbong.flip_h else -FOOT_ANCHOR.x, -_sit_anchor_y())
	queue_redraw()


func _is_moving() -> bool:
	return bongbong.animation == WALK or bongbong.animation == RUN_LIGHT or bongbong.animation == RUN_BOUNCY


func _begin_walk(direction: int, running: bool = false) -> void:
	_cancel_sit()
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
	bongbong.speed_scale = MOVEMENT_SCALE if running else WALK_ANIMATION_SCALE
	bongbong.play(animation_name)
	# Keep the relative gait phase when switching between different frame counts.
	if keep_phase:
		var next_count := bongbong.sprite_frames.get_frame_count(animation_name)
		var next_phase := (float(previous_frame) + previous_progress) * float(next_count) / float(previous_count)
		bongbong.set_frame_and_progress(mini(int(floorf(next_phase)), next_count - 1), fposmod(next_phase, 1.0))
	_update_help()


func _stop_walking() -> void:
	_clear_bouncy_approach()
	_wander_moving = false
	_wander_time_left = _rng.randf_range(WANDER_REST_SECONDS.x, WANDER_REST_SECONDS.y)
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
		_press_pending = false
		_end_drag()
		# Other applications must not stop the desktop pet. Only release keyboard
		# movement, since its key-up events may now belong to another window.
		_left_pressed = false
		_right_pressed = false
		_run_pressed = false
		if not (_auto_walk or _auto_run or _auto_run_bouncy) and _is_moving():
			_stop_walking()


func _request_idle(animation_name: StringName) -> void:
	if _sitting:
		_cancel_sit()
		_begin_idle(animation_name)
		return
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
	if _sitting and bongbong.animation == SIT_SLEEP_LOOP:
		if _sleep_wake_requested:
			_start_sit_wake()
		return
	if _dragging or _falling or _landing or _greeting or _sitting or not _side_hold.is_empty() or not _climb_jump.is_empty() or _grapple.active() or _descent.active():
		return
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


func _on_animation_finished() -> void:
	if _sitting:
		if bongbong.animation == SIT_DOWN:
			bongbong.play(SIT_REST)
			bongbong.set_frame_and_progress(0, 0.0)
			_set_facing(_facing)
			_update_help()
			if _sit_time_left <= 0.0:
				_start_sit_up()
			elif _system_idle_seconds >= SLEEP_AFTER_NO_INPUT_SECONDS:
				_start_sit_sleep()
			return
		if bongbong.animation == SIT_SLEEP_ENTER:
			if _sleep_wake_requested or (_system_idle_seconds >= 0.0 and _system_idle_seconds < SLEEP_AFTER_NO_INPUT_SECONDS):
				_start_sit_wake()
				return
			bongbong.play(SIT_SLEEP_LOOP)
			bongbong.set_frame_and_progress(0, 0.0)
			_set_facing(_facing)
			queue_redraw()
			_update_help()
			return
		if bongbong.animation == SIT_SLEEP_WAKE:
			bongbong.play(SIT_REST)
			bongbong.set_frame_and_progress(0, 0.0)
			_start_sit_up()
			return
		if bongbong.animation == SIT_UP:
			_cancel_sit()
			_begin_idle(IDLE_DEFAULT)
			return
	if _descent.active():
		_descent.animation_finished()
		return
	if _reaching_wall and bongbong.animation in [CLIMB_ENTRY, CLIMB_BOUNCY_ENTRY]:
		if not _sync_side_hold():
			_begin_fall()
			return
		_reaching_wall = false
		bongbong.play(SIDE_HOLD)
		bongbong.set_frame_and_progress(0, 0.0)
		bongbong.pause()
		_update_help()
	elif _pulling_up and bongbong.animation == PULL_UP:
		if not _sync_pull_up(true):
			_begin_fall()
			return
		_clear_side_motion()
		_begin_idle(IDLE_DEFAULT)
		_update_mouse_region()
	elif _falling and bongbong.animation == FALL_INTRO:
		bongbong.play(FALL_AIR)
		bongbong.set_frame_and_progress(0, 0.0)
		_update_help()
	elif _landing and bongbong.animation in [LAND_LOW, LAND_HIGH]:
		_landing = false
		_begin_idle(IDLE_DEFAULT)
	elif _greeting and bongbong.animation == GREET_WAVE:
		_greeting = false
		_begin_idle(IDLE_DEFAULT)


func _choose_idle() -> StringName:
	var roll := _rng.randi_range(1, DEFAULT_WEIGHT + POCKETS_WEIGHT + ARMS_CROSSED_WEIGHT)
	if roll <= DEFAULT_WEIGHT:
		return IDLE_DEFAULT
	if roll <= DEFAULT_WEIGHT + POCKETS_WEIGHT:
		return IDLE_POCKETS
	return IDLE_ARMS_CROSSED


func _begin_idle(animation_name: StringName, bridge_loops: int = 0) -> void:
	_cancel_sit()
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
	if platform_demo:
		help_label.text = "창 위 착지 테스트 · 1단계\n봉봉이를 초록색 선 위로 들어 올린 뒤 놓아 보세요.\n← / →: 직접 걷기    R: 자동 이동 켜기/끄기    Space: 멈춤\n발판 끝을 직접 걸어 나가면 아래로 떨어집니다.    Esc: 종료"
		return
	var mode := "Drag" if _dragging else ("Bouncy run" if bongbong.animation == RUN_BOUNCY else ("Light run" if bongbong.animation == RUN_LIGHT else ("Walk" if bongbong.animation == WALK else "Idle")))
	if _descent.active():
		mode = "Descend: " + str(_descent.state["phase"])
	elif _grapple.active():
		mode = "Grapple: " + str(_grapple.state["phase"])
	elif not _climb_jump.is_empty():
		mode = "Jump to wall"
	elif _falling:
		mode = "Fall"
	elif _landing:
		mode = "Land"
	elif _greeting:
		mode = "Greeting"
	elif _sitting:
		mode = "Window sleep" if bongbong.animation in [SIT_SLEEP_ENTER, SIT_SLEEP_LOOP, SIT_SLEEP_WAKE] else "Window rest"
	elif not _side_hold.is_empty():
		mode = "Reach for wall" if _reaching_wall else ("Pull up" if _pulling_up else ("Climb" if _climbing else "Side hold"))
	if _auto_walk or _auto_run or _auto_run_bouncy:
		mode = "Auto " + mode.to_lower()
	help_label.text = "%s | Facing: %s\n1: Default    2: Pockets    3: Arms crossed\nLeft/Right: Walk    Shift + Left/Right: Light run\n4: Auto walk    5: Auto light run    6: Auto bouncy run\nR: Random roaming on/off    Space: Pause roaming    D: Climb down\nMouse: Click to wave, drag to lift and release to test Fall" % [mode, "Left" if _facing < 0 else "Right"]
	help_label.text += "\nF1: Test view    Esc: Quit"
	if not _side_hold.is_empty():
		help_label.text += "\nHolding window edge: drag to move, Space to let go"
	help_label.text += "\nRandom roaming: %s" % ("On" if _wander_enabled else "Paused")
	if _windows_provider != null:
		help_label.text += "\nWindow platforms: %d" % _platform_surfaces.rectangles.size()
	help_label.text += "\nCurrent: %s | Loops: %d / %s" % [bongbong.animation, _completed_loops, "until floor" if _falling else ("once" if _landing or _greeting else ("infinite" if _is_moving() or _dragging else str(_target_loops)))]
	if _requested_idle != &"":
		var next := String(_requested_idle)
		if not _is_moving() and bongbong.animation != IDLE_DEFAULT and _requested_idle != IDLE_DEFAULT and bongbong.animation != _requested_idle:
			next = "idle_default (1 loop) -> " + next
		help_label.text += "\nNext: %s [queued]" % next
	elif not _is_moving() and bongbong.animation != IDLE_DEFAULT and _side_hold.is_empty():
		help_label.text += "\nNext: idle_default"
