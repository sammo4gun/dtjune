extends Node2D

@export var head_linear_damp = 4.0
@export var head_angular_damp = 4.0
@export var angular_limit_body = deg_to_rad(45)
@export var angular_limit_head = deg_to_rad(90)

const LINK_SCENE = preload("res://body_part.tscn")
const HEAD_SCENE = preload("res://head.tscn")
const JOINT_SCENE = preload("res://body_joint.tscn")
const LINK_SPACING = 25 * 1.5

const COLOUR_DICT = {
	"base": Color8(133, 194, 21),
	"white": Color8(155, 155, 155),
	"red": Color8(206, 21, 0),
	"green": Color8(1, 130, 32),
	"yellow": Color8(209, 218, 0),
	"blue": Color8(28, 219, 240),
	"orange": Color8(221, 118, 4),
	"violet": Color8(247, 147, 177),
	"purple": Color8(127, 0, 255),
}

var previous_link = null
var active_head = null
var link_array = []
var head = null
var head_joint = null
var tail = null
var tail_joint = null
var eating = false

var butterfly_mode = false

var current_force = Vector2.ZERO

var max_head_thrust = 0
var current_head_thrust = 0

var target_rotation = {}

var transitioning = false
var body_rotation = 0

var NUM_LINKS = 1
var COLOUR_LIST = ['white']
var RESPAWNED = false

var can_flap = true
var butterfly_instance = null
var ButterflyBodyScene = preload("res://butterfly_body.tscn")

func _ready():
	if(butterfly_mode):
		spawn_butterfly()
		butterfly_instance.collision_layer = 1
		butterfly_instance.visible = true
		butterfly_instance.mass = 0.6
		butterfly_instance.linear_damp = 2
		
		butterfly_instance.get_node("Wings").texture = load("res://Assets/buttery wings open.png")
		butterfly_instance.linear_velocity.y = $ButterflyBody.linear_velocity.y/2
		await get_tree().create_timer(0.2).timeout
		butterfly_instance.get_node("Wings").texture  = load("res://Assets/buttery wings closed.png")
		butterfly_instance.get_node("swoosh").play()
		butterfly_instance.apply_force(Vector2(0,-70000))
	else:
		init_head()
		init_links()
		init_tail()
		init_colours()
		if RESPAWNED:
			$TransitionRelief.play()
			$Twinkle.play()
			for i in link_array:
				i.get_child(3).emitting = true
			head.mood = "content"
			await get_tree().create_timer(0.8).timeout
			head.mood = "neutral"
			
		var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
		max_head_thrust = get_total_mass() * gravity	

func spawn_butterfly():
	butterfly_instance = ButterflyBodyScene.instantiate()
	add_child(butterfly_instance)

func init_colours():
	head.set_colour(COLOUR_DICT['base'])
	for i in range(len(link_array)):
		link_array[i].modulate = COLOUR_DICT[COLOUR_LIST[i]]
	tail.set_colour(COLOUR_DICT['base'])

func get_total_mass() -> float:
	var total_mass = head.mass + tail.mass
	for link in link_array:
		total_mass += link.mass
	return total_mass

func init_head():
	head = HEAD_SCENE.instantiate()
	head.position = Vector2(LINK_SPACING, 0)
	head.linear_damp = head_linear_damp
	head.angular_damp = head_angular_damp
	head.is_real_head = true
	add_child(head)
	previous_link = head
	target_rotation[head] = null

func init_tail():
	tail = HEAD_SCENE.instantiate()
	tail.position = Vector2(- LINK_SPACING * (NUM_LINKS), 0)
	add_child(tail)

	tail.linear_damp = head_linear_damp
	tail.angular_damp = head_angular_damp

	var joint = JOINT_SCENE.instantiate()
	joint.position = (previous_link.position + tail.position) / 2
	joint.disable_collision = false;
	joint.node_a = previous_link.get_path()
	joint.node_b = tail.get_path()
	target_rotation[tail] = null
	add_child(joint)

func init_links():
	for i in range(NUM_LINKS):
		var link = LINK_SCENE.instantiate()
		link.position = Vector2(- i * LINK_SPACING, 0)
		link_array.append(link)
		add_child(link)
		
		if previous_link:
			var joint = JOINT_SCENE.instantiate()
			joint.node_a = previous_link.get_path()
			joint.node_b = link.get_path()
			joint.position = (previous_link.position + link.position) / 2
			joint.disable_collision = false;
			add_child(joint)
			
		previous_link = link

func get_camera_pos():
	if butterfly_mode:
		if butterfly_instance:
			return butterfly_instance.global_position;
		else: return null
	else:
		return (head.global_position+tail.global_position) / 2

