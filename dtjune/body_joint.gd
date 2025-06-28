extends PinJoint2D
@export var limit_cgw: int = -45 #limit in counterglockwise direction
@export var limit_gw: int = 45 #limit in glockwise direction
#@export var motor_speed: int = 50 #how fast the motor corrects the rotation
@export var control_node: Node2D  #literally Node_B

func _ready():
	control_node = get_node(node_b)
	#motor_enabled = true
	#motor_target_velocity = 0

func _process(delta):
	pass
	
	#--------Probably my best take-----
	
	#if control_node.rotation_degrees < limit_cgw:
		#control_node.angular_velocity = 1
	#if control_node.rotation_degrees > limit_gw:
		#control_node.angular_velocity = -1
	#else:
		#pass
		
		
	
	
	#--------Can't stand heavy impacts, but adjusts softly (uncomment var motor_speed at the top and the ready func)---------
	
	#if control_node.rotation_degrees < limit_cgw:
		#control_node.angular_damp = 100
		#motor_target_velocity = motor_speed
	#if control_node.rotation_degrees > limit_gw:
		#control_node.angular_damp = 100
		#motor_target_velocity = - motor_speed
	#else:
		#control_node.angular_damp = 0
		#motor_target_velocity = 0	
	
	
	#-------Tried to combine the previous ideas-------
	
	#if control_node.rotation_degrees < limit_cgw:
		#control_node.angular_velocity = 0
		#motor_target_velocity = motor_speed
	#if control_node.rotation_degrees > limit_gw:
		#control_node.angular_velocity = 0
		#motor_target_velocity = - motor_speed
	#else:
		#motor_target_velocity = 0
