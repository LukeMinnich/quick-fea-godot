tool
extends FeaBase

signal moved_frame_end(payload)

class_name FeaFrame

# Coordinates in FEA and Godot world coordinate system
export (String) var uuid setget set_uuid, get_uuid
export (Vector3) var end_i setget set_end_i
export (Vector3) var end_j setget set_end_j
export (Resource) var shape = shape as ShapeOutlineResource setget set_shape
export (float) var cross_section_rotation setget set_cross_section_rotation
export (bool) var selected setget set_selected

var _frame_selected : SpatialMaterial = preload("res://assets/materials/frame_selected.tres")
var _frame_unselected : SpatialMaterial = preload("res://assets/materials/frame_unselected.tres")
var _wireframe_dark : SpatialMaterial = preload("res://assets/materials/wireframe_dark.tres")

onready var _extrusion = get_node("Extrusion") as CSGPolygon
onready var _hole_extrusion = get_node("Extrusion/Hole") as CSGPolygon
onready var _wireframe = get_node("Wireframe") as MeshInstance
onready var _centerline = get_node("Centerline") as MeshInstance
onready var _pickable_collider = get_node("PickableArea/CollisionShape").shape as BoxShape

const STICK_SIZE := 0.0254                   # Converts inches to meters in world space, TODO remove this hack
const PICKABLE_COLLIDER_SIZE := 2.5

var _cross_section : ShapeOutline
var _readied := false


func _ready():
	var _success = ViewEvents.connect("toggle_centerline_mode", self, "_on_toggle_centerline_mode")
	
	update_length()
	update_orientation()
	update_centerline()
	update_extrusions()
	update_wireframe()
	update_pickable_collider()
	update_centerline_material()
	update_extrusion_material()


func set_uuid(value: String) -> void:
	uuid = value


func get_uuid() -> String:
	if uuid == "":
		# Uninitialized uuid possible when adding elements to scene algorithimically
		return name
	return uuid


func set_end_i(value: Vector3) -> void:
	end_i = value
	
	if Engine.is_editor_hint():
		update_length()
		update_orientation()
	
	emit_signal("moved_frame_end", { end="i", to=value })


func set_end_j(value: Vector3) -> void:
	end_j = value
	
	if Engine.is_editor_hint():
		update_length()
		update_orientation()
	
	emit_signal("moved_frame_end", { end="j", to=value })


func set_shape(value: ShapeOutlineResource) -> void:
	shape = value
	
	# Unfortunately this cannot be put into ShapeOutlineResource since the way "tools"
	# initialize resources is enigmatic
	match value.outline_kind:
		ShapeOutline.Kind.WIDE_FLANGE:
			_cross_section = Shapes.wide_flange_2d(value.properties)
		ShapeOutline.Kind.SOLID_CIRCULAR_TUBE:
			_cross_section = Shapes.circular_tube_solid_2d(value.properties)
		ShapeOutline.Kind.HOLLOW_CIRCULAR_TUBE:
			_cross_section = Shapes.circular_tube_hollow_2d(value.properties)
		_:
			assert("Invalid kind of ShapeOutline.")
	
	if Engine.is_editor_hint():
		update_extrusions()
		update_wireframe()
		update_pickable_collider()


func set_cross_section_rotation(value: float) -> void:
	cross_section_rotation = value
	rotation_degrees.z = -value


func set_selected(value: bool) -> void:
	selected = value
	
	if Engine.is_editor_hint():
		update_centerline_material()
		update_extrusion_material()
	

# The stick grows out from the insertion point
func update_length() -> void:
	scale = Vector3(STICK_SIZE, STICK_SIZE, end_i.distance_to(end_j))


func update_orientation() -> void:
	if not end_i.is_equal_approx(end_j):
		look_at_from_position(end_i, end_j, Vector3(1, 0, 0) if is_vertical() else Vector3(0, 1, 0))


func update_centerline() -> void:
	_centerline.set_mesh(centerline())
	
	# A bug in Godot 3.2 (https://github.com/godotengine/godot/issues/23707)
	# automatically resets the material when the mesh is changed
	# so it must be set manually
	update_centerline_material()


