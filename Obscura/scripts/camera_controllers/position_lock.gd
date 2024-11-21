extends CameraControllerBase

# Reference to the PushBox instance for synchronization
var push_box_controller: PushBox

func _ready() -> void:
	# Find the PushBox node in the scene and assign it to push_box_controller
	push_box_controller = get_parent().get_node("PushBox")  # Adjust the path as needed

# Keeps the camera centered on the vessel and syncs the cross movement with PushBox
func _process(delta: float) -> void:
	if target and push_box_controller:
		# Set the camera's position to match the vessel's position plus height offset
		global_transform.origin = target.global_transform.origin + Vector3(0, 10, 0)

		# Synchronize the cross position with the PushBox controller
		global_transform.origin.x += (push_box_controller.global_position.x - global_transform.origin.x) * delta
		global_transform.origin.z += (push_box_controller.global_position.z - global_transform.origin.z) * delta

	# Draw the cross each frame if needed
	draw_logic()

# Draw a 5x5 unit cross centered on the vessel if draw_camera_logic is true
func draw_logic() -> void:
	if draw_camera_logic:
		#print("Drawing cross logic")  # Debug to verify function is called

		# Define vertices for the cross, centered at the vessel's Z level
		var vertices = PackedVector3Array([
			Vector3(-2.5, 0, 0), Vector3(2.5, 0, 0),    # Horizontal line
			Vector3(0, 0, -2.5), Vector3(0, 0, 2.5)     # Vertical line
		])
		
		# Define indices for lines
		var indices = PackedInt32Array([0, 1, 2, 3])

		# Create an ArrayMesh to hold the cross lines
		var cross_mesh := ArrayMesh.new()
		var arrays := []
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = vertices
		arrays[ArrayMesh.ARRAY_INDEX] = indices
		
		# Add the surface for drawing lines
		cross_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

		# Create a MeshInstance3D for displaying the cross
		var cross_instance = MeshInstance3D.new()
		cross_instance.mesh = cross_mesh
		cross_instance.material_override = StandardMaterial3D.new()
		cross_instance.material_override.albedo_color = Color(1, 1, 1)  # White color for visibility

		# Place the cross at the vessel's Z level to ensure it appears centered on the screen
		cross_instance.transform.origin = target.global_transform.origin
		add_child(cross_instance)

		# Attach to the camera and clean up after one frame
		await get_tree().process_frame
		cross_instance.queue_free()
