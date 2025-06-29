extends RigidBody2D

var stick_candidate = null
var direction_candidate = null

var grabparticles = preload("res://grab_particles.tscn")

@onready var head_neutral_open_sprite = $"SpriteHandler/HeadOpenSprite"
@onready var head_neutral_closed_sprite = $"SpriteHandler/HeadClosedSprite"
@onready var head_eating_open_sprite = $"SpriteHandler/HeadEatingOpenSprite"
@onready var head_eating_closed_sprite = $"SpriteHandler/HeadEatingClosedSprite"
@onready var head_content_open_sprite = $"SpriteHandler/HeadContentOpenSprite"
@onready var head_content_closed_sprite = $"SpriteHandler/HeadContentClosedSprite"
@onready var head_shocked_open_sprite = $"SpriteHandler/HeadShockedSprite"
@onready var head_shocked_closed_sprite = $"SpriteHandler/HeadShockedSprite"
@onready var head_effort_open_sprite = $"SpriteHandler/HeadEffortOpenSprite"
@onready var head_effort_closed_sprite = $"SpriteHandler/HeadEffortClosedSprite"

@onready var sprite_list = $"SpriteHandler".get_children()

var head_open_sprite
var head_closed_sprite

@onready var tail_open_sprite = $"SpriteHandler/TailOpenSprite"
@onready var tail_closed_sprite = $"SpriteHandler/TailClosedSprite"

@onready var spriterotation = $"SpriteHandler"

@onready var aimdetectors = $"AimDetectors"
var raylist = []
@export var num_rays = 16

@export var is_real_head = false;

var seeking = false
var grabbing = false
var prev_grabbing = false
var bramble_colliding = false
var bramble_collision_normal = null

var mood = "neutral"
var time = 0
var flip_eating_time
var mouthopen = null

func _ready() -> void:
	setup_rays(num_rays)

func setup_rays(i):
	for r in range(i):
		var part = float(r)/float(i)
		var ray = RayCast2D.new()
		ray.target_position.x = sin(2*PI * part) * 30
		ray.target_position.y = cos(2*PI * part) * 30
		raylist.append(ray)
		aimdetectors.add_child(ray)

func _physics_process(delta):
	time += delta
	if is_real_head: get_mood_sprite()
	stick_candidate = null
	bramble_colliding = false
	
	var colliding_bodies = $GrabFinder.get_overlapping_bodies()
	if colliding_bodies.size() > 0:
		for body in colliding_bodies:# Perform actions based on the colliding body, e.g.,
			if body.is_in_group("Wall"):
				stick_candidate = body;
				break;
			if body.is_in_group("Bramble"):
				bramble_collision_normal = (global_position - body.global_position).normalized()
				bramble_colliding = true
				break;
	
	if not $EatingParticles.emitting:
		mouthopen = null
		if seeking:
			if is_real_head:
				for sp in sprite_list:
					if sp == head_open_sprite:
						sp.visible = true
					else: sp.visible = false
			else:
				for sp in sprite_list:
					if sp == tail_open_sprite:
						sp.visible = true
					else: sp.visible = false
		if not seeking:
			if is_real_head:
				for sp in sprite_list:
					if sp == head_closed_sprite:
						sp.visible = true
					else: sp.visible = false
			else:
				for sp in sprite_list:
					if sp == tail_closed_sprite:
						sp.visible = true
					else: sp.visible = false
	else:
		if mouthopen == null:
			mouthopen = true
			flip_eating_time = time
		if time - flip_eating_time > 0.2:
			mouthopen = !mouthopen
			flip_eating_time = time
		if mouthopen:
			for sp in sprite_list:
				if sp == head_eating_open_sprite:
					sp.visible = true
				else: sp.visible = false
		else:
			for sp in sprite_list:
				if sp == head_eating_closed_sprite:
					sp.visible = true
				else: sp.visible = false
	
	if grabbing:
		if grabbing != prev_grabbing:
			grab()
		handle_sprite_grabs()
	else:
		if grabbing != prev_grabbing:
			release()
		spriterotation.rotation = lerp_angle(spriterotation.rotation, 0, 0.3)
	prev_grabbing = grabbing

func get_mood_sprite():
	if mood == "neutral":
		head_open_sprite = head_neutral_open_sprite
		head_closed_sprite = head_neutral_closed_sprite
	if mood == "shocked":
		head_open_sprite = head_shocked_open_sprite
		head_closed_sprite = head_shocked_closed_sprite
	if mood == "effort":
		head_open_sprite = head_effort_open_sprite
		head_closed_sprite = head_effort_closed_sprite
	if mood == "content":
		head_open_sprite = head_content_open_sprite
		head_closed_sprite = head_content_closed_sprite

func handle_bramble():
	bramble_colliding = false
	var dist_list = []
	for ray in raylist:
		if ray.is_colliding():
			var collider = ray.get_collider()
			if collider.is_in_group("Bramble"):
				
				var collision_point = ray.get_collision_point()
				bramble_collision_normal = ray.get_collision_normal()
				

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
		var angle = raylist[min_dir].target_position.angle()
		if is_real_head: angle += 1.5 * PI
		else: angle += 0.5 * PI
		spriterotation.rotation = lerp_angle(spriterotation.rotation, angle, 0.3)

func set_colour(color):
	for sprite in sprite_list:
		sprite.self_modulate = color

func start_eating(color):
	if is_real_head:
		$EatingParticles.modulate = color
		$EatingParticles.emitting = true

func stop_eating():
	if is_real_head:
		mood = "shocked"
		$EatingParticles.emitting = false

func grab():
	if is_real_head:
		if mood != 'content':
			mood = 'effort'
	
	var grab_part = grabparticles.instantiate()
	grab_part.position = Vector2(12, 0)
	grab_part.rotation = deg_to_rad(27.8)
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
		var angle = raylist[min_dir].target_position.angle()
		$"GrabParticlesHandler".rotation =  angle
		$"GrabParticlesHandler".add_child(grab_part)
		grab_part.emitting = true
		await get_tree().create_timer(0.8).timeout
		grab_part.queue_free()

func release():
	if is_real_head:
		mood = "neutral"

func _on_grab_finder_area_entered(area: Area2D) -> void:
	if area.is_in_group("Fruit") and is_real_head:
		get_parent().eat_fruit(area.get_parent())
