# File: PositionLockLerpCamera.gd
extends CameraControllerBase

@export var follow_speed: float = 5.0
@export var catchup_speed: float = 10.0
@export var leash_distance: float = 10.0

# Single cross instance
var cross_instance: MeshInstance3D = null

func _ready() -> void:
	if target == null:
		# Try to find the target node in code if not assigned
		target = get_node_or_null("../Vessel")
		if target == null:
			print("Error: target is null in _ready")
		else:
			print("Target assigned in _ready: ", target.name)
	else:
		print("Target already assigned in Inspector: ", target.name)

	# Draw the cross once at the camera's center
	draw_cross_in_camera_center()

func _process(delta: float) -> void:
	if target == null:
		print("Error: target is null in _process")
		return  # Exit if target is not assigned

	super._process(delta)

	# Camera movement logic with delay
	var cam_pos_2d = Vector2(position.x, position.z)
	var target_pos_2d = Vector2(target.position.x, target.position.z)
	var distance = cam_pos_2d.distance_to(target_pos_2d)

	# Determine move speed based on target's movement
	var target_velocity = Vector2.ZERO
	if target is CharacterBody3D:
		var vel_3d = target.velocity
		target_velocity = Vector2(vel_3d.x, vel_3d.z)
	var target_speed = target_velocity.length()

	# Set move speed based on whether the target is moving
	var move_speed = follow_speed if target_speed > 0.1 else catchup_speed

	# Smoothly move the camera towards the target without centering immediately
	if distance > 0.01:
		var direction = (target_pos_2d - cam_pos_2d).normalized()
		var move_distance = min(move_speed * delta, distance)
		cam_pos_2d += direction * move_distance

	# Enforce leash distance
	if cam_pos_2d.distance_to(target_pos_2d) > leash_distance:
		var leash_direction = (cam_pos_2d - target_pos_2d).normalized()
		cam_pos_2d = target_pos_2d + leash_direction * leash_distance

	# Update camera's position with the delayed movement
	position.x = cam_pos_2d.x
	position.z = cam_pos_2d.y

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
	cross_instance.transform.origin = Vector3(0, 0, 0)  # Adjust Z to keep it in view

	# Add the cross as a child of the camera so it stays centered
	add_child(cross_instance)
