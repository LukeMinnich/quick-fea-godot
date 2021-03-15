extends Reference

class_name Stack

var _data: LinkedList

func _init():
	_data = LinkedList.new()


func push(item):
	_data.push_front(item)


func pop(item):
	return _data.pop_front()
