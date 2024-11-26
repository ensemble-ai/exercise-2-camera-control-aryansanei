class_name PositionLockCamera
extends CameraControllerBase

func _ready() -> void:
	super()
	position = target.position
	make_current()

func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic() 

	# Center the camera on the vessel
	global_position = target.global_position + Vector3(0.0, dist_above_target, 0.0)

# Draw a cross centered on the vessel
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
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y + 0.5, global_position.z)

	await get_tree().process_frame
	mesh_instance.queue_free()
