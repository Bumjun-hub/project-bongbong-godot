extends RefCounted

const SPEED := 140.0
const SLIDE_ACCELERATION := 420.0
const LOWER_RATE := 1.15
const DUST_SPACING := 14.0
const DUST_LIFETIME := 0.32
const SHOE_CONTACT_Y := 133.0
var pet: Node2D
var motion
var dust_renderer: Node2D
var state: Dictionary = {}
var dust: Array[Dictionary] = []
var _dust_distance := 0.0
var _dust_sequence := 0


func active() -> bool:
	return not state.is_empty()


func _down_grip(hold: Dictionary, margin: float) -> Dictionary:
	var grip: Dictionary = pet._platform_surfaces.side_grip(hold, margin)
	if grip.is_empty():
		return {}
	for window in pet._platform_surfaces.windows:
		if window["id"] == hold["id"]:
			var bounds: Rect2 = window["bounds"]
			if absf(Vector2(grip["point"]).y - bounds.position.y - float(hold["height"])) > 0.5:
				# A shortened side must release the pet rather than snap its grip.
				return {}
	return grip


func clear() -> void:
	state.clear()
	dust.clear()
	_dust_distance = 0.0
	if pet != null:
		pet.queue_redraw()
	if dust_renderer != null:
		dust_renderer.queue_redraw()


func advance_dust(delta: float) -> void:
	if dust.is_empty():
		return
	for index in range(dust.size() - 1, -1, -1):
		var puff: Dictionary = dust[index]
		puff["age"] += delta
		if float(puff["age"]) >= DUST_LIFETIME:
			dust.remove_at(index)
		else:
			puff["position"] += Vector2(puff["velocity"]) * delta
	pet.queue_redraw()
	if dust_renderer != null:
		dust_renderer.queue_redraw()


func _emit_dust(distance: float, facing: int, wall_x: float) -> void:
	_dust_distance += distance
	while _dust_distance >= DUST_SPACING:
		_dust_distance -= DUST_SPACING
		# Friction comes from the raised sole pressed against the wall.
		var contact := Vector2(wall_x, pet.bongbong.position.y + (SHOE_CONTACT_Y - pet.FOOT_ANCHOR.y) * pet.CHARACTER_SCALE)
		var point := contact + Vector2(-facing * 1.5, -1.0)
		dust.append({"origin": contact, "position": point, "velocity": Vector2(-facing * (16.0 + (_dust_sequence % 3) * 4.0), -24.0),
			"age": 0.0, "facing": facing})
		_dust_sequence += 1
		if dust.size() > 10:
			dust.pop_front()
	if dust_renderer != null:
		dust_renderer.queue_redraw()


func draw_dust(canvas: Node2D) -> void:
	for puff in dust:
		var progress: float = float(puff["age"]) / DUST_LIFETIME
		var color := Color(0.72, 0.75, 0.80, 0.82 * pow(1.0 - progress, 1.4))
		var point: Vector2 = (Vector2(puff["position"]) + Vector2(int(puff["facing"]) * 1.5, 0.0)).round()
		var size := roundf(4.0 + progress * 4.0)
		var outward := -int(puff["facing"])
		# Clustered pixel lobes form a small cloud entirely above the contact.
		canvas.draw_rect(Rect2(point + Vector2(-size * 0.5, -size).round(), Vector2(size, size * 0.75).round()), color)
		canvas.draw_rect(Rect2(point + Vector2(outward * size * 0.65 - 1.0, -size * 1.35).round(), Vector2.ONE * roundf(size * 0.65)), color)
		canvas.draw_rect(Rect2(point + Vector2(outward * (size + 2.0), -size * 1.7).round(), Vector2.ONE * 2.0), color)


func target_for(direction: int) -> Dictionary:
	var support: Dictionary = pet._platform_surfaces.supporting_window(pet.bongbong.position)
	if support.is_empty():
		return {}
	return _target({"id": support["id"], "edge": "left" if direction < 0 else "right"})


