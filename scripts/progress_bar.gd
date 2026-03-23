extends TextureProgressBar


@export var player: CharacterBody2D
func _ready():
	player.staminachanged.connect(update) 
	update()
func update():
	
	value=player.current_stamina*100/Global.total_stamina
	
