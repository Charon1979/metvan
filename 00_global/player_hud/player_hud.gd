#PlayerHud
extends CanvasLayer

@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana: Control = $Mana
@onready var hp: Control = $HP
@onready var money: Control = $Money


var lifegem : Array[ LifeGem ] = []

func _ready() -> void:
	for child in $HP/GemContainer.get_children():
		if child is LifeGem:
			lifegem.append( child )
			child.visible = false
	
	Messages.player_mana_changed.connect( update_mana_bar )
	Messages.player_hp_changed.connect( update_hp )
	
	
	pass

func update_mana_bar( mp : float, max_mp : float ) -> void:
	var value : float = ( mp / max_mp ) * 100
	mana_bar.value = value
	pass

func update_hp( _hp: int, _max_hp: int ) -> void:
	update_max_hp( _max_hp )
	for i in lifegem.size():
		update_health( i, _hp)
	pass

func update_health( _index : int, _hp : int ) -> void:
	var _value : int = clamp( _hp - _index * 2, 0, 2 )
	lifegem[ _index ].value = _value
	pass

func update_max_hp( _max_hp : int  ) -> void:
	var _lifegem_count : int = roundi( _max_hp * 0.5 )
	for i in lifegem.size():
		if i < _lifegem_count:
			lifegem[i].visible = true

		else:
			lifegem[i].visible = false
		
	pass
func hide_hud() -> void:
	mana.visible = false
	hp.visible = false
	money.visible = false
	pass

func show_hud() -> void:
	mana.visible = true
	hp.visible = true
	money.visible = true
	pass
