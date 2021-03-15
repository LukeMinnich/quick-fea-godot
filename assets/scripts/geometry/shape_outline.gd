extends Reference

class_name ShapeOutline

enum Kind {WIDE_FLANGE, SOLID_CIRCULAR_TUBE, HOLLOW_CIRCULAR_TUBE}

var _points: PoolVector2Array setget ,get_points
var _hole: PoolVector2Array setget ,get_hole
var _rect: Rect2
var _kind: int setget ,get_kind


func get_points():
	return _points
	

func get_hole():
	return _hole


func get_kind():
	return _kind
	

func get_rect():
	return _rect
	

func _init(kind: int, points: PoolVector2Array, hole: PoolVector2Array,	rect: Rect2, force_closed := false):
	if force_closed && ! points[0].is_equal_approx(points[-1]):
		points.append(points[0])
		hole.append(hole[0])
	_points = points
	_hole = hole
	_rect = rect
	_kind = kind


func has_hole() -> bool:
	return _hole && _hole.size() > 0