func _target(hold: Dictionary) -> Dictionary:
	var margin: float = pet.SIDE_HAND_MARGIN * pet.CHARACTER_SCALE
	for window in pet._platform_surfaces.windows:
		if window["id"] != hold.get("id"):
			continue
		var bounds: Rect2 = window["bounds"]
		var facing := 1 if hold["edge"] == "left" else -1
		var corner := Vector2(bounds.position.x if facing > 0 else bounds.end.x, bounds.position.y)
		var point := corner + Vector2(facing * minf(pet.TOP_INSET, bounds.size.x * 0.25), 0)
		var exposed_top := false
		for surface in window["surfaces"]:
			if surface.has_point(Vector2(corner.x + facing * 0.5, corner.y)) and surface.has_point(point):
				exposed_top = true
		if not exposed_top or not pet._position_fits(point):
			return {}
		for side in window.get("sides", []):
			var span: Vector2 = side["span"]
			if side["edge"] != hold["edge"] or span.x > corner.y + 0.01 or span.y < corner.y + margin * 2.0:
				continue
			var hanging: Vector2 = corner + Vector2(-44 * facing, 76) * pet.CHARACTER_SCALE
			if not pet._position_fits(hanging, true):
				return {}
			return {"hold": {"id": hold["id"], "edge": hold["edge"], "height": margin},
				"corner": corner, "point": point, "facing": facing}
	return {}


func request() -> bool:
	if active() or pet._dragging or pet._falling or pet._landing or not pet._side_hold.is_empty() or not pet._climb_jump.is_empty() or pet._grapple.active():
		return false
	var left := target_for(-1)
	var right := target_for(1)
	var target := left if right.is_empty() else right
	if not left.is_empty() and not right.is_empty():
		target = left if absf(pet.bongbong.position.x - Vector2(left["point"]).x) <= absf(pet.bongbong.position.x - Vector2(right["point"]).x) else right
	if target.is_empty():
		return false
	pet._stop_walking()
	pet._greeting = false
	state = {"phase": "approach", "hold": target["hold"].duplicate(), "corner": target["corner"]}
	return true


func begin(target: Dictionary) -> bool:
	if target.is_empty():
		return false
	var current := _target(target["hold"])
	if current.is_empty() or absf(pet.bongbong.position.y - Vector2(current["point"]).y) > 0.5:
		return false
	pet._stop_walking()
	pet._greeting = false
	pet._requested_idle = &""
	state = {"phase": "lower", "hold": current["hold"].duplicate(),
		"start_offset": pet.bongbong.position - Vector2(current["corner"])}
	pet._set_facing(int(current["facing"]))
	pet.bongbong.speed_scale = LOWER_RATE
	pet.bongbong.play(motion.LOWER)
	pet.bongbong.set_frame_and_progress(0, 0.0)
	refresh()
	pet._update_help()
	return true


func advance(delta: float) -> void:
	if state["phase"] == "approach":
		var target := _target(state["hold"])
		if target.is_empty() or not pet._has_support():
			abort()
			return
		var destination: Vector2 = target["point"]
		var direction := -int(target["facing"])
		pet._begin_walk(direction)
		var position: Vector2 = pet.bongbong.position
		position.x = move_toward(position.x, destination.x, pet.WALK_SPEED * pet.MOVEMENT_SCALE * delta)
		set_position(position)
		if absf(position.x - destination.x) < 0.5:
			begin(target)
	elif state["phase"] == "lower":
		refresh()
	else:
		var hold: Dictionary = state["hold"]
		var margin: float = pet.SIDE_HAND_MARGIN * pet.CHARACTER_SCALE
		var grip := _down_grip(hold, margin)
		if grip.is_empty():
			abort()
			return
		# Keep both hands against the wall and glide without climbing steps.
		var velocity: float = state.get("velocity", 0.0)
		var accelerating := minf(delta, (SPEED - velocity) / SLIDE_ACCELERATION)
		var travel := velocity * accelerating + 0.5 * SLIDE_ACCELERATION * accelerating * accelerating + SPEED * (delta - accelerating)
		state["velocity"] = minf(SPEED, velocity + SLIDE_ACCELERATION * delta)
		var before: float = hold["height"]
		var info: Dictionary = pet._platform_surfaces.descend_height(hold, travel, margin)
		if info.is_empty():
			abort()
			return
		hold["height"] = info["height"]
		var next_grip := _down_grip(hold, margin)
		if next_grip.is_empty():
			abort()
			return
		var offset: Vector2 = (pet.SIDE_HAND_ANCHOR - pet.FOOT_ANCHOR) * pet.CHARACTER_SCALE
		var next: Vector2 = Vector2(next_grip["point"]) - Vector2(offset.x * int(next_grip["facing"]), offset.y)
		var landing: float = pet._platform_surfaces.landing_height(next.x, pet.bongbong.position.y, next.y, pet._floor_y)
		if next.y >= landing:
			set_position(Vector2(next.x, landing))
			finish_on_ground()
			return
		if not refresh():
			return
		if is_equal_approx(before, float(hold["height"])):
			if info["at_bottom"]:
				abort()
			else:
				state["velocity"] = 0.0
				pet.bongbong.pause()
		else:
			pet.bongbong.play(motion.DOWN)
			_emit_dust(float(hold["height"]) - before, int(next_grip["facing"]), Vector2(next_grip["point"]).x)
	pet._update_mouse_region()
	pet.queue_redraw()


