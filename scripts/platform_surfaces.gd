extends RefCounted

# All rectangles use the pet viewport's coordinates.
var rectangles: Array[Rect2] = []
var windows: Array = []


func set_rectangles(value: Array[Rect2]) -> void:
	windows.clear()
	rectangles.clear()
	for rectangle in value:
		if rectangle.has_area():
			rectangles.append(rectangle)


func set_windows(value: Array) -> void:
	windows = value.duplicate(true)
	rectangles.clear()
	for window in windows:
		for surface in window["surfaces"]:
			rectangles.append(surface)


func supporting_window(foot: Vector2) -> Dictionary:
	for window in windows:
		if window_supports(window, foot):
			return window
	return {}


func side_grab_at(foot: Vector2, grip_offset: Vector2, reach: float, hand_margin: float) -> Dictionary:
	var nearest: Dictionary = {}
	var distance := reach + 0.001
	for window in windows:
		for side in window.get("sides", []):
			var facing := 1 if side["edge"] == "left" else -1
			# Approach from outside the window; never grab through its interior.
			if (foot.x - float(side["x"])) * facing > 0.0:
				continue
			var hand := foot + Vector2(grip_offset.x * facing, grip_offset.y)
			var span: Vector2 = side["span"]
			var gap := absf(hand.x - float(side["x"]))
			if gap >= distance or hand.y - hand_margin < span.x - 0.01 or hand.y + hand_margin > span.y + 0.01:
				continue
			distance = gap
			var bounds: Rect2 = window["bounds"]
			nearest = {"id": window["id"], "edge": side["edge"], "height": hand.y - bounds.position.y}
	return nearest


func side_grip(hold: Dictionary, hand_margin: float) -> Dictionary:
	for window in windows:
		if window["id"] != hold.get("id"):
			continue
		var bounds: Rect2 = window["bounds"]
		if bounds.size.y < hand_margin * 2.0:
			return {}
		var hand_y := clampf(bounds.position.y + float(hold["height"]), bounds.position.y + hand_margin, bounds.end.y - hand_margin)
		for side in window.get("sides", []):
			var span: Vector2 = side["span"]
			if side["edge"] == hold["edge"] and hand_y - hand_margin >= span.x - 0.01 and hand_y + hand_margin <= span.y + 0.01:
				return {"point": Vector2(float(side["x"]), hand_y), "facing": 1 if side["edge"] == "left" else -1}
		return {}
	return {}


func climb_approaches(foot: Vector2, grip_offset: Vector2, hand_margin: float, max_rise: float = 0.0) -> Array:
	var result: Array = []
	var hand_y := foot.y + grip_offset.y
	for window in windows:
		var bounds: Rect2 = window["bounds"]
		for side in window.get("sides", []):
			var facing := 1 if side["edge"] == "left" else -1
			var edge_x := float(side["x"])
			var span: Vector2 = side["span"]
			if (foot.x - edge_x) * facing > 0.0:
				continue
			# An autonomous climb needs a continuous exposed route to the corner.
			# A small hop may reach the bottom of a floating, exposed side.
			var rise := maxf(0.0, hand_y + hand_margin - span.y)
			var grip_y := hand_y - rise
			if span.x > bounds.position.y + 0.01 or grip_y - hand_margin < span.x - 0.01 or rise > max_rise + 0.01:
				continue
			result.append({
				"hold": {"id": window["id"], "edge": side["edge"], "height": grip_y - bounds.position.y},
				"point": Vector2(edge_x - grip_offset.x * facing, foot.y),
				"facing": facing,
				"rise": rise,
			})
	return result


func climb_height(hold: Dictionary, rise: float, hand_margin: float) -> float:
	# Clamp travel to the *current* visible side segment, including a long frame.
	# This prevents climbing through a narrow occluder into a separate segment.
	var grip := side_grip(hold, hand_margin)
	if grip.is_empty():
		return float(hold["height"])
	for window in windows:
		if window["id"] != hold["id"]:
			continue
		var bounds: Rect2 = window["bounds"]
		var hand: Vector2 = grip["point"]
		for side in window.get("sides", []):
			var span: Vector2 = side["span"]
			# Vector2 stores the contact in float32; allow rounding at the exact
			# bottom margin so a freshly caught floating side can start climbing.
			if side["edge"] == hold["edge"] and hand.y - hand_margin >= span.x - 0.01 and hand.y + hand_margin <= span.y + 0.01:
				return maxf(span.x + hand_margin, hand.y - rise) - bounds.position.y
	return float(hold["height"])


func descend_height(hold: Dictionary, distance: float, hand_margin: float) -> Dictionary:
	var grip := side_grip(hold, hand_margin)
	if grip.is_empty():
		return {}
	for window in windows:
		if window["id"] != hold.get("id"):
			continue
		var bounds: Rect2 = window["bounds"]
		var hand: Vector2 = grip["point"]
		for side in window.get("sides", []):
			var span: Vector2 = side["span"]
			if side["edge"] == hold["edge"] and hand.y - hand_margin >= span.x - 0.01 and hand.y + hand_margin <= span.y + 0.01:
				return {"height": minf(span.y - hand_margin, hand.y + distance) - bounds.position.y,
					"at_bottom": absf(span.y - bounds.end.y) <= 0.01}
	return {}


func pull_up_target(hold: Dictionary, inset: float) -> Dictionary:
	for window in windows:
		if window["id"] != hold.get("id"):
			continue
		var bounds: Rect2 = window["bounds"]
		var facing := 1 if hold["edge"] == "left" else -1
		var edge_x := bounds.position.x if facing > 0 else bounds.end.x
		var target := Vector2(edge_x + facing * minf(inset, bounds.size.x * 0.25), bounds.position.y)
		# Both the corner and the landing point must share an uncovered top.
		for surface in window.get("surfaces", []):
			var corner_x := edge_x + facing * 0.5
			if corner_x >= surface.position.x and corner_x < surface.end.x and target.x >= surface.position.x and target.x < surface.end.x:
				return {"point": target, "corner": Vector2(edge_x, bounds.position.y), "facing": facing}
	return {}


static func window_supports(window: Dictionary, foot: Vector2) -> bool:
	for surface in window.get("surfaces", []):
		if foot.x >= surface.position.x and foot.x < surface.end.x and absf(foot.y - surface.position.y) <= 0.5:
			return true
	return false


func landing_height(x: float, previous_y: float, next_y: float, desktop_floor: float) -> float:
	var result := desktop_floor
	for rectangle in rectangles:
		if x < rectangle.position.x or x >= rectangle.end.x:
			continue
		var top := rectangle.position.y
		# Only land when crossing a top from above, including a fast single step.
		if previous_y <= top and next_y >= top:
			result = minf(result, top)
	return result


func support_at(foot: Vector2) -> Rect2:
	for rectangle in rectangles:
		if foot.x >= rectangle.position.x and foot.x < rectangle.end.x and absf(foot.y - rectangle.position.y) <= 0.5:
			return rectangle
	return Rect2()
