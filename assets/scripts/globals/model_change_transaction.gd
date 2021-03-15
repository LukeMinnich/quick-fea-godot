extends Reference

class_name ModelChangeTransaction

var _data: Array


static func _from_single(message: ModelChangeMessage) -> ModelChangeTransaction:
	var trans := ModelChangeTransaction.new()
	trans._data = [message]
	return trans


static func _from_many(messages: Array) -> ModelChangeTransaction:
	var trans := ModelChangeTransaction.new()
	trans._data = messages
	return trans


func do() -> bool:
	# TODO implementation
	return true
