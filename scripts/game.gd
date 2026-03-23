extends Node2D
@onready var health_bar: CanvasLayer = $HealthBar
@onready var number: Label = $quitgame/number
@onready var panel: Node2D = $"shop menu/Node2D"
@onready var jump_boost: Button = $"shop menu/Node2D/VBoxContainer2/jump boost"
@onready var stamina: Button = $"shop menu/Node2D/VBoxContainer2/stamina"
@onready var speed_boost: Button = $"shop menu/Node2D/VBoxContainer2/speed boost"
@onready var escape_rope: Button = $"shop menu/Node2D/VBoxContainer2/escape rope"
@onready var upper: CollisionShape2D = $killzone_upper/upper
@onready var lower: CollisionShape2D = $killzone_lower/lower
@onready var panel_neverescape: Panel = $"NEVER ESCAPE/Panel"
@onready var escape_rope_text: Label = $"shop menu/Node2D/VBoxContainer/escape rope/escape_rope_text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	escape_rope_text.visible=false
	panel_neverescape.visible=false
	upper.disabled=false
	panel.visible=false
	number.text=str(Global.sap)
	$ColorRect/AnimationPlayer.play('Fade_in')
	health_bar.visible=false 

func _process(_delta: float):
	number.text=str(Global.sap)
	if Global.passed_once:
		lower.disabled=true
	
func _on_button_pressed() -> void:
	Global.reset_run_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func addpoint():
	Global.sap+=1
	number.text=str(Global.sap)

func _on_gravity_remover_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.no_gravity=true

func _on_gravity_remover_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.no_gravity=false

func _on_shop_menu_body_entered(_body: Node2D) -> void:
	panel.visible=true

func _on_shop_menu_body_exited(_body: Node2D) -> void:
	panel.visible=false

func _on_jump_boost_pressed() -> void:
	if Global.sap>=10:
		jump_boost.disabled=true
		Global.sap-=10
		Global.jump-=30.0

func _on_stamina_pressed() -> void:
	if Global.sap>=20:
		stamina.disabled=true
		Global.sap-=20
		Global.total_stamina+=100

func _on_speed_boost_pressed() -> void:
	if Global.sap>=30:
		speed_boost.disabled=true
		Global.sap-=30
		Global.speed+=50

func _on_escape_rope_pressed() -> void:
	if Global.sap>=50:
		escape_rope.disabled=true
		Global.sap-=50
		Global.has_escaperope=true

func _on_killzone_upper_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		
		if Global.has_escaperope:
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file("res://scenes/cutscene.tscn")

func _on_killzone_lower_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D && Global.passed_once==false:
		Global.passed_once=true
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/cutscene.tscn")


func _on_never_escape_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		panel_neverescape.visible=true
		Global.no_gravity=true
		await get_tree().create_timer(2.0).timeout
		Global.no_gravity=false


func _on_never_escape_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		panel_neverescape.visible=false
		Global.no_gravity=false
	



	


func _on_escape_rope_mouse_entered() -> void:
	escape_rope_text.visible=true



func _on_escape_rope_mouse_exited() -> void:
	escape_rope_text.visible=false
