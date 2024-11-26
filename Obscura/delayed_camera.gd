class_name DelayedCamera
extends CameraControllerBase

@export var catchup_speed: float = 5.0 # Speed at which the camera travels to reach the vessel one the vessel stops moving
@export var follow_speed: float = 8.0 # Speed at which the camera follows the vessel
@export var leash_distance: float = 15.0 # How far the vessel can be from the cross/camera

func _ready() -> void:
	super() 
	if target:
		global_position = target.global_position + Vector3(0.0, dist_above_target, 0.0)  # Used to track/locate the position of the vessel
	make_current() 

func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic() 

	if target:
		# Get the distance between the camera and the target
		var distance_to_target = global_position.distance_to(target.global_position)

		# If the distance to the vessel > leash distance, move the camera towards the player at follow_speed
		if distance_to_target > leash_distance:
			global_position = global_position.lerp(target.global_position + Vector3(0.0, dist_above_target, 0.0), catchup_speed * delta)
		else:
			# If the vessel is still, move the camera toward the vessel at catchup_speed
			global_position = global_position.lerp(target.global_position + Vector3(0.0, dist_above_target, 0.0), follow_speed * delta)

# Draw the cross
func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	immediate_mesh.surface_add_vertex(Vector3(-2.5, 0.5, 0))
	immediate_mesh.surface_add_vertex(Vector3(2.5, 0.5, 0))

	immediate_mesh.surface_add_vertex(Vector3(0, 0.5, -2.5))
	immediate_mesh.surface_add_vertex(Vector3(0, 0.5, 2.5))

	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK

	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	if target:
		mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	await get_tree().process_frame
	mesh_instance.queue_free()
