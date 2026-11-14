extends Area2D 

var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0

func _process(delta: float) -> void:
	position += direction * speed * delta
