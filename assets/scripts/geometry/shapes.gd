extends Reference

class_name Shapes

static func wide_flange_2d(dimensions: Dictionary) -> ShapeOutline:
	var d = dimensions.d
	var bf = dimensions.bf
	var tw = dimensions.tw
	var tf = dimensions.tf
	var bounding_box = Rect2(Vector2(-bf / 2, -d / 2), Vector2(bf, d))
	var points = wide_flange_cross_section(bf, tf, d, tw)
	return ShapeOutline.new(ShapeOutline.Kind.WIDE_FLANGE, points, PoolVector2Array(), bounding_box)


static func circular_tube_solid_2d(dimensions: Dictionary) -> ShapeOutline:
	var r = dimensions.r
	var segments = dimensions.segments
	var bounding_box = Rect2(Vector2(-r, -r), Vector2(2 * r, 2 * r))
	var points = circular_cross_section(r, segments)
	return ShapeOutline.new(ShapeOutline.Kind.SOLID_CIRCULAR_TUBE, points, PoolVector2Array(), bounding_box)


static func circular_tube_hollow_2d(dimensions: Dictionary) -> ShapeOutline:
	var ro = dimensions.ro
	var ri = dimensions.ri
	var segments = dimensions.segments
	var bounding_box = Rect2(Vector2(-ro, -ro), Vector2(2 * ro, 2 * ro))
	var points = circular_cross_section(ro, segments)
	var hole = circular_cross_section(ri, segments)
	return ShapeOutline.new(ShapeOutline.Kind.HOLLOW_CIRCULAR_TUBE, points, hole, bounding_box)


static func wide_flange_cross_section(bf: float, tf: float, d: float, tw: float, flip_ys = false) -> PoolVector2Array:
	
	var cross_section = PoolVector2Array()
	cross_section.resize(12)
	
	var xs = [-0.5 * bf, -0.5 * tw, 0.5 * tw, 0.5 * bf]
	var ys = [0.5 * d, 0.5 * d - tf, -0.5 * d + tf, -0.5 * d]
	
	cross_section[0] = Vector2(xs[0], ys[0])
	cross_section[1] = Vector2(xs[3], ys[0])
	cross_section[2] = Vector2(xs[3], ys[1])
	cross_section[3] = Vector2(xs[2], ys[1])
	cross_section[4] = Vector2(xs[2], ys[2])
	cross_section[5] = Vector2(xs[3], ys[2])
	cross_section[6] = Vector2(xs[3], ys[3])
	cross_section[7] = Vector2(xs[0], ys[3])
	cross_section[8] = Vector2(xs[0], ys[2])
	cross_section[9] = Vector2(xs[1], ys[2])
	cross_section[10] = Vector2(xs[1], ys[1])
	cross_section[11] = Vector2(xs[0], ys[1])
		
	if (flip_ys):
		for i in range(12):
			cross_section[i].y *= -1
	
	return cross_section


static func circular_cross_section(r: float, segments: int, flip_ys = false) -> PoolVector2Array:
	return regular_cross_section(r, segments, 0.0, flip_ys)


static func square_cross_section(s: float, flip_ys = false) -> PoolVector2Array:
	return regular_cross_section(0.5 * s * sqrt(2), 4, 0.25 * PI, flip_ys)


# A cross section that is a regular polygon, e.g square
static func regular_cross_section(r: float, segments: int, rotation_offset := 0.0, flip_ys := false) -> PoolVector2Array:	
	var cross_section = PoolVector2Array()
	cross_section.resize(segments)
	
	var theta: float
	var angle_increment: float = 2 * PI / segments
	for i in range(segments):
		theta = angle_increment * i + rotation_offset
		cross_section[i] = Vector2(r*cos(theta), r*sin(theta))
	
	if (flip_ys):
		for i in range(segments):
			cross_section[i].y *= -1
	
	return cross_section
	