func _physics_process(delta):
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1
			
	if(!butterfly_mode):
		handle_rotation()
		
		if input_direction != Vector2.ZERO:
			var target_force = input_direction.normalized() * current_head_thrust
			var acceleration_speed = 3.0
			current_force = current_force.lerp(target_force, delta * acceleration_speed)
		else:
			current_force = Vector2.ZERO

		if not eating:
			if Input.is_action_pressed("stick_head") and self.get("head_joint") == null:
				attach_joint_to_candidate(head, "head_joint")

			if Input.is_action_pressed("stick_tail") and self.get("tail_joint") == null:
				attach_joint_to_candidate(tail, "tail_joint")
		
		get_active_head()
		if active_head:
			if active_head.bramble_colliding:
				var rebound_force = active_head.bramble_collision_normal * 20000
				active_head.apply_force(rebound_force) 
			else:
				active_head.apply_force(current_force)
		handle_head_sprites()
		
		if head.in_cocoon and tail.in_cocoon and !transitioning:
			transitioning = true
			get_parent().zoom_in_cocoon()
			get_parent().fade_background_to_white(0.15)
			await get_tree().create_timer(7.5).timeout
			get_parent().show_ui("final")
			get_parent().grow_butterfy()
			get_tree().get_first_node_in_group("JustTheActualCocoon").close_up()
			get_parent().fade_background_to_clear(1);
			get_parent().zoom_out()
	else:
		var flap_force := Vector2.ZERO

		if Input.is_action_just_pressed("ui_up") and can_flap:
			can_flap = false  # block further flaps until cooldown ends

			butterfly_instance.get_node("Wings").texture = load("res://Assets/buttery wings open.png")
			butterfly_instance.linear_velocity.y = $ButterflyBody.linear_velocity.y/2
			flap_force.y = -75000
			
			# Delay then set wings closed and re-enable flap
			await get_tree().create_timer(0.2).timeout
			butterfly_instance.get_node("Wings").texture  = load("res://Assets/buttery wings closed.png")
			butterfly_instance.get_node("swoosh").play()
			can_flap = true  # re-enable flap after delay

		if Input.is_action_pressed("ui_left"):
			flap_force.x = -800
		elif Input.is_action_pressed("ui_right"):
			flap_force.x = 800
		else:
			if butterfly_instance.rotation_degrees > 0:
				butterfly_instance.rotation_degrees -= delta * 300
				if butterfly_instance.rotation_degrees < 0:
					butterfly_instance.rotation_degrees = 0
			elif butterfly_instance.rotation_degrees < 0:
				butterfly_instance.rotation_degrees += delta * 300
				if butterfly_instance.rotation_degrees > 0:
					butterfly_instance.rotation_degrees = 0
		
		butterfly_instance.rotation_degrees -= Input.get_action_strength("ui_left") * delta * 300
		butterfly_instance.rotation_degrees += Input.get_action_strength("ui_right") * delta * 300
		butterfly_instance.rotation_degrees = clamp(butterfly_instance.rotation_degrees, -30, 30)

		butterfly_instance.angular_velocity = 0
		butterfly_instance.apply_force(flap_force)


func handle_head_sprites():
	if Input.is_action_pressed("stick_head"):
		head.seeking = self.get("head_joint") == null
		head.grabbing = self.get("head_joint") != null
	else: 
		head.seeking = false
		head.grabbing = false
	if Input.is_action_pressed("stick_tail"):
		tail.seeking = self.get("tail_joint") == null
		tail.grabbing = self.get("tail_joint") != null
	else: 
		tail.seeking = false
		tail.grabbing = false

func handle_rotation():
	for part in target_rotation:
		if target_rotation[part] != null:
			part.global_rotation = lerpf(part.global_rotation, target_rotation[part], 0.1)

func get_active_head():
	if self.get("head_joint") == null and self.get("tail_joint") != null:
		current_head_thrust = max_head_thrust
		active_head = head
	elif self.get("tail_joint") == null and self.get("head_joint") != null:
		current_head_thrust = max_head_thrust
		active_head = tail
	else:
		current_head_thrust = max_head_thrust / 4
		active_head = head

func _input(event):
	handle_detatching(event)

func handle_detatching(event):
	if event.is_action_released("stick_head"):
		detach_joint("head_joint")
		
	if event.is_action_released("stick_tail"):
		detach_joint("tail_joint")

func attach_joint_to_candidate(link_body: RigidBody2D, joint_name: String):
	if link_body.stick_candidate == null or self.get(joint_name) != null:
		return false
	
	var joint = PinJoint2D.new()
	joint.position = (link_body.position)
	joint.node_a = link_body.get_path()
	joint.node_b = link_body.stick_candidate.get_path()
	target_rotation[link_body] = null # tbd
	add_child(joint)
	self.set(joint_name, joint)
	
	if not $Grab.playing:
		$Grab.pitch_scale = randf_range(0.9, 1.3)
		$Grab.play()
	
	return true

func detach_joint(joint_name: String):
	var joint = self.get(joint_name)
	if joint_name == 'head_joint':
		target_rotation[head] = null
	if joint_name == 'tail_join':
		target_rotation[tail] = null
	if joint:
		joint.queue_free()
		self.set(joint_name, null)

func eat_fruit(fruit):
	var li = fruit.get_eaten()
	eating = true
	head.start_eating(li[1])
	await get_tree().create_timer(2.5).timeout
	head.stop_eating()
	get_parent().zoom_in()
	$TransitionAnxiety.play()
	await get_tree().create_timer(1.5).timeout
	get_parent().grow_player(NUM_LINKS, COLOUR_LIST, li[0])
	get_parent().zoom_out()
	
