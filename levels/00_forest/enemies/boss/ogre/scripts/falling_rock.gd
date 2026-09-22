extends CharacterBody2D

@onready var entrance_player: AnimationPlayer = $".."
@onready var damage_area: DamageArea = $DamageArea
@onready var rock_damage: GPUParticles2D = $"../Rock_damage"
@onready var sprite: Sprite2D = $Sprite2D
@export var particle_scene : PackedScene
@export var boss_orchestrator : BossBattleOrchestrator
## Leave empty to auto-derive one from this node's path (fine as long as you
## don't reparent/rename this rock); set it explicitly for a stable id
## regardless of scene position. See RegionInfo.persistent_key()'s doc
## comment for why this replaced the old unique_name() (removed below).
@export var persistent_id : String = ""
var health : int = 3

## Persisted via SaveManager.persistent_data[ _key() ] — same pattern
## as Switch/SavePoint/BossBattleOrchestrator. Absent/"" = not spawned yet
## (battle hasn't ended). STATE_ACTIVE = spawned, still destructible.
## STATE_DESTROYED = already broken; stays broken across reloads.
const STATE_ACTIVE : String = "active"
const STATE_DESTROYED : String = "destroyed"

const AUDIO_OGRE_ROCK_PUNCH = preload("uid://b5pnuls7t3eu")
const AUDIO_OGRE_HIT_ROCK = preload("uid://tbq6wwlime6y")
const AUDIO_HARD_HIT = preload("uid://d1j1jjuxdh65")

func _ready() -> void:
	
	Messages.boss_intro_started.connect( _on_intro_started )
	damage_area.damage_taken.connect( on_damage_taken )
	Messages.battle_ended.connect( _on_battle_ended )
	damage_area.monitoring = false
	damage_area.monitorable = false
	set_collision_layer_value( 1, false )
	var state : String = SaveManager.persistent_data.get( _key(), "" )
	if state == STATE_DESTROYED:
		# Snap straight to the destroyed look — no animation, no damage_area,
		# nothing left to hit. Stays this way permanently.
		sprite.frame = 19
		damage_area.queue_free()
		
	elif state == STATE_ACTIVE:
		# Battle already ended in a previous session and this rock was never
		# destroyed — restore it to the same destructible state
		# _on_battle_ended() below puts it in, since that signal only fires
		# once and won't fire again just because the scene reloaded.
		entrance_player.play( "rock_down" )
		damage_area.monitoring = true
		damage_area.monitorable = true
		sprite.frame = 15
		set_collision_layer_value( 1, true )
	pass


func _on_battle_ended() -> void:
	# Messages.battle_ended fires for EVERY enemy's death, not just the boss
	# (see the identical guard/comment in boss_battle_orchestrator.gd's own
	# end_boss_battle()). Without this, any regular enemy dying anywhere in
	# the loaded scene would wrongly spawn/reset this rock even while the
	# real boss is still alive. Point boss_orchestrator at this room's
	# BossBattleOrchestrator in the Inspector for this to take effect.
	if not boss_orchestrator or not is_instance_valid( boss_orchestrator.boss ) or not ( boss_orchestrator.boss is Enemy ) or not ( boss_orchestrator.boss.state_machine.current_state is ESDeath ):
		return
	entrance_player.play("rock_down")
	damage_area.monitoring = true
	damage_area.monitorable = true
	sprite.frame = 15
	set_collision_layer_value( 1, true )
	SaveManager.persistent_data[ _key() ] = STATE_ACTIVE
	pass


func on_damage_taken( _a: AttackArea ) -> void:
	health -= 1
	sprite.frame += 1
	if health <= 0 or sprite.frame == 19:
		# Collision clears IMMEDIATELY, before the destroy animation plays —
		# not after awaiting entrance_player.animation_finished like before.
		# This rock sits on the same layer (1) a ranged spell's HazardArea
		# treats as solid terrain, so waiting for the animation to finish
		# left it still blocking (and stopping) spells/movement for the
		# whole "rock_destroyed" animation — and permanently, if that
		# animation was ever missing/misnamed on a given rock instance,
		# since animation_finished would then just never fire at all.
		set_collision_layer_value( 1, false )
		damage_area.queue_free()
		SaveManager.persistent_data[ _key() ] = STATE_DESTROYED
		entrance_player.play("rock_destroyed")
		Audio.play_spatial_sound( AUDIO_OGRE_ROCK_PUNCH, global_position)
		await entrance_player.animation_finished
		sprite.frame = 19
	else:
		entrance_player.play("rock_damage")
		Audio.play_spatial_sound( AUDIO_OGRE_HIT_ROCK, global_position)
	pass


func _key() -> String:
	if persistent_id.is_empty():
		persistent_id = str( get_path() )
	return SaveManager.persistent_key( self, persistent_id )


func spawn_particles() -> void:
	var p = particle_scene.instantiate()
	add_child(p)
	p.position = rock_damage.position
	p.amount = 18
	p.lifetime = 4
	p.speed_scale = 1.5
	p.restart()
	await p.finished
	p.queue_free()

func play_audio() -> void:
	Audio.play_spatial_sound( AUDIO_HARD_HIT, global_position)
	pass

func _on_intro_started() -> void:
	set_collision_layer_value( 1, true )
	pass
