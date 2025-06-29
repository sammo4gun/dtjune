extends Node2D

@onready var camera = $"Camera2D"
@onready var player = $"Player"

@onready var ui_final = $"Camera2D/YouDidIt"

@onready var music = $"MusicPlayer"

var player_scene = preload("res://player.tscn")

var camera_position = Vector2(0,0)
var camera_target_zoom = Vector2(1,1)

var fade_alpha = 0.0
var fade_speed = 1.0
var fading_in = false
var fading_out = false;
var zoom_speed = 1

func _physics_process(delta: float) -> void:
	var target_pos
	
	if player:
		target_pos = player.get_camera_pos()
	else:
		target_pos = camera_position
	if target_pos == null:
		target_pos = camera.position
	
	target_pos.y = max(-2973.0, target_pos.y)
	
	camera.position = camera.position.lerp(target_pos, delta * 2.5)
	
	if camera.zoom != camera_target_zoom:
		camera.zoom = camera.zoom.lerp(camera_target_zoom, delta * zoom_speed)

func _process(delta):
	if fading_in:
		music.volume_db = lerpf(music.volume_db, -200, 0.1)
		fade_alpha = clamp(fade_alpha + fade_speed * delta, 0.0, 1.0)
		$WhiteFade.color = Color(1, 1, 1, fade_alpha)#
		if(fade_alpha == 1.0):
			fading_in = false
			
	if fading_out:
		fade_alpha = clamp(fade_alpha + fade_speed * delta, 0.0, 1.0)
		$WhiteFade.color = Color(1, 1, 1, fade_alpha)#
		if(fade_alpha == 0.0):
			fading_out = false

func zoom_in():
	zoom_speed = 1
	camera_target_zoom = Vector2(2.5, 2.5)

func zoom_out():
	zoom_speed = 1
	camera_target_zoom = Vector2(1,1)
	
func zoom_in_cocoon():
	$TransitionSound.play()
	zoom_speed = 0.25
	camera_target_zoom = Vector2(2.5, 2.5)
	
func fade_background_to_white(speed):
	fade_speed = speed
	fade_alpha = 0.0
	fading_in = true
	
func fade_background_to_clear(speed):
	fade_speed = -speed
	fade_alpha = 1.0
	fading_out = true

func grow_butterfy():
	var player_pos = player.head.global_position
	player.queue_free()
	player = player_scene.instantiate()
	player.butterfly_mode = true
	player.global_position = player_pos + Vector2(0, -35)
	add_child(player)
 
func show_ui(type):
	if type == "final":
		ui_final.visible = true

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

var ending = false

func _on_area_2d_body_entered(_body: Node2D) -> void:
	if not ending:
		ending = true
		fade_background_to_white(0.15)
		await get_tree().create_timer(7.5).timeout
		get_tree().change_scene_to_file("res://menu.tscn")

func turn_down():
	music.volume_db = - 30

func turn_up():
	music.volume_db = - 15
