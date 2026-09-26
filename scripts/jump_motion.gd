extends RefCounted

# Reviewed push-off boundaries in the generated jump poses.
const NORMAL: StringName = &"climb_jump"
const BOUNCY: StringName = &"climb_jump_bouncy"
const FRAMES: SpriteFrames = preload("res://scenes/climb_jump_frames.tres")
const TAKEOFF_FRAME := {NORMAL: 17, BOUNCY: 26}
