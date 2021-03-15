extends Spatial

export (Resource) var shape = shape as ShapeOutlineResource

onready var _camera_container := get_node("CameraContainer") as Spatial
onready var _model := get_node("Model") as VisibilityNotifier

const FeaFrameScene = preload("res://assets/scenes/fea/FeaFrame.tscn")
const FeaNodeScene = preload("res://assets/scenes/fea/FeaNode.tscn")
const TriangleMeshScene = preload("res://assets/scenes/mesh/TriangulatedMesh3D.tscn")
const GRID_SPACING := 3.0
const ROTATION_SPEED := 0.25
var count := 0

var _centerline_mode = true
var _camera_movement_enabled := true

func _ready():
	var _success = ViewEvents.connect("enable_camera_movement", self, "_on_camera_movement_enabled")
	_success = ViewEvents.connect("disable_camera_movement", self, "_on_camera_movement_disabled")
	
	var bounding_box = AABB(_camera_container.translation, Vector3(0.1, 0.1, 0.1))
	
	var meshSceneInstance := TriangleMeshScene.instance()
	
	for i in range(5):
		var meshScene := meshSceneInstance.duplicate()
		meshScene.set("translation", Vector3(i * GRID_SPACING, 0, 0))
		meshScene.set("rotation_degrees", Vector3(0, 90, 0))
		_model.add_child(meshScene, true)
		
		for j in range(5):
			if i == 0:
				meshScene = meshSceneInstance.duplicate()
				meshScene.set("translation", Vector3(0, 0, -j * GRID_SPACING))
				_model.add_child(meshScene, true)
		
			for k in range(5):
				var frameScene := FeaFrameScene.instance()
				frameScene.set("end_i", Vector3(i*GRID_SPACING, k*GRID_SPACING, -j*GRID_SPACING))
				frameScene.set("end_j", Vector3(i*GRID_SPACING, (k+1)*GRID_SPACING, -j*GRID_SPACING))
				frameScene.set("shape", shape)
				_model.add_child(frameScene, true)
				
				var frame := frameScene.get_node(".") as FeaFrame
				bounding_box = bounding_box.expand(frame.end_i)
				bounding_box = bounding_box.expand(frame.end_j)
				
				var nodeScene := FeaNodeScene.instance()				
				nodeScene.set("translation", Vector3(i*GRID_SPACING, (k+1)*GRID_SPACING, -j*GRID_SPACING))
				_model.add_child(nodeScene, true)
	

	_model.set_aabb(bounding_box)
	ViewEvents.emit_signal("model_extents_changed")
				
	$Timer.start()


func _process(_delta):
	if _camera_movement_enabled:
		_camera_container.rotate_y(_delta * ROTATION_SPEED)
		


func _on_Timer_timeout():
	ViewEvents.emit_signal("toggle_centerline_mode", _centerline_mode)
	_centerline_mode = not _centerline_mode
	

func _on_camera_movement_enabled():
	print("tried to enable camera movement")
	_camera_movement_enabled = true


func _on_camera_movement_disabled():
	print("tried to disable camera movement")
	_camera_movement_enabled = false
