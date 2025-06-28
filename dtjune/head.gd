extends RigidBody2D

var stick_candidate = null

@onready var head_open_sprite = $"HeadOpenSprite"
@onready var head_closed_sprite = $"HeadClosedSprite"
@onready var head_happy_sprite = $"HeadHappySprite"
@onready var head_shocked_sprite = $"HeadShockedSprite"
@onready var tail_open_sprite = $"TailOpenSprite"
@onready var tail_closed_sprite = $"TailClosedSprite"

@export var is_real_head = false;

var seeking = false

func _physics_process(_delta):
	stick_candidate = null
	
	var colliding_bodies = $GrabFinder.get_overlapping_bodies()
	if colliding_bodies.size() > 0:
		for body in colliding_bodies:# Perform actions based on the colliding body, e.g.,
			if body.is_in_group("Wall"):
				stick_candidate = body;
				break;
	
	if not $EatingParticles.emitting:
		if seeking:
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

func set_colour(color):
	for sprite in [head_open_sprite, head_closed_sprite, head_happy_sprite, head_shocked_sprite, tail_open_sprite, tail_closed_sprite]:
		sprite.self_modulate = color

func start_eating(color):
	if is_real_head:
		head_open_sprite.visible = false
		head_closed_sprite.visible = false
		$EatingParticles.modulate = color
		$EatingParticles.emitting = true
		head_happy_sprite.visible = true

func stop_eating():
	if is_real_head:
		head_happy_sprite.visible = false
		head_shocked_sprite.visible = true
		$EatingParticles.emitting = false

func _on_grab_finder_area_entered(area: Area2D) -> void:
	if area.is_in_group("Fruit") and is_real_head:
		get_parent().eat_fruit(area.get_parent())
