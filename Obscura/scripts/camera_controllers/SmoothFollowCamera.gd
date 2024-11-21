extends CameraControllerBase

@export var lead_speed: float = 15.0
@export var follow_speed: float = 5.0
@export var catchup_speed: float = 10.0
@export var leash_distance: float = 10.0
@export var catchup_delay_duration: float = 1.0
@export var max_offset_distance: float = 5.0  # Maximum distance for the cross to lead ahead of the target

# Single cross instance
var cross_instance: MeshInstance3D = null
var catchup_timer: float = 0.0
var input_hold_time: float = 0.0  # Time for which movement input is held
var cross_offset: Vector3 = Vector3.ZERO  # Smooth offset for the cross

func _ready() -> void:
	if target == null:
		target = get_node_or_null("../Vessel")
		if target == null:
			print("Error: target is null in _ready")
		else:
			print("Target assigned in _ready: ", target.name)
	else:
		print("Target already assigned in Inspector: ", target.name)

	# Draw the cross at the camera's center
	draw_cross_in_camera_center()

func _process(delta: float) -> void:
	if target == null:
		print("Error: target is null in _process")
		return  # Exit if target is not assigned

	super._process(delta)

	# Camera movement logic with delay and lead effect
	var target_pos_2d = Vector2(target.position.x, target.position.z)
	var cam_pos_2d = Vector2(position.x, position.z)

	# Check if the player has movement input
	var input_dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	var is_moving = input_dir.length() > 0

	# Smoothly adjust cross offset based on input hold
	if is_moving:
		input_hold_time += delta  # Increase hold time
		var lead_amount = min(input_hold_time * lead_speed, max_offset_distance)  # Limit lead distance
		cross_offset = cross_offset.lerp(Vector3(input_dir.x, 0, input_dir.y).normalized() * lead_amount, delta * 5.0)
		catchup_timer = 0.0  # Reset catchup timer when player is moving
	else:
		input_hold_time = 0.0  # Reset hold time when input stops
		catchup_timer += delta  # Increment catchup timer if no input
		cross_offset = cross_offset.lerp(Vector3.ZERO, delta * 3.0)  # Smooth reset to zero

	# Determine the camera movement direction
	var move_direction = Vector2.ZERO
	var move_speed = follow_speed

	if is_moving:
		# Lead the camera in the input direction
		move_direction = input_dir
		move_speed = lead_speed
	elif catchup_timer >= catchup_delay_duration:
		# Catch up to the target when the player has stopped for `catchup_delay_duration`
		move_direction = (target_pos_2d - cam_pos_2d).normalized()
		move_speed = catchup_speed

	# Move the camera towards the target with the appropriate speed and leash distance
	var distance_to_target = cam_pos_2d.distance_to(target_pos_2d)
	if distance_to_target > 0.01:
		var move_distance = min(move_speed * delta, distance_to_target)
		cam_pos_2d += move_direction * move_distance

	# Enforce leash distance while moving
	if cam_pos_2d.distance_to(target_pos_2d) > leash_distance:
		var leash_direction = (cam_pos_2d - target_pos_2d).normalized()
		cam_pos_2d = target_pos_2d + leash_direction * leash_distance

	# Update camera's position
	position.x = cam_pos_2d.x
	position.z = cam_pos_2d.y

	# Update the cross position based on the smooth offset
	if cross_instance:
		cross_instance.global_transform.origin = global_transform.origin + cross_offset

func draw_cross_in_camera_center() -> void:
	if cross_instance != null:
		return  # Exit if cross already exists

	# Create a MeshInstance3D for the cross
	cross_instance = MeshInstance3D.new()
	cross_instance.name = "CenterCross"

	# Create the cross mesh using ArrayMesh
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var cross_size = 2.5  # Half of 5 units to create a 5x5 cross

	# Define vertices for a centered cross to face the camera, ensuring it remains fixed
	var vertices = PackedVector3Array([
		# Horizontal line (along X-axis)
		Vector3(-cross_size, 0, 0),
		Vector3(cross_size, 0, 0),
		# Vertical line (along Z-axis)
		Vector3(0, -cross_size, 0),
		Vector3(0, cross_size, 0),
	])

	arrays[Mesh.ARRAY_VERTEX] = vertices

	# Define indices for the lines
	var indices = PackedInt32Array([
		0, 1,  # Horizontal line
		2, 3,  # Vertical line
	])

	arrays[Mesh.ARRAY_INDEX] = indices

	# Add the surface to the mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	# Create the material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS

	# Assign the material to the mesh
	mesh.surface_set_material(0, material)

	# Assign the mesh to the MeshInstance3D
	cross_instance.mesh = mesh

	# Position the cross at the camera's center
	cross_instance.transform.origin = Vector3(0, 0, 0)  # Keep it at the center of the camera

	# Add the cross as a child of the camera so it stays centered
	add_child(cross_instance)
