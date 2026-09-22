#PlayerHud
extends CanvasLayer

@onready var mana_bar: TextureProgressBar = %ManaBar
@onready var mana: Control = $Mana
@onready var hp: Control = $HP
@onready var money: Control = $Money

@onready var boss_hp: Control = %BossHP
@onready var boss_hp_bar: ProgressBar = %BossHPBar
@onready var boss_hp_highlight: ProgressBar = %BossHPBar2
@onready var boss_name: Label = %BossName
@onready var boss_hp_animation_player: AnimationPlayer = $BossHP/BossHPAnimationPlayer

var lifegem : Array[ LifeGem ] = []
var boss_hp_tween : Tween

@export var boss_bar : bool = false

func _ready() -> void:
	for child in $HP/GemContainer.get_children():
		if child is LifeGem:
			lifegem.append( child )
			child.visible = false
	
	Messages.player_resource_changed.connect( update_resource_bar )
	Messages.player_hp_changed.connect( update_hp )
	Messages.boss_intro_started.connect( show_boss_hp )
	Messages.battle_ended.connect( hide_boss_hp )
	
	
	pass

func update_resource_bar( current : float, max : float, res_name : String ) -> void:
	var value : float = ( current / max ) * 100
	mana_bar.value = value
	# If you add a name label to the HUD later, set it here too, e.g.:
	# resource_label.text = res_name
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


func show_boss_hp() -> void:
	boss_hp_bar.visible =boss_bar
	boss_hp_highlight.visible = boss_bar
	boss_hp.visible = true
	boss_hp_bar.value = 1.0
	boss_hp_highlight.value = 1.0
	boss_hp_animation_player.play( "show" )
	boss_name.visible = true
	pass
	
func update_boss_hp( hp : float, max_hp : float ) -> void:
	var new_value : float = hp / max_hp
	boss_hp_bar.value = new_value
	tween_hp_highlight( new_value )
	pass

func tween_hp_highlight( target_value : float ) -> void:
	if boss_hp_tween:
		boss_hp_tween.kill()
	
	boss_hp_tween = create_tween()
	boss_hp_tween.set_ease( Tween.EASE_OUT )
	boss_hp_tween.set_trans( Tween.TRANS_EXPO )
	boss_hp_tween.tween_interval( 0.5 )
	boss_hp_tween.tween_property( boss_hp_highlight, "value", target_value, 0.5 )
	pass
	

func hide_boss_hp() -> void:
	boss_hp_animation_player.play( "hide" )
	await boss_hp_animation_player.animation_finished
	boss_hp.visible = false
	boss_name.visible = false
	pass


## Same end result as hide_boss_hp() but skips the "hide" animation/await
## entirely — for use right before a scene reload (see
## SaveManager.game_over()). SceneManager.transition_scene() pauses the
## tree almost immediately after it's called, which freezes
## boss_hp_animation_player mid-animation before "hide" can actually play
## out (PlayerHud is a persistent autoload, so by default it pauses along
## with everything else) — the bar was left looking fully visible for the
## whole reload instead of disappearing. A hard cut is fine here since the
## screen is already fading out for the death/respawn transition anyway.
func hide_boss_hp_immediate() -> void:
	if boss_hp_animation_player.is_playing():
		boss_hp_animation_player.stop()
	boss_hp.visible = false
	boss_name.visible = false
	pass
