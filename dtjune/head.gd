extends RigidBody2D

var stick_candidate = null

func _physics_process(delta):
	stick_candidate = null
	
	var colliding_bodies = $Area2D.get_overlapping_bodies()
	if colliding_bodies.size() > 0:
		for body in colliding_bodies:# Perform actions based on the colliding body, e.g.,
			if body.is_in_group("Wall"):
				stick_candidate = body;
				break;
