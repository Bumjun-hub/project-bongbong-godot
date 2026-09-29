extends Node2D

# The rope follows the authored hands; its length belongs to the window route.
const MAX_RISE := 640.0
const MAX_ROPE := 900.0
const STANDOFF := 70.0
const PREPARE_TIME := 0.38
const TENSION_TIME := 0.14
const CATCH_TIME := 0.20
const PULL_SPEED := 230.0
const HANG_VARIATION := 72.0

var pet: Node2D
var motion: Script
var state: Dictionary = {}


func active() -> bool:
	return not state.is_empty()


func find_approach(direction: int, reach: float) -> Dictionary:
	if not pet.auto_climb_enabled or pet._auto_climb_cooldown > 0.0:
		return {}
	var offset: Vector2 = (pet.SIDE_HAND_ANCHOR-pet.FOOT_ANCHOR)*pet.CHARACTER_SCALE
	var foot := Vector2(pet._position_x,pet.bongbong.position.y)
	var limits: Vector2 = pet._walking_limits(true)
	limits = Vector2(minf(limits.x,foot.x),maxf(limits.y,foot.x))
	var nearest: Dictionary = {}
	var nearest_distance := reach+0.01
	for approach in pet._platform_surfaces.climb_approaches(foot,offset,pet.SIDE_HAND_MARGIN*pet.CHARACTER_SCALE,MAX_RISE):
		if float(approach["rise"]) <= pet.CLIMB_JUMP_MAX_RISE+0.01:
			continue
		var facing: int = approach["facing"]
		if direction != 0 and direction != facing:
			continue
		var catch_point: Vector2 = approach["point"]-Vector2(0,float(approach["rise"]))
		var point: Vector2 = approach["point"]
		point.x -= facing*minf(STANDOFF,maxf(0,(point.x-foot.x)*facing))
		var distance := (point.x-foot.x)*facing
		if distance < -0.01 or distance > nearest_distance or point.x < limits.x or point.x > limits.y:
			continue
		var top: Dictionary = pet._platform_surfaces.pull_up_target(approach["hold"],pet.TOP_INSET)
		if top.is_empty() or not pet._position_fits(top["point"]) or not pet._position_fits(catch_point) or not pet._position_fits(point,true):
			continue
		# Catch on an exposed part of the side, with a different hand height
		# for each launch. The rope and final side hold share this point.
		var hold: Dictionary = approach["hold"].duplicate()
		var margin: float = pet.SIDE_HAND_MARGIN * pet.CHARACTER_SCALE
		var max_extra := minf(HANG_VARIATION, MAX_RISE - float(approach["rise"]))
		for window in pet._platform_surfaces.windows:
			if window["id"] != hold["id"]:
				continue
			for side in window.get("sides", []):
				if side["edge"] == hold["edge"] and absf(float(side["x"]) - float(top["corner"].x)) < 0.75:
					var base_y: float = window["bounds"].position.y + float(hold["height"])
					max_extra = minf(max_extra, base_y - float(side["span"].x) - margin)
		var extra: float = pet._rng.randf_range(0.25, 1.0) * maxf(0.0, max_extra)
		hold["height"] = float(hold["height"]) - extra
		catch_point.y -= extra
		var grip: Dictionary = pet._platform_surfaces.side_grip(hold, margin)
		if grip.is_empty() or not pet._position_fits(catch_point):
			continue
		var anchor: Vector2 = grip["point"]
		if point.distance_to(anchor)>MAX_ROPE or not clear_route(approach["hold"],point,catch_point,anchor):
			continue
		approach["hold"] = hold
		approach["point"] = point
		approach["catch_point"] = catch_point
		approach["anchor"] = anchor
		approach["grapple"] = true
		nearest = approach
		nearest_distance = distance
	return nearest


func clear_route(hold: Dictionary, start: Vector2, target: Vector2, anchor: Vector2) -> bool:
	var facing := 1 if hold["edge"] == "left" else -1
	var hand := start+Vector2(36*facing,-45)
	for window in pet._platform_surfaces.windows:
		if window["id"] != hold["id"]:
			continue
		for bounds: Rect2 in window.get("blockers",[]):
			if crosses_rect(hand,anchor,bounds.grow(-1)):
				return false
			# Check the body's swept route, not only whether the end is visible.
			if crosses_rect(start-Vector2(0,62),target-Vector2(0,62),bounds.grow(18)):
				return false
		return true
	return false


