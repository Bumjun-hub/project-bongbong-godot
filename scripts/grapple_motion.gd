extends RefCounted

const ANIMATION: StringName = &"grapple"
const FRAMES: SpriteFrames = preload("res://scenes/grapple_frames.tres")
const AIM_FRAME := 21
const HANG_FRAME := 30
const LAST_FRAME := 44
const HAND_POINTS := [
    Vector2(129,82),
    Vector2(131,84),
    Vector2(132,87),
    Vector2(134,88),
    Vector2(136,90),
    Vector2(136,92),
    Vector2(137,92),
    Vector2(137,91),
    Vector2(137,91),
    Vector2(137,90),
    Vector2(136,92),
    Vector2(136,131),
    Vector2(140,125),
    Vector2(141,118),
    Vector2(141,114),
    Vector2(141,105),
    Vector2(140,102),
    Vector2(139,100),
    Vector2(139,99),
    Vector2(139,97),
    Vector2(139,97),
    Vector2(139,97),
    Vector2(138,94),
    Vector2(137,92),
    Vector2(137,91),
    Vector2(137,89),
    Vector2(137,88),
    Vector2(137,85),
    Vector2(136,84),
    Vector2(136,84),
    Vector2(136,83),
    Vector2(136,83),
    Vector2(136,82),
    Vector2(136,81),
    Vector2(136,82),
    Vector2(135,82),
    Vector2(135,82),
    Vector2(135,81),
    Vector2(135,82),
    Vector2(134,87),
    Vector2(133,92),
    Vector2(135,97),
    Vector2(135,98),
    Vector2(135,105),
    Vector2(134,112)
]
