@icon( "uid://cjtwbmlrcd1mb" )

@tool

extends Control
class_name Trap

@onready var dmg_area: Area2D = $DmgArea
@onready var collision_shape_2d: CollisionShape2D = $DmgArea/CollisionShape2D

@export_range(32, 320, 32, "suffix:px") var width: int = 32:
	set = _on_width_changed




func _ready() -> void:
	
	
	if not Engine.is_editor_hint():
		_on_width_changed(width)



func _on_width_changed(new_width: int) -> void:

	var bigger: int = 0
	if new_width > width:
		bigger = 1
	elif new_width < width:
		bigger = -1
	else:
		bigger = 0
		
	width = new_width
	
	if not is_inside_tree():
		return
	if collision_shape_2d == null:
		return

	var rect := collision_shape_2d.shape as RectangleShape2D
	if rect == null:
		return

	rect.extents = Vector2(width / 2, 8)
	
	if bigger == -1:
		self.global_position.x = self.global_position.x - 16
	elif bigger == 1:
		self.global_position.x = self.global_position.x + 16

	queue_redraw()


func _on_dmg_area_body_entered( body: Node2D ) -> void:
	dmg_area.monitoring = false
	if body is PlayerGold:
		SaveManager.place_gold()
	SaveManager.restore_checkpoint()
	Messages.player_healed.emit(-1)
	
	pass 


func _on_dmg_area_body_exited( _body: Node2D ) -> void:
	dmg_area.monitoring = true
	pass 
