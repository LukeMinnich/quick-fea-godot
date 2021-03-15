extends Panel

signal update_dimensions(dimensions)

var _input_depth := 1.0
var _input_flange_width := 1.0
var _input_flange_thickness := 1.0
var _input_web_thickness := 1.0

func _ready():
	send_new_dimensions()

func _on_InputDepth_number_changed(value):
	_input_depth = value
	print("updated depth: ", value)
	send_new_dimensions()


func _on_InputFlangeWidth_number_changed(value):
	_input_flange_width = value
	print("updated flange width: ", value)
	send_new_dimensions()


func _on_InputFlangeThickness_number_changed(value):
	_input_flange_thickness = value
	print("updated flange thickness: ", value)
	send_new_dimensions()


func _on_InputWebThickness_number_changed(value):
	_input_web_thickness = value
	print("updated web depth: ", value)
	send_new_dimensions()


func send_new_dimensions():	
	emit_signal("update_dimensions", {
		d = _input_depth,
		bf = _input_flange_width,
		tf = _input_flange_thickness,
		tw = _input_web_thickness
	})
