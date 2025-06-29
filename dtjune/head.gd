extends RigidBody2D

var stick_candidate = null
var direction_candidate = null

@onready var head_open_sprite = $"HeadOpenSprite"
@onready var head_closed_sprite = $"HeadClosedSprite"
@onready var head_happy_sprite = $"HeadHappySprite"
@onready var head_shocked_sprite = $"HeadShockedSprite"
@onready var tail_open_sprite = $"TailOpenSprite"
@onready var tail_closed_sprite = $"TailClosedSprite"

@onready var sprite_base_rotations = {
	head_open_sprite: head_open_sprite.rotation,
	head_closed_sprite: head_closed_sprite.rotation,
	head_happy_sprite: head_happy_sprite.rotation,
	head_shocked_sprite: head_shocked_sprite.rotation,
	tail_open_sprite: tail_open_sprite.rotation,
	tail_closed_sprite: tail_closed_sprite.rotation,
}

@onready var aimdetectors = $"AimDetectors"
var raylist = []
@export var num_rays = 16

@export var is_real_head = false;

var seeking = false
var grabbing = false
var prev_grabbing = false
var grabparticles

func _ready() -> void:
	setup_rays(num_rays)
	if is_real_head:
		grabparticles = $"GrabParticlesHandler/GrabParticlesHead"
	else: 
		grabparticles = $"GrabParticlesHandler/GrabParticlesTail"

func setup_rays(i):
	for r in range(i):
		var part = float(r)/float(i)
		var ray = RayCast2D.new()
		ray.target_position.x = sin(2*PI * part) * 30
		ray.target_position.y = cos(2*PI * part) * 30
		raylist.append(ray)
		aimdetectors.add_child(ray)

func _physics_process(_delta):
	stick_candidate = null
	
	var colliding_bodies = $GrabFinder.get_overlapping_bodies()
	if colliding_bodies.size() > 0:
		for body in colliding_bodies:# Perform actions based on the colliding body, e.g.,
			if body.is_in_group("Wall"):
				stick_candidate = body;
				break;
	
		var all_collision_points := []
	
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
	
	if grabbing:
		if grabbing != prev_grabbing:
			grab()
		handle_sprite_grabs()
	else:
		for s in sprite_base_rotations:
			s.rotation = lerp_angle(s.rotation, sprite_base_rotations[s], 0.3)
	prev_grabbing = grabbing

func handle_sprite_grabs():
	var dist_list = []
	for i in raylist:
		if i.is_colliding():
			if i.get_collider().is_in_group("Wall"):
				var dist = (i.get_collision_point() - global_position).length()
				dist_list.append(dist)
			else: dist_list.append(100)
		else: dist_list.append(100)
	
	var min_dist = 100
	var min_dir = -1
	for i in range(len(dist_list)):
		if dist_list[i] < min_dist:
			min_dist = dist_list[i]
			min_dir = i
	
	if min_dir >= 0:
		for s in sprite_base_rotations:
			var angle = raylist[min_dir].target_position.angle()
			if is_real_head: angle += 1.5 * PI
			else: angle += 0.5 * PI
			s.rotation = lerp_angle(s.rotation, sprite_base_rotations[s] + angle, 0.1)

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

func grab():
	print('a')
	var dist_list = []
	for i in raylist:
		if i.is_colliding():
			if i.get_collider().is_in_group("Wall"):
				var dist = (i.get_collision_point() - global_position).length()
				dist_list.append(dist)
			else: dist_list.append(100)
		else: dist_list.append(100)
	
	var min_dist = 100
	var min_dir = -1
	for i in range(len(dist_list)):
		if dist_list[i] < min_dist:
			min_dist = dist_list[i]
			min_dir = i
	
	if min_dir >= 0:
		for s in sprite_base_rotations:
			var angle = raylist[min_dir].target_position.angle()
			if is_real_head: angle += 1.5 * PI
			else: angle += 0.5 * PI
			$"GrabParticlesHandler".rotation =  angle
				
	grabparticles.emitting = true

func _on_grab_finder_area_entered(area: Area2D) -> void:
	if area.is_in_group("Fruit") and is_real_head:
		get_parent().eat_fruit(area.get_parent())
