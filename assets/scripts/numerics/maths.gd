extends Reference

class_name Maths

const IMPERIAL_TO_METRIC := 0.0254

static func itm(inches: float):
	return inches * IMPERIAL_TO_METRIC

static func mti(meters: float):
	return meters / IMPERIAL_TO_METRIC
