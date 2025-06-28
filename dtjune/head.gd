extends RigidBody2D

var stick_candidate = null

@onready var head_open_sprite = $"HeadOpenSprite"
@onready var head_closed_sprite = $"HeadClosedSprite"
@onready var tail_open_sprite = $"TailOpenSprite"
@onready var tail_closed_sprite = $"TailClosedSprite"

@export var is_real_head = false;

var sticking = false

func _physics_process(_delta):
	stick_candidate = null
	
	var colliding_bodies = $Area2D.get_overlapping_bodies()
	if colliding_bodies.size() > 0:
		for body in colliding_bodies:# Perform actions based on the colliding body, e.g.,
			if body.is_in_group("Wall"):
				stick_candidate = body;
				break;
				
	if sticking:
		if is_real_head:
			head_open_sprite.visible = true
			head_closed_sprite.visible = false
		else:
			tail_open_sprite.visible = true
			tail_closed_sprite.visible = false
	else:
		if is_real_head:
			head_open_sprite.visible = false
			head_closed_sprite.visible = true
		else:
			tail_open_sprite.visible = false
			tail_closed_sprite.visible = true