func update_centerline_material() -> void:
	_centerline.set("material/0", _frame_selected if selected else _frame_unselected)


func update_extrusions() -> void:
	if _cross_section && _extrusion:
		_extrusion.polygon = _cross_section.get_points()
	if _cross_section && _hole_extrusion:
		if _cross_section.has_hole():
			_hole_extrusion.visible = true
			_hole_extrusion.polygon = _cross_section.get_hole()
		else:
			_hole_extrusion.visible = false
			_hole_extrusion.polygon = PoolVector2Array()


func update_extrusion_material() -> void:
	_extrusion.set("material", _frame_selected if selected else _frame_unselected)
	if _cross_section.has_hole():
		_hole_extrusion.set("material", _frame_selected if selected else _frame_unselected)		


func update_wireframe() -> void:
	if _wireframe:
		update_wireframe_mesh()
		
		# A bug in Godot 3.2 (https://github.com/godotengine/godot/issues/23707)
		# automatically resets the material when the mesh is changed
		# so it must be set manually
		update_wireframe_material()


func update_pickable_collider() -> void:
	if _pickable_collider:
		_pickable_collider.extents = Vector3(PICKABLE_COLLIDER_SIZE, PICKABLE_COLLIDER_SIZE, _pickable_collider.extents.z)


func update_wireframe_mesh() -> void:
	var mesh = wireframe_extrusion(_cross_section.get_points())
	if _cross_section.has_hole():
		# Merge extrusion and hole meshes
		_wireframe.set_mesh(wireframe_extrusion(_cross_section.get_hole(), mesh))
	else:
		_wireframe.set_mesh(mesh)


func update_wireframe_material() -> void:
	if _cross_section:
		_wireframe.set("material/0", _wireframe_dark)
		
		if _cross_section.has_hole():
			_wireframe.set("material/1", _wireframe_dark)


func is_vertical() -> bool:
	return is_equal_approx(end_i.x, end_j.x) and is_equal_approx(end_i.z, end_j.z)


func centerline() -> Mesh:
	var draw = SurfaceTool.new()
	draw.begin(Mesh.PRIMITIVE_LINE_STRIP)
	draw.add_vertex(Vector3(0, 0, 0))
	draw.add_vertex(Vector3(0, 0, -1))
	return draw.commit()
	

static func wireframe_extrusion(vertices2d: PoolVector2Array, merge_with: Mesh = null) -> Mesh:
	var size: int = vertices2d.size()
	var vertices := PoolVector3Array()
	vertices.resize(6 * size)
	var v: Vector2
	
	for i in range(size):
		v = vertices2d[i]		
		vertices[2 * i + 1] = Vector3(v.x, v.y, 0)
		vertices[2 * (i + size) + 1] = Vector3(v.x, v.y, -1)
	
	for i in range(size):
		if i == 0:
			vertices[2 * i] = vertices[2 * size - 1]
			vertices[2 * (i + size)] = vertices[4 * size - 1]
		else:
			vertices[2 * i] = vertices[2 * i - 1]
			vertices[2 * (i + size)] = vertices[2 * (i + size) - 1]
	
	for i in range(size):
		vertices[2 * (i + 2 * size)] = vertices[2 * i + 1]
		vertices[2 * (i + 2 * size) + 1] = vertices[2 * (i + size) + 1]
	
	var draw := SurfaceTool.new()
	draw.begin(Mesh.PRIMITIVE_LINES)
	for vertex in vertices:
		draw.add_vertex(vertex)
	draw.index()
	return draw.commit(merge_with)


func select() -> void:
	selected = true
	update_centerline_material()
	update_extrusion_material()


func deselect() -> void:
	selected = false
	update_centerline_material()
	update_extrusion_material()
	

func _on_toggle_centerline_mode(centerline_mode: bool):
	if centerline_mode:
		_extrusion.visible = false
		_wireframe.visible = false
		_centerline.visible = true
	else:
		_extrusion.visible = true
		_wireframe.visible = true
		_centerline.visible = false


func _on_moused_over():
	ViewEvents.emit_signal("hovered_over", self)


func _on_moused_out():
	ViewEvents.emit_signal("hovered_from", self)
