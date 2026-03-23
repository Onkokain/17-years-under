extends Node2D
@onready var cutscene: Node2D = $"."
@onready var cutscene_label: Label = $CanvasLayer/Label
@onready var color_rect: ColorRect = $CanvasLayer/ColorRect
@onready var end: Label = $CanvasLayer/end
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var end_good: Label = $CanvasLayer/end_good


@onready var timer: Timer = $Timer

var lines = [
	'Where.. Where am I?',
	'Why.. why am I back here again..',
	"Game Over!"
]

func _ready() -> void:
	end_good.visible=false
	canvas_layer.visible=true
	end.visible=false
	cutscene_label.visible = false
	cutscene_label.text = ""
	
	color_rect.modulate.a = 1.0 
	color_rect.show()	
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 1.5)
	
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(start_cutscene)
	timer.start()

func start_cutscene() -> void:
	var current = Global.played_count

	if current >= len(lines):
		end_scene()
		return
	

	if current == len(lines) - 1 && Global.has_escaperope :
		zoomout_win()
		return
	# Normal logic for all other lines
	cutscene_label.text = lines[current] 
	cutscene_label.visible = true
	
	timer.wait_time = 2.5
	timer.one_shot = true
	# Use a lambda or disconnect/reconnect to avoid signal stacking
	if timer.timeout.is_connected(start_cutscene):
		timer.timeout.disconnect(start_cutscene)
	
	timer.timeout.connect(load_game, CONNECT_ONE_SHOT)
	timer.start()


	
func zoomout_win() -> void:
	# 1. Target the camera inside the instanced game map
	# This path assumes you renamed the instanced node to "GameMap"
	var camera = $GameMap/player/Camera2D
	end_good.visible=true
	if camera:
		camera.make_current() 

	# 2. Hide the ColorRect so it doesn't block the view
	color_rect.visible = false 
	cutscene_label.visible = false # Hide text while zooming
	
	# 3. Create the Zoom Animation
	var tween = create_tween()
	
	# ZOOM OUT = Small number. (0.2 means you see 5x more of the map)
	var target_zoom = Vector2(0.2, 0.2) 
	
	# Animate the zoom over 10 seconds
	tween.tween_property(camera, "zoom", target_zoom, 10.0).set_trans(Tween.TRANS_SINE)
	
	# 4. Wait for the zoom to finish
	await tween.finished
	
	# 5. Show "Game Over"
	cutscene_label.text = lines[len(lines)-1]
	cutscene_label.visible = true
	
	# 6. Wait 3 seconds, then go to the Main Menu
	await get_tree().create_timer(3.0).timeout
	end_scene()

func end_scene() -> void:
	Global.reset_run_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func load_game() -> void:
	Global.played_count += 1
	get_tree().change_scene_to_file("res://scenes/game.tscn")
