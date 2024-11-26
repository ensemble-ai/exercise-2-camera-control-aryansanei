class_name PushZoneCamera
extends CameraControllerBase

@export var box_width: float = 10.0
@export var box_height: float = 10.0
@export var inner_box_width: float = 6.0
@export var inner_box_height: float = 6.0
@export var speedup_factor: float = 0.5  # Speedup ratio for the speedup zone

func _ready() -> void:
	super()
	position = target.position

func _process(delta: float) -> void:
	if !current:
		return

	if draw_camera_logic:
		draw_logic()

	var tpos = target.global_position
	var cpos = global_position

	# Outer box boundaries
	var diff_left = (tpos.x - target.WIDTH * 1.38) - (cpos.x - box_width * 1.38)
	if diff_left < 0:
		global_position.x += diff_left

	var diff_right = (tpos.x + target.WIDTH * 1.38) - (cpos.x + box_width * 1.38)
	if diff_right > 0:
		global_position.x += diff_right

	var diff_top = (tpos.z - target.HEIGHT * 0.7) - (cpos.z - box_height * 0.7)
	if diff_top < 0:
		global_position.z += diff_top

	var diff_bottom = (tpos.z + target.HEIGHT * 0.7) - (cpos.z + box_height * 0.7)
	if diff_bottom > 0:
		global_position.z += diff_bottom

	# Speedup zone logic
	var inner_left = cpos.x - inner_box_width * 1.7
	var outer_left = cpos.x - box_width * 1.38
	if tpos.x < inner_left and tpos.x > outer_left:
		global_position.x += (tpos.x - cpos.x) * speedup_factor * delta

	var inner_right = cpos.x + inner_box_width * 1.7
	var outer_right = cpos.x + box_width * 1.38
	if tpos.x > inner_right and tpos.x < outer_right:
		global_position.x += (tpos.x - cpos.x) * speedup_factor * delta

	var inner_top = cpos.z - inner_box_height * 0.8
	var outer_top = cpos.z - box_height * 0.7
	if tpos.z < inner_top and tpos.z > outer_top:
		global_position.z += (tpos.z - cpos.z) * speedup_factor * delta

	var inner_bottom = cpos.z + inner_box_height * 0.8
	var outer_bottom = cpos.z + box_height * 0.7
	if tpos.z > inner_bottom and tpos.z < outer_bottom:
		global_position.z += (tpos.z - cpos.z) * speedup_factor * delta

	super(delta)

func draw_logic() -> void:
	# Outer box drawing
	var outer_mesh_instance = MeshInstance3D.new()
	var outer_immediate_mesh = ImmediateMesh.new()
	var outer_material = ORMMaterial3D.new()

	outer_mesh_instance.mesh = outer_immediate_mesh
	outer_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var left = -box_width * 1.3
	var right = box_width * 1.3
	var top = -box_height * 0.7
	var bottom = box_height * 0.7

	outer_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, outer_material)
	outer_immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	outer_immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	outer_immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	outer_immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	outer_immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	outer_immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	outer_immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	outer_immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	outer_immediate_mesh.surface_end()

	outer_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outer_material.albedo_color = Color.BLACK

	add_child(outer_mesh_instance)
	outer_mesh_instance.global_transform = Transform3D.IDENTITY
	outer_mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	# Inner box drawing
	var inner_mesh_instance = MeshInstance3D.new()
	var inner_immediate_mesh = ImmediateMesh.new()
	var inner_material = ORMMaterial3D.new()

	inner_mesh_instance.mesh = inner_immediate_mesh
	inner_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var inner_left = -inner_box_width * 1.7
	var inner_right = inner_box_width * 1.7
	var inner_top = -inner_box_height * 0.8
	var inner_bottom = inner_box_height * 0.8

	inner_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, inner_material)
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_top))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_bottom))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_bottom))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_bottom))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_bottom))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_top))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_left, 0, inner_top))
	inner_immediate_mesh.surface_add_vertex(Vector3(inner_right, 0, inner_top))
	inner_immediate_mesh.surface_end()

	inner_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner_material.albedo_color = Color.BLACK

	add_child(inner_mesh_instance)
	inner_mesh_instance.global_transform = Transform3D.IDENTITY
	inner_mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	# Free meshes after drawing
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	outer_mesh_instance.queue_free()
	inner_mesh_instance.queue_free()
