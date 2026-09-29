extends SceneTree

const WindowsPlatforms=preload("res://scripts/windows_platforms.gd")
var pet: Node2D
var sprite: AnimatedSprite2D
var failed:=false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	pet=load("res://scenes/main.tscn").instantiate()
	pet.native_windows_enabled=false
	root.add_child(pet)
	pet.set_process(false)
	pet._play_area_size=Vector2(800,700)
	pet._floor_y=690
	sprite=pet.bongbong
	for right in [false,true]:
		for gait in [&"walk",&"run_light",&"run_bouncy"]:
			reset(Vector2(690 if right else 100,690),right,gait)
			snapshot([window(Rect2(300,180,200,190))])
			for frame in 280:
				var before:=sprite.position
				await tick(1)
				check(sprite.position.distance_to(before)<=3,"Grapple approach warped")
				if pet._grapple.active(): break
			check(pet._grapple.active(),"High window did not start grappling")
			if not pet._grapple.active(): continue
			check(pet._climb_jump.is_empty() and sprite.animation==&"grapple","High window used a jump or wrong pose")
			var planted:=sprite.position
			var saw_shot:=false
			var saw_pull:=false
			var initial_rope:=0.0
			for frame in 300:
				var before:=sprite.position
				await tick(1)
				check(sprite.position.distance_to(before)<=7.0,"Cable pull teleported")
				if not pet._grapple.active(): break
				var state: Dictionary=pet._grapple.state
				if not state["airborne"]:
					check(sprite.position==planted,"Moved before hook attached")
				if state["phase"]=="shoot":
					saw_shot=true
					check(pet._grapple.rope_visible(),"Shot cable is hidden")
					if float(state["elapsed"])>float(state["shot_time"])*0.7:
						var region:=Rect2(sprite.position+Vector2(-48,-126),Vector2(96,134))
						var polygon: PackedVector2Array=pet._grapple.interaction_polygon(region)
						var mid: Vector2=pet._grapple.hand_point().lerp(pet._grapple.rope_tip(),0.6)
						check(Geometry2D.is_point_in_polygon(mid,polygon),"Windows render region clips cable")
						check(not Geometry2D.is_point_in_polygon(mid+Vector2(65,0),polygon),"Cable blocks a wide desktop area")
				if state["phase"]=="pull":
					var length: float=pet._grapple.hand_point().distance_to(state["anchor"])
					if not saw_pull: initial_rope=length
					else: check(length<=initial_rope+0.1,"Cable got longer while reeling")
					saw_pull=true
					check(sprite.position.y<=before.y,"Reeling moved downward")
			check(saw_shot and saw_pull,"Skipped launch or reel phase")
			check(pet._side_hold.get("id")=="target" and not pet._falling,"Grapple missed side contact")
			check(sprite.flip_h==right,"Grapple faces away from wall")
			check(not pet._grapple.rope_visible(),"Cable remained after grabbing")
			var hand:=sprite.position+Vector2(44*(-1 if right else 1),-62)*0.72
			check(absf(hand.x-(500 if right else 300))<0.6,"Catch hands not on wall")
			await tick(6)
			check(pet._climbing,"Grapple did not continue climbing")
			if gait==&"walk":
				for frame in 950:
					await tick(1)
					if pet._side_hold.is_empty(): break
				check(sprite.position.y==180 and pet._has_support(),"Grapple/climb/top-out failed")

	# Ground and small-hop approaches keep priority; manual movement is unaffected.
	reset(Vector2(100,690),false,&"walk")
	for bottom in [690.0,610.0]:
		snapshot([window(Rect2(300,180,200,bottom-180))])
		check(not pet._find_auto_approach().get("grapple",false),"Hook replaced direct contact or small jump")
	snapshot([window(Rect2(300,180,200,190))])
	pet._auto_walk=false
	pet._right_pressed=true
	pet._process(1.5)
	check(not pet._grapple.active(),"Manual movement fired hook")

	# A foreground window across the cable/body route must block selection.
	reset(Vector2(198,690),false,&"walk")
	snapshot([window(Rect2(235,300,35,110),"cover",false),window(Rect2(300,180,200,190))])
	check(pet._grapple.find_approach(1,320).is_empty(),"Cable passed through foreground occluder")
	snapshot([window(Rect2(300,100,200,80))])
	check(pet._grapple.find_approach(1,320).is_empty(),"Chose a top without headroom")
	pet._floor_y=1100
	reset(Vector2(198,1100),false,&"walk")
	snapshot([window(Rect2(300,180,200,80))])
	check(pet._grapple.find_approach(1,320).is_empty(),"Chose a window above hook range")
	pet._floor_y=690

	for airborne in [false,true]:
		for interruption in ["remove","move","resize","cover","space","drag"]:
			reset(Vector2(198,690),false,&"walk")
			snapshot([window(Rect2(300,180,200,190))])
			await tick(2)
			if airborne:
				for frame in 200:
					await tick(1)
					if pet._grapple.active() and pet._grapple.state["phase"]=="pull" and float(pet._grapple.state["elapsed"])>0.25: break
			check(pet._grapple.active(),"No grapple to interrupt")
			var before:=sprite.position
			match interruption:
				"remove": pet.set_window_platforms([])
				"move": snapshot([window(Rect2(330,180,200,190))])
				"resize": snapshot([window(Rect2(300,180,200,130))])
				"cover": snapshot([window(Rect2(235,300,35,110),"cover",false),window(Rect2(300,180,200,190))])
				"space":
					var key:=InputEventKey.new()
					key.keycode=KEY_SPACE
					key.pressed=true
					pet._unhandled_key_input(key)
				"drag": pet._begin_drag(sprite.position)
			check(not pet._grapple.active() and not pet._grapple.rope_visible(),"Interrupted hook stayed active")
			check(sprite.position==before,"Cancel warped pet")
			if interruption=="drag": check(pet._dragging,"Drag failed during hook")
			elif airborne:
				check(pet._falling and pet._fall_velocity<0,"Cable interruption discarded rising momentum")
				for frame in 150:
					await tick(1)
					if pet._landing: break
				check(pet._landing,"Cable interruption did not reach LAND")
			else: check(not pet._falling and sprite.animation==&"idle_default","Ground cancellation launched pet")

	# Window-top launch and disappearing support.
	reset(Vector2(198,590),false,&"walk")
	snapshot([window(Rect2(300,180,200,100)),window(Rect2(100,590,170,90),"base")])
	await tick(2)
	check(pet._grapple.active(),"Could not launch from a lower window")
	snapshot([window(Rect2(300,180,200,100))])
	check(pet._falling and not pet._grapple.active(),"Missing launch support did not cancel hook")

	reset(Vector2(198,690),false,&"walk")
	snapshot([window(Rect2(300,180,200,190))])
	await tick(2)
	pet._process(10.0)
	check(pet._side_hold.get("id")=="target" and not pet._grapple.active(),"Late frame overshot grapple")
	if not failed: print("Grapple passed: both sides/three gaits, grounded launch, cable reel, complete top-out, nearby-route priority, manual control, occlusion/range, window-top support, all cancellations, momentum and late frames")
	quit(1 if failed else 0)

func reset(position: Vector2,right: bool,gait: StringName) -> void:
	pet._clear_side_motion()
	pet._stop_walking()
	pet._dragging=false
	pet._falling=false
	pet._landing=false
	pet._greeting=false
	pet._wander_enabled=false
	pet._auto_climb_cooldown=0.0
	sprite.position=position
	pet._position_x=position.x
	pet._fall_position_y=position.y
	pet._auto_walk=gait==&"walk"
	pet._auto_run=gait==&"run_light"
	pet._auto_run_bouncy=gait==&"run_bouncy"
	pet._begin_walk(-1 if right else 1,gait!=&"walk")

func window(bounds: Rect2,id: String="target",platform: bool=true) -> Dictionary:
	return {"id":id,"x":bounds.position.x,"y":bounds.position.y,"width":bounds.size.x,"height":bounds.size.y,"platform":platform}

func snapshot(windows: Array) -> void:
	pet.set_window_platforms(WindowsPlatforms.visible_platforms(windows,Vector2.ZERO,Vector2(800,1200),140,pet._floor_y,60))

func tick(count: int) -> void:
	for frame in count:
		await process_frame
		pet._process(1.0/60.0)

func check(condition: bool,message: String) -> void:
	if not condition:
		push_error(message)
		failed=true
