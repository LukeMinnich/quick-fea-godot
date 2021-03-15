tool
extends FeaBase

class_name FeaNode

export (bool) var selected setget set_selected

var _node_selected : SpatialMaterial = preload("res://assets/materials/node_selected.tres")
var _node_unselected : SpatialMaterial = preload("res://assets/materials/node_unselected.tres")


func set_selected(value: bool) -> void:
	selected = value
	
	if Engine.is_editor_hint():
		update_material()


func select() -> void:
	selected = true
	update_material()


func deselect() -> void:
	selected = false
	update_material()


func update_material() -> void:
	$MeshInstance.set("material/0", _node_selected if selected else _node_unselected)


func _on_moused_over() -> void:
	print("hovering over node")
	ViewEvents.emit_signal("hovered_over", self)


func _on_moused_out() -> void:
	ViewEvents.emit_signal("hovered_from", self)
