extends CameraControllerBase

@export var top_left: Vector2 = Vector2(-13, 7)  # Top-left corner of the frame
@export var bottom_right: Vector2 = Vector2(13, -7) # Bottom-right corner of the frame
@export var autoscroll_speed: Vector3 = Vector3(0.0, 0, 0)  # Autoscroll speed along x and z axes

# Track the camera's frame position
var frame_position: Vector3

func _ready() -> void:
	if target == null:
		target = get_node_or_null("../Vessel")
		if target == null:
			print("Error: target is null in _ready")
	frame_position = global_transform.origin  # Start the frame at the camera's initial position

func _process(delta: float) -> void:
	if target == null:
		print("Error: target is null in _process")
		return

	# Autoscroll the frame position
	frame_position.x += autoscroll_speed.x * delta
	frame_position.z += autoscroll_speed.z * delta

	# Update the camera's position to follow the autoscroll
	global_transform.origin = frame_position

	# Handle player confinement within the scrolling frame
	handle_player_position(delta)

	# Draw the frame box if debugging is enabled
	if draw_camera_logic:
		draw_frame_box()

# Function to handle player confinement within the frame box
func handle_player_position(delta: float) -> void:
	var player_pos = target.global_transform.origin

	# Define the box boundaries in world space
	var left_edge = frame_position.x + top_left.x
	var right_edge = frame_position.x + bottom_right.x
	var top_edge = frame_position.z + top_left.y
	var bottom_edge = frame_position.z + bottom_right.y

	# Check if the player is outside the box and apply constraints
	if player_pos.x < left_edge:
		# Push the player forward to the left edge of the box
		player_pos.x = left_edge
	elif player_pos.x > right_edge:
		player_pos.x = right_edge

	if player_pos.z < bottom_edge:
		player_pos.z = bottom_edge
	elif player_pos.z > top_edge:
		player_pos.z = top_edge

	# Update the player's position if it has been adjusted
	target.global_transform.origin = player_pos

# Function to draw the frame border box
func draw_frame_box() -> void:
	# Clear previous debug drawings
	for child in get_children():
		if child.name == "DebugFrameBox":
			child.queue_free()

	# Create an ArrayMesh for the frame border
	var frame_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	# Define vertices based on the frame bounds
	var vertices = PackedVector3Array([
		Vector3(top_left.x, 0, top_left.y),
		Vector3(bottom_right.x, 0, top_left.y),
		Vector3(bottom_right.x, 0, bottom_right.y),
		Vector3(top_left.x, 0, bottom_right.y),
		Vector3(top_left.x, 0, top_left.y)  # Close the loop
	])

	arrays[Mesh.ARRAY_VERTEX] = vertices

	# Define indices to connect the vertices with lines
	var indices = PackedInt32Array([0, 1, 2, 3, 4])
	arrays[Mesh.ARRAY_INDEX] = indices

	# Add the surface to the mesh
	frame_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)

	# Create a MeshInstance3D to hold the frame border mesh
	var frame_instance = MeshInstance3D.new()
	frame_instance.mesh = frame_mesh
	frame_instance.name = "DebugFrameBox"
	frame_instance.material_override = get_debug_material()  # Apply red material for visibility

	# Add the frame to the camera for visualization
	add_child(frame_instance)

# Helper function to create a red material for the debug frame box
func get_debug_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)  # Red color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return material
