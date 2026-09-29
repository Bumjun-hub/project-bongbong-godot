extends Node2D

var controller: RefCounted


func _draw() -> void:
	if controller != null:
		controller.draw_dust(self)
