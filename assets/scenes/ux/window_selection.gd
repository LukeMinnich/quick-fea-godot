extends Spatial

# This widget only functions as expected when it is the child of a Camera
# and aligned to the camera's rotation and translation,
# It stretches in the direction of the camera -Z axis

onready var _center := get_node("CenterOfSelection") as Area
onready var _right := get_node("RightOfSelection") as Area
onready var _left := get_node("LeftOfSelection") as Area
onready var _top := get_node("TopOfSelection") as Area
onready var _bottom := get_node("BottomOfSelection") as Area

onready var _center_collider := get_node("CenterOfSelection/Center") as CollisionShape
onready var _right_collider := get_node("RightOfSelection/Right") as CollisionShape
onready var _left_collider := get_node("LeftOfSelection/Left") as CollisionShape
onready var _top_collider := get_node("TopOfSelection/Top") as CollisionShape
onready var _bottom_collider := get_node("BottomOfSelection/Bottom") as CollisionShape

onready var _center_mesh := get_node("CenterOfSelection/MeshInstance") as MeshInstance
onready var _left_mesh := get_node("RightOfSelection/MeshInstance") as MeshInstance
onready var _right_mesh := get_node("LeftOfSelection/MeshInstance") as MeshInstance
onready var _top_mesh := get_node("TopOfSelection/MeshInstance") as MeshInstance
onready var _bottom_mesh := get_node("BottomOfSelection/MeshInstance") as MeshInstance

onready var _blink_timer := get_node("BlinkTimer") as Timer

const SIDE_COLLIDER_WIDTH := 0.1
const NEAR_FAR_OFFSET := 0.01
const MAX_BLINKS := 2

var _blink_count : int

func _ready():
	var _success = ViewEvents.connect("select_within", self, "_on_activate_window_selection")
	
	if not Engine.is_editor_hint():
		visible = false


func _on_activate_window_selection(mode: int, window_rect: Rect2) -> void:
	var only_fully_enclosed: bool = window_rect.size.x > 0
	var elements := []	# TODO refactor with Dictionary
	
	# Change child Areas based on rectangular selection extents
	var camera := get_parent() as Camera
	assert(not camera == null, "Could not find camera relative to window selection widget.")
	
	if camera.projection == Camera.PROJECTION_ORTHOGONAL:
		update_colliders_for_orthographic_projection(camera, window_rect)
		
	if camera.projection == Camera.PROJECTION_PERSPECTIVE:
		print("camera fov: ", camera.fov)
		
	# Wait for physics engine to catch wind of the collider udpates
	# Three frames seems like minimum for using get_overlapping_areas()
	for _i in range(3):
		yield(get_tree(), "physics_frame")
	
	for area in _center.get_overlapping_areas():
		var element := area.get_parent() as FeaBase
		if element && not elements.has(element):
			if only_fully_enclosed:
				var intersected_boundary: Area = get_intersecting_area_at_boundary(area)
				if not intersected_boundary:
					elements.append(element)
			else:
				elements.append(element)
	
	# Commence blinking so user sees their selection window
	blink()
	
	ViewEvents.emit_signal("select_many", mode, elements)
	

