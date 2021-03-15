extends Resource

class_name ShapeOutlineResource

export (Dictionary) var properties
export (int) var outline_kind

var _cross_section : ShapeOutline

# TODO determine how to use _init() or func calls on a Resource correctly.
# When invoked from a GDScript "tool", there are issues with function calls.
# When invoked at runtime, there are issues with exports not defined when _init() is called.
