extends Node

#warning-ignore-all:unused_signal

signal hovered_over(element)		# Expects an FeaBase
signal hovered_from(element)		# Expects an FeaBase

signal select_many(mode, elements)	# Expects a selection mode and an array of FeaBase
signal select_dynamic_window(rect)	# Expects a screen-space Rect2
signal select_within(mode, rect)	# Expects a selection mode and a screen-space Rect2

signal toggle_centerline_mode(to)   # Expects a boolean for the target centerline mode display state

signal disable_camera_movement()
signal enable_camera_movement()

signal model_extents_changed()
