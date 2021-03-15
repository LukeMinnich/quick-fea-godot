extends ColorRect

const SHAPE_PADDING := 30  # pixels
const SHAPE_LINEWEIGHT := 5.0  # pixels
const TICK_LENGTH := 10.0  # pixels
const TICK_SPACING := 1.0  # model units

var _zoom_scale := 1.0  # for model units -> pixels conversions
var _dimensions: Dictionary

signal resized_drawing(bg_rect_size)


func _ready():
	$Timer.start()
	# center shape on drawing area
	emit_signal("resized_drawing", rect_size)


func _draw():
	var shape
	if _dimensions:
		shape = Shapes.wide_flange_2d(_dimensions)
	else:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		shape = random_wide_flange(rng)
	_zoom_scale = determine_zoom_scale(shape, SHAPE_PADDING)
	$Outline.points = shape._points
	$Outline.scale = Vector2(_zoom_scale, _zoom_scale)
	$Outline.width = SHAPE_LINEWEIGHT / _zoom_scale
	draw_x_axis(self.rect_size, _zoom_scale)
	draw_y_axis(self.rect_size, _zoom_scale)


func _on_Timer_timeout():
	update()


func _on_SectionDrawing_resized():
	emit_signal("resized_drawing", rect_size)


func determine_zoom_scale(shape: ShapeOutline, padding: float) -> float:
	var available_height = clamp(rect_size.y - 2 * SHAPE_PADDING, 0, rect_size.y)
	var available_width = clamp(rect_size.x - 2 * SHAPE_PADDING, 0, rect_size.x)
	var width_ratio = available_width / shape._rect.size.x
	var height_ratio = available_height / shape._rect.size.y
	return min(width_ratio, height_ratio)


func randomize_bg_size(rng: RandomNumberGenerator) -> Vector2:
	var x = rng.randf_range(200, 400)
	var y = rng.randf_range(200, 400)
	return Vector2(x, y)


func centered_bg(bg_size: Vector2, viewport_rect: Rect2) -> Vector2:
	return Vector2(0.5 * (viewport_rect.size.x - bg_size.x), 0.5 * (viewport_rect.size.y - bg_size.y))


func draw_x_axis(bg_size: Vector2, zoom: float):
	var start = Vector2(0, bg_size.y / 2)
	var end = Vector2(bg_size.x, bg_size.y / 2)
	draw_axis(start, end)
	draw_axis_tick_marks("x", start, end, zoom)


func draw_y_axis(bg_size: Vector2, zoom: float):
	var start = Vector2(bg_size.x / 2, 0)
	var end = Vector2(bg_size.x / 2, bg_size.y)
	draw_axis(start, end)
	draw_axis_tick_marks("y", start, end, zoom)


func draw_axis_tick_marks(axis: String, axis_start: Vector2, axis_end: Vector2, zoom: float):
	var positive_half_axis: Vector2 = 0.5 * (axis_end - axis_start)
	var grid_center: Vector2 = axis_start + positive_half_axis
	var subdivisions_half_axis: float = floor(positive_half_axis[axis] / (TICK_SPACING * zoom))

	var subdivision_interval: Vector2 = (Vector2.RIGHT if axis == "x" else Vector2.DOWN) * (TICK_SPACING * zoom)
	var direction: Vector2 = Vector2.DOWN if axis == "x" else Vector2.RIGHT

	for i in range(subdivisions_half_axis):
		var start = grid_center + i * subdivision_interval
		var end = start + TICK_LENGTH * direction
		draw_axis(start, end)

		start = grid_center - i * subdivision_interval
		end = start + TICK_LENGTH * direction
		draw_axis(start, end)


func draw_axis(start: Vector2, end: Vector2):
	draw_line(start, end, Color.black, 1.0)


func random_wide_flange(rng: RandomNumberGenerator) -> ShapeOutline:
	var d = rng.randf_range(6, 36)
	var bf = rng.randf_range(4, d)
	var tw = rng.randf_range(bf / 16, bf / 8)
	var tf = rng.randf_range(d / 16, d / 8)

	var dimensions = {d = d, bf = bf, tf = tf, tw = tw}

	return Shapes.wide_flange_2d(dimensions)


func _on_SectionDimensions_update_dimensions(dimensions):
	_dimensions = dimensions
	update()
