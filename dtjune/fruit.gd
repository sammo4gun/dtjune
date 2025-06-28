extends Node2D

@export var SWAY = 8
@export_flags("strawberry", "apple", "banana", "blueberry", "orange", "raspberry") var picked_type = 0

@onready var sprites_dict = {
	'strawberry': $StrawberrySprite,
	'apple': $AppleSprite,
	'banana': $BananaSprite,
	'blueberry': $BlueberrySprite,
	'orange': $OrangeSprite,
	'raspberry': $RaspberrySprite,
}
@onready var particle_dict = {
	'strawberry': Color8(227, 76, 76, 255),
	'apple': Color8(77, 172, 12, 255),
	'banana': Color8(255, 244, 18, 255),
	'blueberry': Color8(91, 110, 225, 255),
	'orange': Color8(223, 113, 38, 255),
	'raspberry': Color8(223, 16, 157, 255),
}
@onready var particles = $Particles
@onready var basepos = position

var types_dict = {
	1: 'strawberry',
	2: 'apple',
	4: 'banana',
	8: 'blueberry',
	16: 'orange',
	32: 'raspberry',
}
var time = 0

var type

func _ready() -> void:
	select_type(types_dict[picked_type])

func select_type(given_type: String):
	type = given_type
	particles.self_modulate = particle_dict[given_type]
	for spr in sprites_dict:
		if spr == given_type:
			sprites_dict[spr].visible = true
		else: sprites_dict[spr].visible = false

func _process(delta: float) -> void:
	time += delta
	position.y = basepos.y + sin(time * 1.4) * SWAY

func get_eaten():
	self.queue_free()
	# returns: the type of fruit that was eaten, and the colour of that fruit
	return [type, particle_dict[type]]
