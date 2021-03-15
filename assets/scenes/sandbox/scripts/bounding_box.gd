tool
extends Spatial

onready var _wireframe = get_node("Wireframe") as MeshInstance

var _wireframe_dark: SpatialMaterial = preload("res://assets/materials/wireframe_dark.tres")


func _ready():
	var _success = ViewEvents.connect("model_extents_changed", self, "_on_model_extents_changed")


func _on_model_extents_changed() -> void:
	var model := get_parent() as VisibilityNotifier
	print(model.name)
	if model:
		var bounding_box: AABB = model.get_aabb()
		bounding_box = bounding_box.grow(1.0)
		translation = bounding_box.position + 0.5 * bounding_box.size
		scale = bounding_box.size
