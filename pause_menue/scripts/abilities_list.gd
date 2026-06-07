extends Node

@onready var ability_dash: Sprite2D = %AbilityDash
@onready var ability_double_jump: Sprite2D = %AbilityDoubleJump
@onready var ability_slam: Sprite2D = %AbilitySlam



func _ready() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	ability_dash.visible = player.dash
	ability_double_jump.visible = player.double_jump
	ability_slam.visible = player.ground_slam

	pass
