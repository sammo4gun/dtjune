extends Node2D

@onready var camera = $"Camera2D"
@onready var player = $"Player"

var player_scene = preload("res://player.tscn")

var camera_position = Vector2(0,0)
var camera_target_zoom = Vector2(1,1)

func _physics_process(delta: float) -> void:
	if player:
		camera.position = camera.position.lerp(player.get_camera_pos(), delta * 2.5)
	else:
		camera.position = camera.position.lerp(camera_position, delta * 2.5)
	
	if camera.zoom != camera_target_zoom:
		camera.zoom = camera.zoom.lerp(camera_target_zoom, delta)

func zoom_in():
	camera_target_zoom = Vector2(2.5, 2.5)

func zoom_out():
	camera_target_zoom = Vector2(1,1)

func grow_player(size, colours, new_colour):
	var player_pos = player.head.global_position
	var player_upside_down = player.head.global_rotation > 0
	camera_position = player.get_camera_pos()
	player.queue_free()
	player = player_scene.instantiate()
	if player_upside_down: player.rotation = -PI
	player.NUM_LINKS = size + 1
	player.COLOUR_LIST = colours + [new_colour]
	player.RESPAWNED = true
	player.global_position = player_pos + Vector2(0, -35)
	add_child(player)
 
