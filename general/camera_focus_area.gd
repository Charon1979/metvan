class_name CameraFocusArea
extends Area2D

## Drop this Area2D (with its own CollisionShape2D child) around whatever
## you want the camera to highlight while the player is inside it — a boss
## arena entrance, a vista, a lever that opens a door somewhere else on
## screen. While the player overlaps this area, their camera eases off them
## and centers on `focus_point` instead; leaving the area eases it back onto
## the player.
##
## Reaches the player's camera via $"Camera2D" on the Player node itself —
## same node name every PlayerState script already uses (see jump.gd,
## fall.gd, idle.gd: $"../../Camera2D"). See player_camera.gd's
## focus_on() / return_to_player() for the actual easing.

@export var focus_point : Node2D  ## Leave empty to focus on this Area2D's own position instead.


func _ready() -> void:
	body_entered.connect( _on_body_entered )
	body_exited.connect( _on_body_exited )


func _on_body_entered( body : Node2D ) -> void:
	if body is Player:
		var camera : PlayerCamera = body.get_node_or_null( "Camera2D" )
		if camera:
			camera.focus_on( focus_point if focus_point else self )


func _on_body_exited( body : Node2D ) -> void:
	if body is Player:
		var camera : PlayerCamera = body.get_node_or_null( "Camera2D" )
		if camera:
			camera.return_to_player()
