extends Line2D


func _on_SectionDrawing_resized_drawing(drawing_rect: Vector2):
	# keep centered in drawing
	position = 0.5 * drawing_rect
