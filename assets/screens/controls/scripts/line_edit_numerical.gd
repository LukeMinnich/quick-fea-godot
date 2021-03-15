tool
extends LineEdit

signal number_changed(value)

export (int) var display_precision = 1 setget set_display_precision
export (float) var minimum = 0.0 setget set_minimum

func set_display_precision(value):
	if value >= 0:
		var formatted = format(_number)
		if formatted.length() <= max_length:
			display_precision = value
			text = formatted


func set_minimum(value):
	minimum = value


var _number: float
var _number_on_enter: float

func _ready():
	validate_input_and_update_if_valid()
	emit_signal("number_changed", _number)


func _on_LineEditNumerical_focus_entered():
	_number_on_enter = _number
	select_all()


func _on_LineEditNumerical_focus_exited():
	validate_input_and_update_if_valid()
	emit_signal("number_changed", _number)


func _on_LineEditNumerical_text_entered(new_text):
	validate_input_and_update_if_valid()
	emit_signal("number_changed", _number)


func validate_input_and_update_if_valid() -> bool:
	var parsed = parse_number(text)
	var formatted = format(parsed)
	
	if formatted.length() > max_length:
		print("tried to enter too-long a number")
		text = format(_number)
		return false

	_number = parsed
	text = formatted
	return true


func parse_number(text: String):
	var parsed = float(text)
	if parsed == 0:
		# Invalid parse
		return _number_on_enter if _number_on_enter else minimum
	else:
		return max(parsed, minimum)


func format(value: float):
	var format_string: String = "%%.%sf" % display_precision
	return format_string % value
