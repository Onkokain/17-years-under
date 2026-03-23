extends Area2D


@onready var game: Node2D = $"../../.."

@export var player: CharacterBody2D

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.total_stamina+=20

		body.current_stamina+=20
		game.addpoint()
		queue_free()
		
		