func refresh() -> bool:
	if state.is_empty():
		return false
	if state["phase"] == "approach":
		var target := _target(state["hold"])
		if target.is_empty():
			abort()
			return false
		var corner: Vector2 = target["corner"]
		var position: Vector2 = pet.bongbong.position + corner - Vector2(state["corner"])
		if not pet._position_fits(position) or not pet._platform_surfaces.support_at(position).has_area():
			abort()
			return false
		state["corner"] = corner
		set_position(position)
		return true
	if state["phase"] == "lower":
		var target := _target(state["hold"])
		if target.is_empty():
			abort()
			return false
		var index: int = pet.bongbong.frame
		var progress := float(index) / float(motion.ROOT_OFFSETS.size() - 1)
		var mirror := Vector2(int(target["facing"]), 1)
		var offset: Vector2 = motion.ROOT_OFFSETS[index] * mirror * pet.CHARACTER_SCALE
		var first: Vector2 = motion.ROOT_OFFSETS[0] * mirror * pet.CHARACTER_SCALE
		offset += (Vector2(state["start_offset"]) - first) * (1.0 - smoothstep(0.0, 0.18, progress))
		var position: Vector2 = Vector2(target["corner"]) + offset
		if not pet._position_fits(position, true):
			abort()
			return false
		set_position(position)
	else:
		var grip := _down_grip(state["hold"], pet.SIDE_HAND_MARGIN * pet.CHARACTER_SCALE)
		if grip.is_empty():
			abort()
			return false
		var offset: Vector2 = (pet.SIDE_HAND_ANCHOR - pet.FOOT_ANCHOR) * pet.CHARACTER_SCALE
		var position: Vector2 = Vector2(grip["point"]) - Vector2(offset.x * int(grip["facing"]), offset.y)
		if position.y >= pet._floor_y:
			set_position(Vector2(position.x, pet._floor_y))
			finish_on_ground()
			return false
		if not pet._position_fits(position, true):
			abort()
			return false
		set_position(position)
	return true


func animation_finished() -> void:
	if not active() or state["phase"] != "lower" or pet.bongbong.animation != motion.LOWER:
		return
	state["phase"] = "down"
	state["velocity"] = 0.0
	_dust_distance = 0.0
	pet.bongbong.speed_scale = 1.0
	pet.bongbong.play(motion.DOWN)
	pet.bongbong.set_frame_and_progress(0, 0.0)
	refresh()
	pet._update_help()


func set_position(position: Vector2) -> void:
	pet.bongbong.position = position.round()
	pet._position_x = position.x
	pet._fall_position_y = position.y


func finish_on_ground() -> void:
	state.clear()
	pet._auto_climb_cooldown = pet.AUTO_CLIMB_COOLDOWN
	pet._begin_idle(pet.IDLE_DEFAULT)
	pet._wander_time_left = pet._rng.randf_range(pet.WANDER_REST_SECONDS.x, pet.WANDER_REST_SECONDS.y)
	pet._update_mouse_region()


func abort() -> void:
	var airborne: bool = state.get("phase", "approach") != "approach"
	var release_velocity: float = state.get("velocity", 0.0)
	clear()
	pet._auto_climb_cooldown = pet.AUTO_CLIMB_COOLDOWN
	if airborne or not pet._has_support():
		pet._begin_fall()
		pet._fall_velocity = release_velocity
	else:
		pet._stop_walking()
		pet._begin_idle(pet.IDLE_DEFAULT)
