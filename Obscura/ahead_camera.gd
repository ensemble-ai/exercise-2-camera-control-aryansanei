class_name AheadCamera
extends CameraControllerBase

@export var lead_speed: float = 8.0
@export var leash_distance: float = 20.0

func _ready() -> void:
	position = target.position + Vector3(0.0, dist_above_target, 0.0)
	make_current()

func _process(delta: float) -> void:
	if !current:
		return

	var target_pos = target.global_position + Vector3(0.0, dist_above_target, 0.0)
	var velocity = target.velocity.normalized()

	if velocity.length() > 0:
		var lead_offset = Vector3(velocity.x, 0.0, velocity.z) * lead_speed
		var desired_pos = target_pos + lead_offset
		position = position.lerp(desired_pos, 0.05)

		if position.distance_to(target.global_position) > leash_distance:
			position = target_pos + lead_offset
	else:
		position = position.lerp(target_pos, 0.01)

	if draw_camera_logic:
		draw_logic()

# Draw a cross to visualize the camera's logic
func draw_logic() -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = ORMMaterial3D.new()

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
	mesh_instance.global_position = Vector3(
		global_position.x, 
		target.global_position.y + 0.5, 
		global_position.z
	)

	await get_tree().process_frame
	mesh_instance.queue_free()
