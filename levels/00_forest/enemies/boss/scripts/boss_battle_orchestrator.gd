@icon( "uid://cb3yj45ujgdft" )
class_name BossBattleOrchestrator
extends Node


@export var boss_name : String = "Boss Name"
@export var boss : Node
@export var trigger_area : Area2D
@export var reward : Node2D


@export_category( "Boss Music" )
@export var boss_track : AudioStream
@export var post_boss_track : AudioStream

@export_category( "Camera Bounds" )
@export var boss_level_bounds : LevelBounds
@export var original_level_bounds : LevelBounds

@onready var entrance_player: AnimationPlayer = $EntrancePlayer
@onready var dust_ground: CeilingDustWarning = $Dust_Ground

## Persisted via SaveManager.persistent_key( self, persistent_id ) — see
## RegionInfo.persistent_key()'s doc comment for why this replaced the old
## unique_name() (removed below). Leave empty to auto-derive one from this
## node's path (fine as long as you don't reparent/rename this node); set it
## explicitly for a stable id regardless of scene position.
@export var persistent_id : String = ""

## False while the player was already standing inside trigger_area the
## instant monitoring turned on (see _enable_trigger_area() below) — set
## true again only once that player has genuinely left and comes back.
var _trigger_armed : bool = true


func _ready() -> void:
	Messages.battle_ended.connect( end_boss_battle )
	if boss:
		boss.process_mode = Node.PROCESS_MODE_DISABLED

	if trigger_area:
		trigger_area.set_collision_mask_value( 5, true )
		# Don't start monitoring immediately. On a scene reload (e.g. after
		# the boss kills the player and the level reloads back into this
		# room), the fresh Player node exists here at whatever position it's
		# authored at in this room's scene file for several frames BEFORE
		# SaveManager.setup_player() teleports it to the actual saved
		# checkpoint. If that authored position happens to overlap this
		# trigger's shape, body_entered fired during that transient window
		# and started the fight using a position the player was about to be
		# moved away from — so the fight visibly started while the player
		# was actually still standing somewhere else entirely (e.g. still
		# outside the room) once the teleport caught up. Waiting for
		# load_scene_finished — the same signal level_transistion.gd already
		# waits on before re-arming its own trigger — means the scene's
		# fade/load sequence has run its course and the player has long
		# since been moved to their real position before this trigger can
		# fire at all.
		trigger_area.monitoring = false
		SceneManager.load_scene_finished.connect( _enable_trigger_area, CONNECT_ONE_SHOT )
		trigger_area.body_entered.connect( _on_body_entered )
		trigger_area.body_exited.connect( _on_body_exited )

	if reward:
		reward.process_mode = Node.PROCESS_MODE_DISABLED
		reward.visible = false

	# NEW — a scripted intro (ESOgreIntro, or any boss that emits this)
	# reports back here when its cinematic is done, so the fight itself
	# doesn't start until that's finished.
	Messages.boss_intro_ended.connect( _on_boss_intro_ended )

	if SaveManager.persistent_data.get_or_add( persistent_key(), "" ) == "defeated":
		queue_free()
	pass


func _enable_trigger_area() -> void:
	if not trigger_area:
		return
	trigger_area.monitoring = true
	# Guard against a false start: if the player is ALREADY standing inside
	# this area the instant monitoring turns on — e.g. they respawned right
	# on/near it, or SaveManager.setup_player()'s teleport (which runs in
	# its own, unsynced coroutine chain — see the big comment above) simply
	# hasn't landed yet — Godot's Area2D treats that pre-existing overlap as
	# a brand new one and fires body_entered on the very next physics step,
	# indistinguishable from the player actually walking in. That's the
	# "the fight started and claimed the camera without me triggering it"
	# bug. Wait one physics step for the overlap list to settle, and if
	# anyone's already inside, disarm triggering until they genuinely leave
	# and come back — see _on_body_entered/_on_body_exited below.
	await get_tree().physics_frame
	for body in trigger_area.get_overlapping_bodies():
		if body is Player and body.is_active_player_candidate:
			_trigger_armed = false
			return


func _on_body_entered( body : Node2D ) -> void:
	if not _trigger_armed:
		return
	# `body is Player` alone isn't enough — Eldurion (or any other
	# Player-typed node sitting in the level for character-select) also
	# passes that check. If a body like that overlaps this trigger before
	# the real controlled character does, begin_intro() gets called with
	# the wrong body and the boss locks onto it for the whole fight.
	# is_active_player_candidate (added on Player) is true only for the
	# character actually being controlled, so gate on that too — set
	# is_active_player_candidate = false on Eldurion's instance in the
	# Inspector for this to take effect.
	if body is Player and body.is_active_player_candidate:
		activate_boss_arena( body )
		trigger_area.body_entered.disconnect( _on_body_entered )
		pass
	pass


