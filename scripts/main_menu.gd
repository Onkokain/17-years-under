extends Node2D
@onready var buttons: VBoxContainer = $Control/CenterContainer/VBoxContainer
@onready var start_button: TextureButton = $Control/CenterContainer/VBoxContainer/StartCard/Start
@onready var learnmore_button: TextureButton = $Control/CenterContainer/VBoxContainer/LearnMoreCard/learnmore
@onready var settings_button: TextureButton = $Control/CenterContainer/VBoxContainer/SettingsCard/settings
@onready var options_settings: Panel = $settings
@onready var options_learnmore: Panel = $learnmore

var button_type = null
var hover_tweens := {}
var hovered_cards := {}
var pressed_cards := {}


func _ready() -> void:
	buttons.visible = true
	options_settings.visible = false
	options_learnmore.visible = false

	_configure_hover(start_button)
	_configure_hover(learnmore_button)
	_configure_hover(settings_button)


func _configure_hover(button: TextureButton) -> void:
	var card := button.get_parent() as Control
	hovered_cards[card] = false
	pressed_cards[card] = false
	_sync_card_pivot(card)
	card.resized.connect(_sync_card_pivot.bind(card))
	button.mouse_entered.connect(_set_button_hover.bind(card, true))
	button.mouse_exited.connect(_set_button_hover.bind(card, false))
	button.focus_entered.connect(_set_button_hover.bind(card, true))
	button.focus_exited.connect(_set_button_hover.bind(card, false))
	button.button_down.connect(_set_button_pressed.bind(card, true))
	button.button_up.connect(_set_button_pressed.bind(card, false))


func _sync_card_pivot(card: Control) -> void:
	card.pivot_offset = card.size / 2.0


func _set_button_hover(card: Control, hovered: bool) -> void:
	hovered_cards[card] = hovered
	_update_button_scale(card)


func _set_button_pressed(card: Control, pressed: bool) -> void:
	pressed_cards[card] = pressed
	_update_button_scale(card)


func _update_button_scale(card: Control) -> void:
	_sync_card_pivot(card)

	var existing = hover_tweens.get(card)
	if existing != null:
		existing.kill()

	var target_scale := Vector2.ONE
	if pressed_cards.get(card, false):
		target_scale *= 0.94
	elif hovered_cards.get(card, false):
		target_scale *= 1.06

	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tweens[card] = tween
	tween.tween_property(card, "scale", target_scale, 0.12)


func _on_settings_pressed() -> void:
	buttons.visible = false
	options_settings.visible = true


func _on_learnmore_pressed() -> void:
	buttons.visible = false
	options_learnmore.visible = true


func _on_start_pressed() -> void:
	Global.reset_run_state()
	button_type = 'start'
	$ColorRect.show()
	$ColorRect/fade_timer.start()
	$ColorRect/AnimationPlayer.play('Fade_in')


func _on_fade_timer_timeout() -> void:
	if button_type == 'start':
		# Load the cutscene first
		get_tree().change_scene_to_file("res://scenes/cutscene.tscn")

	

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
