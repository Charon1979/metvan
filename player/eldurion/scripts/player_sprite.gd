class_name PlayerSprite extends Sprite2D

var tween : Tween
var flash_material : ShaderMaterial

func _ready() -> void:
	flash_material = ShaderMaterial.new()
	flash_material.shader = preload("uid://b2pyyq8v3flw0") # adjust path
	material = flash_material
	pass

func tween_color( duration : float = 0.5,  color : Color = Color( 0.14, 0.62, 0.87, 0.75 )) -> void:
	if tween:
		tween.kill()
	modulate = color
	tween = create_tween()
	tween.tween_property( self, "modulate", Color.WHITE, duration )
	pass

# Flashes pure white repeatedly until the given DamageArea's invulnerability ends
func flash_until( damage_area : DamageArea, flash_speed : float = 0.08 ) -> void:
	if tween:
		tween.kill()

	flash_material.set_shader_parameter( "flash_color", Color.WHITE )

	tween = create_tween()
	tween.set_loops()
	tween.tween_method( _set_flash_amount, 0.0, 1.0, flash_speed )
	tween.tween_method( _set_flash_amount, 1.0, 0.0, flash_speed )

	if not damage_area.invulnerability_ended.is_connected( stop_flash ):
		damage_area.invulnerability_ended.connect( stop_flash, CONNECT_ONE_SHOT )
	pass

func _set_flash_amount( value : float ) -> void:
	flash_material.set_shader_parameter( "flash_amount", value )

func stop_flash() -> void:
	if tween:
		tween.kill()
	_set_flash_amount( 0.0 )
	pass

func ghost() -> void:
	var effect : Node2D = Node2D.new()
	var p : Node2D = get_parent()
	p.add_sibling( effect )
	effect.get_parent().move_child( effect, 0 )
	effect.z_index = 1
	effect.global_position = p.global_position
	effect.modulate = Color( 0.14, 0.62, 0.87, 0.5 )
	
	var sprite_copy : Sprite2D = duplicate()
	effect.add_child( sprite_copy )
	
	var t : Tween = create_tween()
	t.set_ease( Tween.EASE_OUT )
	t.tween_property( effect, "modulate", Color( 1, 1, 1, 0 ), 0.2 )
	t.chain().tween_callback( effect.queue_free )
	pass
