class_name CameraControllerBase
extends Camera3D

@export var target: Vessel
@export var dist_above_target: float = 10.0
@export var zoom_speed: float = 10.0
@export var min_zoom: float = 5.0
@export var max_zoom: float = 100.0
@export var draw_camera_logic: bool = false

func _ready() -> void:
	current = false
	position += Vector3(0.0, dist_above_target, 0.0)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fire1"):
		draw_camera_logic = !draw_camera_logic
	
	if Input.is_action_pressed("zoom_in"):
		dist_above_target = clampf(
			dist_above_target - zoom_speed * delta, 
			min_zoom, 
			max_zoom
		)
	
	if Input.is_action_pressed("zoom_out"):
		dist_above_target = clampf(
			dist_above_target + zoom_speed * delta, 
			min_zoom, 
			max_zoom
		)
	
	position.y = target.position.y + dist_above_target

func draw_logic() -> void:
	pass
