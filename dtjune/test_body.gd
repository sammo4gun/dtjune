extends RigidBody2D

const SPEED := 200.0

func _physics_process(_delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized()
	linear_velocity = input_vector * SPEED
