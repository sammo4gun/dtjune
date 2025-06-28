extends Node2D

@export var head_thrust = 2000
@export var head_linear_damp = 4.0
@export var head_angular_damp = 4.0

@onready var camera = $"Camera2D"

const LINK_SCENE = preload("res://body_part.tscn")
const HEAD_SCENE = preload("res://head.tscn")
const NUM_LINKS = 5
const LINK_SPACING = 25

var previous_link = null
var active_head = null
var link_array = []
var head = null
var head_joint = null
var tail = null
var tail_joint = null

var current_force = Vector2.ZERO

var direction_multiplier = {
	"up": 0.9,
	"down": 0.3,
	"left": 0.1,
	"right": 0.1,
}

func _ready():
	init_head()
	init_links()
	init_tail()
	
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	head_thrust = get_total_mass() * gravity	

func get_total_mass() -> float:
	var total_mass = head.mass + tail.mass
	for link in link_array:
		total_mass += link.mass
	return total_mass

func init_head():
	head = HEAD_SCENE.instantiate()
	head.position = Vector2(0, -LINK_SPACING)
	head.linear_damp = head_linear_damp
	head.angular_damp = head_angular_damp
	head.is_real_head = true
	add_child(head)
	previous_link = head

func init_tail():
	tail = HEAD_SCENE.instantiate()
	tail.position = Vector2(0, LINK_SPACING * (NUM_LINKS))
	add_child(tail)

	tail.linear_damp = head_linear_damp
	tail.angular_damp = head_angular_damp

	var joint = PinJoint2D.new()
	joint.position = (previous_link.position + tail.position) / 2
	joint.disable_collision = false;
	joint.node_a = previous_link.get_path()
	joint.node_b = tail.get_path()
	add_child(joint)
	

func init_links():
	for i in range(NUM_LINKS):
		var link = LINK_SCENE.instantiate()
		link.position = Vector2(0, i * LINK_SPACING)
		link_array.append(link)
		add_child(link)
		
		if previous_link:
			var joint = PinJoint2D.new()
			joint.node_a = previous_link.get_path()
			joint.node_b = link.get_path()
			joint.position = (previous_link.position + link.position) / 2
			joint.disable_collision = false;
			add_child(joint)
			
		previous_link = link

func _physics_process(delta):
	handle_camera()
	var input_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1

	if input_direction != Vector2.ZERO:
		var target_force = input_direction.normalized() * head_thrust
		var acceleration_speed = 1.0
		current_force = current_force.lerp(target_force, delta * acceleration_speed)
	else:
		current_force = Vector2.ZERO

	if active_head:
		active_head.apply_force(current_force)

func handle_camera():
	camera.position = head.position

func _input(event):
	handle_grabbing(event)

func handle_grabbing(event):
	if event.is_action_pressed("stick_head"):
		if attach_joint_to_candidate(head, "head_joint"):
			active_head = tail

	if event.is_action_released("stick_head"):
		if active_head == tail:
			active_head = null
		detach_joint("head_joint")

	if event.is_action_pressed("stick_tail"):
		if attach_joint_to_candidate(tail, "tail_joint"):
			active_head = head

	if event.is_action_released("stick_tail"):
		if active_head == head:
			active_head = null
		detach_joint("tail_joint")

func attach_joint_to_candidate(link_body: RigidBody2D, joint_name: String):
	if link_body.stick_candidate == null or self.get(joint_name) != null:
		return false

	var joint = PinJoint2D.new()
	joint.position = (link_body.position)
	joint.node_a = link_body.get_path()
	joint.node_b = link_body.stick_candidate.get_path()
	add_child(joint)
	self.set(joint_name, joint)
	
	return true

func detach_joint(joint_name: String):
	var joint = self.get(joint_name)
	if joint:
		joint.queue_free()
		self.set(joint_name, null)