func update_colliders_for_orthographic_projection(camera: Camera, window_rect: Rect2):
	var screen_rect: Rect2 = get_viewport().get_visible_rect()
	
	var screen_to_world_ratio: float
	var camera_rect : Rect2		# Viewport in world space, centered on the camera 
	
	if camera.keep_aspect == Camera.KEEP_HEIGHT:
		screen_to_world_ratio = screen_rect.size.y / camera.size
		camera_rect = Rect2(-0.5 * screen_rect.size.x / screen_to_world_ratio, -0.5 * camera.size,
						   screen_rect.size.x / screen_to_world_ratio, camera.size)
	
	elif camera.keep_aspect == Camera.KEEP_WIDTH:
		screen_to_world_ratio = screen_rect.size.x / camera.size
		camera_rect = Rect2(-0.5 * camera.size, -0.5 * screen_rect.size.y / screen_to_world_ratio,
						   camera.size, screen_rect.size.y / screen_to_world_ratio)
	else:
		assert(false, "Unexpected camera state.")
	
	var window_camera_rect := Rect2(
		camera_rect.position.x + window_rect.position.x / screen_to_world_ratio,
		camera_rect.end.y - window_rect.position.y / screen_to_world_ratio,
		window_rect.size.x / screen_to_world_ratio,
		-window_rect.size.y / screen_to_world_ratio)
	
	var window_camera_center : Vector2 = window_camera_rect.position + 0.5 * window_camera_rect.size
	
	""" Position colliders just inside the near and far clipping planes """
	
	scale.z = 0.5 * (camera.far - camera.near) - NEAR_FAR_OFFSET	
	translation.z = -1 * (camera.near + NEAR_FAR_OFFSET + scale.z)
	
	""" Update center collider """
	
	_center.translation = Vector3(window_camera_center.x, window_camera_center.y, 0)
	# Box colliders extents are half their overall dimensions
	_center_collider.shape.extents = Vector3(0.5 * abs(window_camera_rect.size.x), 0.5 * abs(window_camera_rect.size.y), 1)
	sync_mesh_with_box_collider(_center_mesh, _center_collider.shape)
	
	""" Update edge colliders """

	var half_width: float = 0.5 * SIDE_COLLIDER_WIDTH
	
	# Performance would likely marginally improve if using Plane shapes instead of Box shapes for the side colliders
	# but they are expected to be deprecated in Godot 4.0, so use Box shapes instead.
	_right.translation = Vector3(max(window_camera_rect.position.x, window_camera_rect.end.x) + half_width, window_camera_center.y, 0)
	_right_collider.shape.extents = Vector3(half_width, 0.5 * abs(window_camera_rect.size.y), 1)
	sync_mesh_with_box_collider(_right_mesh, _right_collider.shape)

	_left.translation = Vector3(min(window_camera_rect.position.x, window_camera_rect.end.x) - half_width, window_camera_center.y, 0)
	_left_collider.shape.extents = Vector3(half_width, 0.5 * abs(window_camera_rect.size.y), 1)		
	sync_mesh_with_box_collider(_left_mesh, _left_collider.shape)

	_top.translation = Vector3(window_camera_center.x, max(window_camera_rect.position.y, window_camera_rect.end.y) + half_width, 0)
	_top_collider.shape.extents = Vector3(0.5 * abs(window_camera_rect.size.x), half_width, 1)
	sync_mesh_with_box_collider(_top_mesh, _top_collider.shape)

	_bottom.translation = Vector3(window_camera_center.x, min(window_camera_rect.position.y, window_camera_rect.end.y) - half_width, 0)
	_bottom_collider.shape.extents = Vector3(0.5 * abs(window_camera_rect.size.x), half_width, 1)
	sync_mesh_with_box_collider(_bottom_mesh, _bottom_collider.shape)


func sync_mesh_with_box_collider(instance: MeshInstance, shape: BoxShape) -> void:
	if instance && instance.visible:
		# Scale is doubled for mesh to align with the collider shape
		instance.scale = Vector3(2, 2, 2)
		instance.mesh.size = shape.extents


func get_intersecting_area_at_boundary(area: Area) -> Area:
	for item in [_right, _left, _top, _bottom]:
		var adjacent := item as Area
		if adjacent and adjacent.overlaps_area(area):
			return adjacent
	
	return null


func blink():
	visible = true
	_blink_count = 1		# Blinking on counts as a blink
	_blink_timer.start()


func _on_BlinkTimer_timeout():
	visible = not visible
	_blink_count += 1
	
	if _blink_count > MAX_BLINKS * 2 - 1:
		_blink_timer.stop()
		ViewEvents.emit_signal("enable_camera_movement")
