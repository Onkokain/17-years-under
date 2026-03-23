extends CharacterBody2D

signal staminachanged
signal healthchanged
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var blocks: TileMap = $"../Blocks"
@onready var foreground: TileMap = $"../TileMap/foreground"
@onready var mmusic: AudioStreamPlayer2D = $mmusic
@onready var mining: AudioStreamPlayer2D = $"../mining"
@onready var regen_timer: Timer = $HealthRegenTimer
@onready var ray_cast_2d: RayCast2D = $RayCast2D

@export var current_stamina: int = Global.total_stamina
@export var max_health = 100
@export var current_health: int = max_health



const dialogue_resource='res://dialogues/dialogue_player.dialogue'

const ATLAS_START := Vector2i(7, 4)    # starting
const ATLAS_BROKEN1 := Vector2i(1, 4)  # broken stage 1
const ATLAS_BROKEN2 := Vector2i(5, 4)  # broken stage 2
const BREAK_COOLDOWN_TIME := 0.2
const BREAK_RAY_UP := Vector2(0, -14)
const BREAK_RAY_SIDE_LENGTH := 10.0
const BREAK_RAY_INSET := 1.0
const STAMINA_REGEN:=1.5
const HEALTH_REGEN := 1 # amount of health regained per second 



var last_direction := 0
var tile_health := {}
var default_gravity: float
var current_gravity: float
var break_cooldown: float = 0.0


func _ready() -> void:
	camera.zoom=Global.camera_zoom
	default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")/2
	current_gravity = default_gravity
	ray_cast_2d.enabled = true
	_restore_saved_tiles()
	
	regen_timer.timeout.connect(_on_regen_timer_timeout)


func _restore_saved_tiles() -> void:
	tile_health = Global.mined_tile_hits.duplicate(true)

	for key: String in tile_health.keys():
		var coords := key.split("_")
		if coords.size() != 2:
			continue

		var tile_pos := Vector2i(int(coords[0]), int(coords[1]))
		var hits: int = int(tile_health[key])
		var src_id: int = blocks.get_cell_source_id(0, tile_pos)

		if hits >= 3:
			blocks.erase_cell(0, tile_pos)
		elif src_id != -1:
			if hits == 1:
				blocks.set_cell(0, tile_pos, src_id, ATLAS_BROKEN1)
			elif hits == 2:
				blocks.set_cell(0, tile_pos, src_id, ATLAS_BROKEN2)

func _on_regen_timer_timeout():
	
	current_stamina = min(current_stamina + STAMINA_REGEN, Global.total_stamina)
	
	staminachanged.emit()
	healthchanged.emit()

func _break_tile_at(tile_pos: Vector2i) -> void:

	if current_stamina < 5:
		return
	var src_id: int = blocks.get_cell_source_id(0, tile_pos)
	if src_id == -1:
		return

	var key: String = "%d_%d" % [tile_pos.x, tile_pos.y]
	var hits: int = tile_health.get(key, 0) + 1
	tile_health[key] = hits
	Global.save_tile_damage(tile_pos, hits)

	current_stamina = max(0, current_stamina - 5)
	staminachanged.emit()

	if hits == 1:
		blocks.set_cell(0, tile_pos, src_id, ATLAS_BROKEN1)
	elif hits == 2:
		blocks.set_cell(0, tile_pos, src_id, ATLAS_BROKEN2)
	else:
		blocks.erase_cell(0, tile_pos)

	if mining.playing:
		mining.stop()
	mining.play()
	
	break_cooldown = BREAK_COOLDOWN_TIME

func _break_tile_with_raycast(local_target: Vector2) -> void:
	if ray_cast_2d == null:
		return

	ray_cast_2d.target_position = local_target
	ray_cast_2d.force_raycast_update()

	if not ray_cast_2d.is_colliding():
		return

	var collider := ray_cast_2d.get_collider()
	if collider != blocks:
		return

	var break_point := ray_cast_2d.get_collision_point() - (ray_cast_2d.get_collision_normal() * BREAK_RAY_INSET)
	var tile_pos: Vector2i = blocks.local_to_map(blocks.to_local(break_point))
	_break_tile_at(tile_pos)

func break_tile_above() -> void:

	_break_tile_with_raycast(BREAK_RAY_UP)

func break_tile_side(dir: int) -> void:
	if dir == 0:
		return

	_break_tile_with_raycast(Vector2(BREAK_RAY_SIDE_LENGTH * dir, 0))

func _check_foreground_tile() -> void:
	if foreground == null:
		if Global.no_gravity==false:
			current_gravity = default_gravity
		return

	var tile_pos: Vector2i = foreground.local_to_map(foreground.to_local(global_position))
	var src_id: int = foreground.get_cell_source_id(0, tile_pos)
	if src_id != -1:
		current_gravity = 0.0 # sets gravity at lvl 2 to be 0
		if Input.is_action_just_pressed('down'):
			velocity.y = -Global.jump
	elif Global.no_gravity==false:
		current_gravity = default_gravity

func _physics_process(delta: float) -> void:
	# reduce cooldown
	break_cooldown = max(0.0, break_cooldown - delta)
	if Global.no_gravity==true:
		current_gravity=0
	# Update gravity based on foreground
	_check_foreground_tile()

	# --- VERTICAL MOVEMENT LOGIC ---
	if current_gravity > 0:
		# Standard Gravity Mode: Jump logic
		if current_stamina > 0:
			if Input.is_action_just_pressed("jump"):
				current_stamina = max(0, current_stamina - 2)
				staminachanged.emit()
				velocity.y = Global.jump
				mmusic.play()  # play jump sound
	else:
		# Zero Gravity Mode: Move Up/Down at constant speed
		var v_dir = Input.get_axis("jump", "down")
		# Using JUMP_VELOCITY magnitude for consistency or SPEED. 
		# v_dir is negative for jump (up) and positive for down.
		velocity.y = v_dir * Global.speed

	# Track last key pressed
	if Input.is_action_just_pressed("regen"):
		current_stamina=Global.total_stamina
	if Input.is_action_just_pressed("left"):
		last_direction = -1
		_on_regen_timer_timeout()
	elif Input.is_action_just_pressed("right"):
		last_direction = 1
		_on_regen_timer_timeout()

	var left_pressed = Input.is_action_pressed("left")
	var right_pressed = Input.is_action_pressed("right")

	var direction := 0
	if last_direction == -1 and left_pressed:
		direction = -1
	elif last_direction == 1 and right_pressed:
		direction = 1

	# Horizontal movement
	velocity.x = direction * Global.speed if direction != 0 else 0

	# Apply gravity BEFORE move_and_slide
	if not is_on_floor() and current_gravity > 0:
		velocity += Vector2(0, current_gravity * delta)

	# Set sprite animations
	if direction != 0:
		sprite.flip_h = direction < 0
		if not sprite.is_playing() or sprite.animation != "moving_right":
			sprite.play("moving_right")
	else:
		if Input.is_action_pressed("jump"):
			if not sprite.is_playing() or sprite.animation != "jump":
				sprite.play("jump")
		else:
			if not sprite.is_playing() or sprite.animation != "idle":
				sprite.play("idle")

	# Move and IMMEDIATELY check ceiling collision
	move_and_slide()


	if break_cooldown <= 0.0:
		if is_on_ceiling():
			break_tile_above()
		elif is_on_wall():
			var dir := 0
			if last_direction != 0:
				dir = last_direction
			elif velocity.x != 0:
				dir = int(sign(velocity.x))

			if dir != 0:
				break_tile_side(dir)
