extends Spatial

# Acts as an interface / abstract class for Fea Element classes
class_name FeaBase


func select() -> void:
	assert(false, "Missing implementation in child class.")


func deselect() -> void:
	assert(false, "Missing implementation in child class.")


func get_uuid() -> String:
	assert(false, "Missing implementation in child class.")
	return ""
