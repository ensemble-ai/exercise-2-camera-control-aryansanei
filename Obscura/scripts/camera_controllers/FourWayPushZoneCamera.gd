# File: SpeedupPushZoneCamera.gd
extends CameraControllerBase

@export var push_ratio: float = 1.5
@export var pushbox_top_left: Vector2 = Vector2(-13, 7)
@export var pushbox_bottom_right: Vector2 = Vector2(13, -7)
@export var speedup_zone_top_left: Vector2 = Vector2(-2, 2)
@export var speedup_zone_bottom_right: Vector2 = Vector2(2, -2)

var camera_position: Vector3

func _ready() -> void:
	if target == null:
		target = get_node_or_null("../Vessel")
		if target == null:
			print("Error: target is null in _ready")
	camera_position = global_transform.origin

func _process(delta: float) -> void:
	if target == null:
		print("Error: target is not assigned in _process")
		return

	handle_camera_movement(delta)

	if draw_camera_logic:
		draw_zones()

func handle_camera_movement(delta: float) -> void:
	var target_pos = target.global_transform.origin
	var target_velocity = target.velocity

	var pushbox_left = camera_position.x + pushbox_top_left.x
	var pushbox_right = camera_position.x + pushbox_bottom_right.x
	var pushbox_top = camera_position.z + pushbox_top_left.y
	var pushbox_bottom = camera_position.z + pushbox_bottom_right.y

	var speedup_left = camera_position.x + speedup_zone_top_left.x
	var speedup_right = camera_position.x + speedup_zone_bottom_right.x
	var speedup_top = camera_position.z + speedup_zone_top_left.y
	var speedup_bottom = camera_position.z + speedup_zone_bottom_right.y

	var move_vector = Vector3.ZERO

	if target_pos.x > speedup_left and target_pos.x < speedup_right and target_pos.z > speedup_bottom and target_pos.z < speedup_top:
		return
	elif target_pos.x > pushbox_left and target_pos.x < pushbox_right and target_pos.z > pushbox_bottom and target_pos.z < pushbox_top:
		move_vector.x = target_velocity.x * push_ratio * delta
		move_vector.z = target_velocity.z * push_ratio * delta
	else:
		move_vector.x = target_velocity.x * delta
		move_vector.z = target_velocity.z * delta

		if target_pos.x <= pushbox_left or target_pos.x >= pushbox_right:
			move_vector.x = target_velocity.x * delta
			move_vector.z *= push_ratio
		if target_pos.z <= pushbox_bottom or target_pos.z >= pushbox_top:
			move_vector.z = target_velocity.z * delta
			move_vector.x *= push_ratio

	camera_position += move_vector
	global_transform.origin = camera_position

# Function to draw the pushbox and speedup zone borders
func draw_zones() -> void:
	for child in get_children():
		if child.name == "DebugZone":
			child.queue_free()

	# Draw the pushbox border in red
	draw_border(pushbox_top_left, pushbox_bottom_right, Color(1, 0, 0))

	# Draw the speedup zone border in green
	draw_border(speedup_zone_top_left, speedup_zone_bottom_right, Color(0, 1, 0))

# Helper function to create a border box aligned with the camera's top-down view
func draw_border(top_left: Vector2, bottom_right: Vector2, color: Color) -> void:
	var border_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	# Define the vertices of the box based on the specified coordinates
	var vertices = PackedVector3Array([
		Vector3(camera_position.x + top_left.x, 0, camera_position.z + top_left.y),       # Upper left corner
		Vector3(camera_position.x + bottom_right.x, 0, camera_position.z + top_left.y),   # Upper right corner
		Vector3(camera_position.x + bottom_right.x, 0, camera_position.z + bottom_right.y), # Lower right corner
		Vector3(camera_position.x + top_left.x, 0, camera_position.z + bottom_right.y),     # Lower left corner
		Vector3(camera_position.x + top_left.x, 0, camera_position.z + top_left.y)        # Closing the loop to upper left
	])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices

	# Define indices for line segments to draw the outline
	var indices = PackedInt32Array([0, 1, 2, 3, 4])

	# Add the surface to create a line loop for the border
	border_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)

	# Create a MeshInstance3D to hold the border mesh
	var border_instance = MeshInstance3D.new()
	border_instance.mesh = border_mesh
	border_instance.name = "DebugZone"

	# Create and assign the color material for the border
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	border_instance.material_override = material

	add_child(border_instance)
