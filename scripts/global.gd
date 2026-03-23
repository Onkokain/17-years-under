extends Node

var played_count = 0
var total_stamina= 200
var camera_zoom := Vector2(4,4)
var sap=0
var mined_tile_hits := {}
var no_gravity=false
var speed=150.0
var jump = -230.0
var has_escaperope=false
var passed_once=false

func reset_run_state() -> void:
	played_count = 0
	total_stamina = 200
	camera_zoom = Vector2(4,4)
	sap = 0
	mined_tile_hits.clear()
	no_gravity=false
	passed_once=false
	has_escaperope=false
	speed=150.0
	jump = -230.0


func save_tile_damage(tile_pos: Vector2i, hits: int) -> void:
	var key := "%d_%d" % [tile_pos.x, tile_pos.y]
	mined_tile_hits[key] = hits