func _on_body_exited( body : Node2D ) -> void:
	if not _trigger_armed and body is Player and body.is_active_player_candidate:
		_trigger_armed = true

func activate_boss_arena( player : Player ) -> void:
	
	Audio.play_music(null)
	PlayerHud.boss_name.text = boss_name
	dust_ground.emitting = true

	if boss:
		boss.process_mode = Node.PROCESS_MODE_INHERIT
		# NOTE: do NOT hook end_boss_battle() off boss.tree_exiting. tree_exiting
		# fires on ANY removal from the tree — including the whole scene being
		# torn down by SceneManager.transition_scene() (e.g. SaveManager.game_over()
		# reloading the level after the BOSS kills the player mid-fight, with the
		# boss still alive). That falsely marked the fight "defeated" in
		# persistent_data, which then made the next BossBattleOrchestrator._ready()
		# queue_free() itself (so the fight could never be retriggered), made
		# BossLadder.is_boss_dead() show the post-boss ladder state, and even
		# resolved deliver_reward()'s `await reward.tree_exiting` early (the
		# reward node was also being torn down, not actually collected). The
		# only legitimate "boss died" signal is Messages.battle_ended, emitted
		# once by ESDeath.enter() after the death animation finishes — that's
		# already connected in _ready() above, and is sufficient on its own.

	if boss is Enemy:
		boss.was_hit.connect( _on_boss_enemy_hit )

	# NEW — scripted intro cinematics (fall / land / roar / etc) live on
	# the boss itself. begin_intro() is the explicit hand-off into that
	# sequence; it ends by emitting Messages.boss_intro_ended, which
	# _on_boss_intro_ended below picks up to actually start the fight.
	# Bosses that don't define begin_intro() just skip straight past this
	# (nothing calls it), so this is safe to leave in for every boss.
	# Passes the exact player that triggered the fight — see the comment
	# on OgreBoss.begin_intro() for why that beats a group lookup.
	if boss and boss.has_method( "begin_intro" ):
		boss.begin_intro( player )
	entrance_player.play("rocks_fall")
	pass

func end_boss_intro() -> void:
	
	pass

func start_boss_battle() -> void:
	Messages.battle_started.emit()
	dust_ground.emitting = false
	if boss_level_bounds:
		boss_level_bounds.set_camera_bounds( true )  # true = ease into the new bounds instead of snapping

	Audio.play_music( boss_track )

	pass

func end_boss_battle() -> void:
	# Messages.battle_ended is a single global signal emitted by EVERY enemy's
	# ESDeath state (see es_death.gd), not just this orchestrator's own boss —
	# and every BossBattleOrchestrator currently in the tree is connected to
	# it. Without this guard, any regular enemy dying anywhere in the loaded
	# scene (or another boss dying, if two orchestrators are ever loaded at
	# once) would wrongly run this orchestrator's own end-of-fight cleanup:
	# marking THIS fight "defeated" in persistent_data, handing out its
	# reward, switching to post_boss_track, etc. Only continue if this
	# orchestrator's own `boss` is the enemy that actually just finished
	# dying — i.e. it's an Enemy and its own state machine is currently
	# sitting in ESDeath (where it stays once battle_ended fires; nothing
	# transitions an enemy out of ESDeath afterward).
	if not is_instance_valid( boss ) or not ( boss is Enemy ) or not ( boss.state_machine.current_state is ESDeath ):
		return

	SaveManager.persistent_data[ persistent_key() ] = "defeated"

	await deliver_reward()

	if boss_level_bounds:
		original_level_bounds.set_camera_bounds( true )  # true = ease back to the normal bounds instead of snapping
	Audio.play_music( post_boss_track )

	pass

func deliver_reward() -> bool:

	if not reward:
		return false

	if reward:
		reward.process_mode = Node.PROCESS_MODE_INHERIT
		reward.visible = true

	await reward.tree_exiting

	Messages.boss_reward_collected.emit()

	return true

## Public — ladder.gd's is_boss_dead() needs the exact same key to check
## whether THIS boss is defeated.
func persistent_key() -> String:
	if persistent_id.is_empty():
		persistent_id = str( get_path() )
	return SaveManager.persistent_key( self, persistent_id )

func _on_boss_enemy_hit( _a : AttackArea ) -> void:
	if boss is Enemy:
		PlayerHud.update_boss_hp( boss.blackboard.health, boss.health )
	pass


## NEW
func _on_boss_intro_ended() -> void:
	end_boss_intro()
	start_boss_battle()
