extends StaticBody2D


func close_up():
	$PointLight2D.queue_free()
	$Sprite2D.queue_free()
	$Sprite2D2.queue_free()
	$CollisionPolygon2D.queue_free()
	$Area2D.queue_free()
	queue_free()
