class_name ModelChangeMessage

enum ModelMutationKind { MODIFY, ADD, DELETE }
enum ModelEntityKind { NODE, FRAME_ELEMENT }

var _mutation_kind: int
var _entity_kind: int
var _payload: Dictionary


func _init(mutation_kind: int, entity_kind: int, payload: Dictionary):
	self._mutation_kind = mutation_kind
	self._entity_kind = entity_kind
	self._payload = payload


func print():
	print("mutation kind: ", self._mutation_kind)
	print("entity kind: ", self._entity_kind)
	print("payload text:", self._payload.text if _payload.text else "")