static func crosses_rect(a: Vector2,b: Vector2,rect: Rect2) -> bool:
	if not rect.has_area():
		return false
	if rect.has_point(a) or rect.has_point(b):
		return true
	var corners := [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(a,b,corners[i],corners[(i+1)%4]) != null:
			return true
	return false


func begin(approach: Dictionary) -> bool:
	if not pet._has_support() or motion == null:
		return false
	var start: Vector2 = approach["point"]
	var target: Vector2 = approach["catch_point"]
	var anchor: Vector2 = approach["anchor"]
	pet._stop_walking()
	pet._set_facing(int(approach["facing"]))
	pet.bongbong.position = start.round()
	pet._position_x = start.x
	pet._fall_position_y = start.y
	pet._falling = false
	pet._landing = false
	pet._greeting = false
	pet._requested_idle = &""
	state = {"phase":"prepare","elapsed":0.0,"airborne":false,"start":start,"target":target,
		"hold":approach["hold"].duplicate(),"anchor":anchor,"velocity":Vector2.ZERO,
		"shot_time":clampf(start.distance_to(anchor)/950.0,0.20,0.65),
		"pull_time":clampf(start.distance_to(target)/PULL_SPEED,0.65,2.8)}
	pet.bongbong.speed_scale=1.0
	pet.bongbong.play(motion.ANIMATION)
	pet.bongbong.set_frame_and_progress(0,0.0)
	pet.bongbong.pause()
	refresh()
	pet._update_help()
	return true


func target_valid() -> bool:
	if not active() or (not state["airborne"] and not pet._has_support()):
		return false
	var hold: Dictionary=state["hold"]
	var grip: Dictionary=pet._platform_surfaces.side_grip(hold,pet.SIDE_HAND_MARGIN*pet.CHARACTER_SCALE)
	var top: Dictionary=pet._platform_surfaces.pull_up_target(hold,pet.TOP_INSET)
	if grip.is_empty() or top.is_empty() or not pet._position_fits(top["point"]):
		return false
	var offset: Vector2=(pet.SIDE_HAND_ANCHOR-pet.FOOT_ANCHOR)*pet.CHARACTER_SCALE
	var target: Vector2=grip["point"]-Vector2(offset.x*int(grip["facing"]),offset.y)
	# A fixed cable cannot silently warp onto a relocated/resized window.
	if target.distance_to(state["target"])>0.75 or Vector2(grip["point"]).distance_to(state["anchor"])>0.75:
		return false
	var route_exists:=false
	for route in pet._platform_surfaces.climb_approaches(state["start"],offset,pet.SIDE_HAND_MARGIN*pet.CHARACTER_SCALE,MAX_RISE):
		if route["hold"]["id"]==hold["id"] and route["hold"]["edge"]==hold["edge"] and float(route["hold"]["height"]) + 0.75 >= float(hold["height"]):
			route_exists=true
	return route_exists and clear_route(hold,state["start"],state["target"],state["anchor"])


func advance(delta: float) -> void:
	if not target_valid():
		abort()
		return
	# Consume complete phases so even one late frame cannot overshoot contact.
	while active() and delta>0.000001:
		var phase: String=state["phase"]
		var duration: float=phase_duration(phase)
		var used:=minf(delta,maxf(0.0,duration-float(state["elapsed"])))
		state["elapsed"]=minf(duration,float(state["elapsed"])+used)
		delta-=used
		var t:=float(state["elapsed"])/duration
		match phase:
			"prepare": set_pose(t*motion.AIM_FRAME)
			"shoot": set_pose(motion.AIM_FRAME)
			"tension": set_pose(lerpf(motion.AIM_FRAME,motion.HANG_FRAME,t))
			"pull":
				var start: Vector2=state["start"]
				var target: Vector2=state["target"]
				var eased:=smoothstep(0,1,t)
				var position:=start.lerp(target,eased)
				state["velocity"]=(target-start)*(6*t*(1-t)/duration)
				pet._position_x=position.x
				pet._fall_position_y=position.y
				pet.bongbong.position=position.round()
				set_pose(motion.HANG_FRAME)
			"catch": set_pose(lerpf(motion.HANG_FRAME,motion.LAST_FRAME,t))
		if t>=1.0:
			state["elapsed"]=0.0
			match phase:
				"prepare": state["phase"]="shoot"
				"shoot": state["phase"]="tension"
				"tension":
					state["phase"]="pull"
					state["airborne"]=true
				"pull": state["phase"]="catch"
				"catch":
					var hold: Dictionary=state["hold"].duplicate()
					clear()
					if pet._begin_side_hold(hold):
						pet._climb_delay=pet.CLIMB_ENTRY_SETTLE
					else:
						pet._begin_fall()
			if active():
				pet._update_help()
	refresh()


func phase_duration(phase: String) -> float:
	match phase:
		"prepare": return PREPARE_TIME
		"shoot": return float(state["shot_time"])
		"tension": return TENSION_TIME
		"pull": return float(state["pull_time"])
	return CATCH_TIME


func set_pose(value: float) -> void:
	var frame:=clampi(int(value),0,motion.LAST_FRAME)
	pet.bongbong.set_frame_and_progress(frame,fposmod(value,1.0))


func abort() -> void:
	if not active():
		return
	var airborne: bool=state["airborne"]
	var velocity: Vector2=state["velocity"]
	var height: float=pet._fall_position_y
	pet._clear_side_motion()
	pet._stop_walking()
	if not airborne and pet._has_support():
		pet._begin_idle(pet.IDLE_DEFAULT)
	else:
		pet._begin_fall()
		pet._fall_position_y=height
		pet._fall_velocity=velocity.y if airborne else 0.0
	refresh()


func clear() -> void:
	state.clear()
	pet._last_mouse_region=Rect2()
	queue_redraw()


func refresh() -> void:
	queue_redraw()
	pet._update_mouse_region()


func hand_point() -> Vector2:
	var point: Vector2=motion.HAND_POINTS[pet.bongbong.frame]
	point-=pet.FOOT_ANCHOR
	point.x*=pet._facing
	return pet.bongbong.position+point*pet.CHARACTER_SCALE


func rope_tip() -> Vector2:
	var anchor: Vector2=state["anchor"]
	if state["phase"]=="shoot":
		return hand_point().lerp(anchor,float(state["elapsed"])/float(state["shot_time"]))
	return anchor


func rope_visible() -> bool:
	return active() and state["phase"]!="prepare"


func interaction_polygon(region: Rect2) -> PackedVector2Array:
	var polygon:=PackedVector2Array([region.position,Vector2(region.end.x,region.position.y),region.end,Vector2(region.position.x,region.end.y)])
	if not rope_visible():
		return polygon
	var start:=hand_point()
	var tip:=rope_tip()
	var direction:=(tip-start).normalized()
	if direction.is_zero_approx():
		return polygon
	var normal:=direction.orthogonal()*7.0
	var corridor:=PackedVector2Array([start-normal,tip+direction*9-normal,tip+direction*9+normal,start+normal])
	var merged:=Geometry2D.merge_polygons(polygon,corridor)
	# The hand always lies inside the character region, yielding one narrow union.
	return merged[0] if merged.size()==1 else polygon


func _draw() -> void:
	if not active():
		return
	var hand:=hand_point()
	var anchor: Vector2=state["anchor"]
	var direction:=(anchor-hand).normalized()
	var normal:=direction.orthogonal()
	if rope_visible():
		var tip:=rope_tip()
		draw_line(hand,tip,Color("17202d"),3.0,true)
		draw_line(hand,tip,Color("c7d7e6"),1.3,true)
		# Compact three-prong hook, oriented along the shot/cable.
		draw_line(tip-direction*8,tip+direction*2,Color("162332"),4.0,true)
		for side in [-1,1]:
			var prong: Vector2=tip-direction*4+normal*side*6
			draw_polyline(PackedVector2Array([tip+direction*2,prong,prong-direction*3]),Color("17202d"),3.3,true)
			draw_polyline(PackedVector2Array([tip+direction*2,prong,prong-direction*3]),Color("d9e7ef"),1.5,true)
		if state["phase"]=="tension":
			var t:=float(state["elapsed"])/TENSION_TIME
			draw_arc(tip,4+5*t,0,TAU,12,Color(1.0,0.83,0.35,1.0-t),1.5,true)
	# The small launcher appears as the hands reach the aiming position.
	var reveal:=clampf(float(pet.bongbong.frame)/maxf(1,motion.AIM_FRAME),0,1)
	if reveal>0.6 and state["phase"]!="catch":
		var barrel:=PackedVector2Array([hand-normal*3-direction*3,hand-normal*3+direction*8,hand+normal*3+direction*8,hand+normal*3-direction*3])
		draw_colored_polygon(barrel,Color("35495d"))
		draw_polyline(PackedVector2Array([barrel[0],barrel[1],barrel[2],barrel[3],barrel[0]]),Color("131e2d"),1.5,true)
		draw_line(hand+direction*3-normal*2,hand+direction*7-normal*2,Color("81c6d6"),1.5,true)
