extends CharacterBody2D
class_name Player

#region // signals

signal damage_taken
signal dead

#endregion


#region /// on ready variables

@onready var sprite_2d: PlayerSprite = $Sprite2D
@onready var collision_stand: CollisionShape2D = $CollisionStand
@onready var one_way_platform_shape_cast: ShapeCast2D = $OneWayPlatformShapeCast
@onready var attack_area: AttackArea = %AttackArea
@onready var damage_area: DamageArea = %DamageArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Container for the power-charge weapon vfx (VFXSprite2 + VFXPArt as its
## children) — flipped as a whole in update_direction() below instead of
## mirroring each child's scale/position individually.
## get_node_or_null() rather than the plain $Path shorthand — $Path calls
## get_node() under the hood, which logs a hard "Node not found" error the
## instant this scene is loaded if a given Player subclass doesn't have
## these nodes. Not every character has the power-charge weapon vfx set up
## (Eldurion doesn't) — resolving to null and skipping it (see the null
## checks in power_charge.gd/power_attack.gd/update_direction() below)
## instead of hard-erroring lets those characters just not have this
## feature rather than crashing on spawn.
@onready var vfx: Node2D = $VFX

@onready var vfx_sprite_2: Sprite2D = %VFXSprite2
@onready var vfx_player: AnimationPlayer = %VFXPlayer
@onready var vfxp_art: GPUParticles2D = %VFXPArt
@onready var vfx_sprite_1: Sprite2D = %VFXSprite1

#endregion

#region /// programmatically-created nodes
## Dedicated looping player for water_wade_sfx/water_swim_sfx — built here
## rather than added in the editor, same as Audio.gd builds its own pooled
## AudioStreamPlayer2D instances in _ready(), so this works with no scene
## changes required. A child of Player (added before the reparent-to-root
## call below carries it along), so its position tracks the player for free
## every frame without anything here having to update it manually — unlike
## Audio.play_spatial_sound()'s one-shot players, which are freestanding and
## only ever positioned once at creation, fine for an instant sound but
## wrong for one that's expected to keep playing while the player moves.
var water_movement_audio : AudioStreamPlayer2D
#endregion

#region /// export variables
@export var move_speed : float = 150
@export var max_fall_velocity : float = 600.0
#endregion

#region /// active-player dedup
## Godot group used ONLY for the "one active player at a time" check below
## — deliberately separate from the "Player" group (which just means
## "this node is a Player-typed character" and can legitimately have many
## members at once: other characters on a select screen, a boss that
## reuses the Player moveset like Eldurion, etc).
const ACTIVE_PLAYER_GROUP := "ActivePlayerCandidate"

## Leave true for the character actually being controlled right now.
## Set to false on any Player-derived instance that coexists with the real
## active player without being controlled itself — e.g. Eldurion sitting
## in a boss arena, or other characters idling on a character-select
## screen. Those instances skip the dedup check entirely instead of
## competing for (and potentially winning, at the real player's expense)
## the one "active" slot.
@export var is_active_player_candidate : bool = true
#endregion


#region /// State Machine Variables
var states : Array[ PlayerState ]
var current_state : PlayerState :
	get : return states.front()
var previous_state : PlayerState :
	get : return states[ 1 ]
#endregion

#region /// character identity — overridden by each character subclass
## Display name shown on the character-select screen and anywhere else it's needed.
var character_id : String = "default"       # stable id, used as a save-data key — never shown to the player, never renamed once used in a save
var character_name : String = "Hero"  # display name

## The single named secondary resource (mana, stamina, whatever). Every
## character has exactly one of these; only the name/max/regen differ.
var resource_name : String = "Mana"
var resource_current : float = 50 :
	set( value ):
		resource_current = clampf( value, 0, resource_max )
		Messages.player_resource_changed.emit( resource_current, resource_max, resource_name )
var resource_max : float = 100 :
	set( value ):
		resource_max = value
		Messages.player_resource_changed.emit( resource_current, resource_max, resource_name )
#endregion

#region /// player stats — universal, identical for every character
var hp : int = 6 :
	set( value ):
		hp = clampi( value, 0, max_hp )
		Messages.player_hp_changed.emit( hp, max_hp )
var max_hp : int = 6 :
	set( value ):
		max_hp = value
		Messages.player_hp_changed.emit( hp, max_hp )
var gold : int = 0:
	set(value):
		gold = value
		Messages.player_gold_changed.emit(value)
#endregion

#region /// shared movement kit — same bools as before, unlocked by AbilityPickup
var dash : bool = false
var dash_count : int = 0
var double_jump : bool = false
var jump_count : int = 0
var ground_slam : bool = false
var morph_roll : bool = false
var pogo_count : int = 0
#endregion

#region /// character-unique abilities — generic bag for anything a subclass adds
## Not used by the shared movement kit above (that stays as explicit bools
## for minimal diff). Use this for anything character-specific: a spell,
## a summon, a stance — whatever a given character's kit adds.
var unique_abilities : Dictionary = {}

func has_unique_ability( id : String ) -> bool:
	return unique_abilities.get( id, false )

func unlock_unique_ability( id : String ) -> void:
	unique_abilities[ id ] = true
#endregion

#region /// standard variables
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980
var gravity_mulitplier : float = 1.0
var attack_held := false
var direction_locked : bool = false
#endregion


#region /// attack cooldown
## Set whenever the combo attack ends without chaining into another hit
## (grace window expired) or gets cut short (e.g. the player is hurt).
## While > 0, idle/run refuse to re-enter the attack state.
var attack_cooldown_timer : float = 0.0

func can_attack() -> bool:
	return attack_cooldown_timer <= 0.0

func start_attack_cooldown( duration : float ) -> void:
	attack_cooldown_timer = duration
#endregion


#region /// pogo cooldown
## Set whenever a pogo attack ends (bounced off a target or just landed).
## While > 0, jump/fall refuse to let the player pogo again even if
## pogo_count has already been reset by a fresh jump.
var pogo_cooldown_timer : float = 0.0

func can_pogo() -> bool:
	return pogo_count == 0 and pogo_cooldown_timer <= 0.0

func start_pogo_cooldown( duration : float ) -> void:
	pogo_cooldown_timer = duration
#endregion


#region /// spell cooldown
## Independent of attack_cooldown_timer on purpose — being on spell
## cooldown doesn't block melee, and vice versa.
var spell_cooldown_timer : float = 0.0

func can_cast() -> bool:
	return spell_cooldown_timer <= 0.0

func start_spell_cooldown( duration : float ) -> void:
	spell_cooldown_timer = duration
#endregion


#region /// equipped spell
## The spell scene currently equipped — set via equip_spell() (or directly
## in the Inspector for testing). Assigning this instantiates a fresh
## SpellCast into equipped_spell below; that instance is deliberately never
## added to the scene tree, so its @onready child refs (and anything that
## activates on _ready(), like HazardArea forcing monitoring = true) never
## run. Its plain @export fields (cast_animation, resource_cost,
## fail_animation, etc.) are still immediately readable regardless, since
## those don't need tree membership — this is what makes it a cheap
## "equip slot" idle/run/spell can peek at without instantiate-to-peek every
## time a cast is attempted.
@export var equipped_spell_scene : PackedScene :
	set( value ):
		equipped_spell_scene = value
		equipped_spell = value.instantiate() if value else null

## The live "equip slot" instance described above — never added to the
## tree on its own. To actually cast, duplicate() it into a fresh instance
## and add THAT to the tree (see PlayerStateSpell._on_animation_finished),
## leaving this one untouched and reusable for the next cast.
var equipped_spell : SpellCast = null

## Convenience wrapper for callers that don't want to reach into the
## exported property directly (e.g. a future inventory/equip system).
func equip_spell( scene : PackedScene ) -> void:
	equipped_spell_scene = scene
#endregion


#region /// water
var water_current : Vector2 = Vector2.ZERO
var water_max_speed : float = -1.0
var swim_enabled : bool = false   # set by DynamicWater2D's WaterArea while overlapping
## Whether the player is currently overlapping ANY water area at all —
## distinct from swim_enabled (only true for water that specifically grants
## swimming) and from water_current != Vector2.ZERO (a still pool with
## CurrentDirection.NONE never sets a current, so that alone can't tell "in
## water" from "on dry land" either). Set by DynamicWater2D's WaterArea the
## same duck-typed way as the other three fields above — see its
## _on_body_entered()/_on_body_exited().
var in_water : bool = false

@export_category( "Water Audio" )
## Played once (fire-and-forget, via Audio.play_spatial_sound — same as any
## other one-shot in this project) on crossing the water's surface in
## EITHER direction: jumping in, or jumping/climbing back out. One sound
## covers both; it's the audio side of the same moment DynamicWater2D's own
## splash particles fire on (see its _spawn_splash()).
@export var water_splash_sfx : AudioStream
## Long/looping clip played on water_movement_audio (see the programmatically-
## created nodes region above) while actively moving through water that
## ISN'T swimmable here — in_water true, swim_enabled false: wading through
## a shallow pool, or a current too weak/disabled to actually swim in.
## Needs "Loop" enabled in the file's own import settings — this script
## only starts/stops it, it doesn't make a non-looping clip loop.
@export var water_wade_sfx : AudioStream
## Same, but for water that IS swimmable here (in_water AND swim_enabled
## both true) — an actual swim-stroke loop instead of a wade/splash one.
@export var water_swim_sfx : AudioStream
## Deadzone on `direction` (the same input axis idle.gd/run.gd already key
## off to tell moving from standing still) below which the player counts as
## "not moving" for water_wade_sfx/water_swim_sfx. Checked against input
## rather than actual velocity — velocity alone isn't reliable here since
## there's no dedicated swim state yet to cancel gravity while in_water, so
## a player just standing still and sinking still accumulates downward
## velocity from plain gravity, which read as "moving" and never let the
## wade sound stop. Direction-based means a current sweeping the player
## along with no key held won't trigger it on its own — add
## `or water_current != Vector2.ZERO` to the check below if you want that
## to count as movement too.
@export var water_movement_speed_threshold : float = 0.1

var _was_in_water : bool = false
#endregion




func _ready() -> void:
	if is_active_player_candidate:
		add_to_group( ACTIVE_PLAYER_GROUP )
		if get_tree().get_first_node_in_group( ACTIVE_PLAYER_GROUP ) != self:
			self.queue_free()
	# Hook for subclasses to set character_id / character_name / resource_name /
	# resource_max / unique starting state before states initialize. Runs before
	# initialize_states() so a subclass can rely on it being set by the time
	# any state's enter() fires.
	_init_character()
	initialize_states()
	self.call_deferred( "reparent", get_tree().root )

	Messages.player_healed.connect( _on_player_healed )
	Messages.player_casting.connect( _on_player_casted )
	Messages.back_to_title_screen.connect ( queue_free )
	damage_area.damage_taken.connect( _on_damage_taken )

	water_movement_audio = AudioStreamPlayer2D.new()
	water_movement_audio.bus = "SFX"
	add_child( water_movement_audio )

	pass

## Override in each character subclass to set character_id, character_name,
## resource_name, resource_max, and any starting unique_abilities. Do NOT
## call state-machine code here — states aren't initialized yet.
func _init_character() -> void:
	pass


func _input(event):

	if event.is_action_pressed("attack"):
		attack_held = true

	if event.is_action_released("attack"):
		attack_held = false

func _unhandled_input( event: InputEvent ) -> void:
	if event.is_action_released( "jump" ):
		velocity.y *= 0.5
	if event.is_action_pressed( "up" ):
		Messages.player_interacted.emit( self )
	elif event.is_action_pressed( "pause" ):
		get_tree().paused = true
		var pause_menu : PauseMenu = load( "uid://orcv8nfhnb66" ).instantiate()
		add_child( pause_menu )
		return
	change_state( current_state.handle_input( event ) )

	pass



func _process( _delta: float ) -> void:
	update_direction()
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= _delta
	if pogo_cooldown_timer > 0.0:
		pogo_cooldown_timer -= _delta
	if spell_cooldown_timer > 0.0:
		spell_cooldown_timer -= _delta
	_update_water_audio( _delta )
	change_state( current_state.process( _delta ) )
	pass



func _physics_process( _delta: float ) -> void:
	velocity.y += gravity * _delta * gravity_mulitplier
	velocity.y = clampf( velocity.y, -1000.0, max_fall_velocity )
	move_and_slide()

	change_state( current_state.physics_process( _delta ) )

	if water_current != Vector2.ZERO:
		velocity += water_current * _delta
		if water_max_speed >= 0.0:
			velocity.x = clampf( velocity.x, -water_max_speed, water_max_speed )

	pass



func initialize_states() -> void:
	states = []

	for c in $States.get_children():
		if c is PlayerState:
			states.append( c )
			c.player = self
		pass

	if states.size() == 0:
		return

	for state in states:
		state.init()

	change_state( current_state )
	current_state.enter()

	pass



func change_state( new_state : PlayerState ) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return

	if current_state:
		current_state.exit()

	states.push_front( new_state )
	current_state.enter()
	states.resize( 3 )

	pass



func update_direction() -> void:

	if direction_locked:
		return

	var prev_direction : Vector2 = direction

	var x_axis = Input.get_axis("left", "right")
	var y_axis = Input.get_axis("up", "down")
	direction = Vector2(x_axis, y_axis)

	if prev_direction.x != direction.x:
		attack_area.flip( direction.x )
		# VFXSprite2/VFXPArt (the power-charge weapon glow/particles) live
		# under the VFX container, not under sprite_2d — so flipping
		# sprite_2d.flip_h alone doesn't move them to the other side on a
		# turnaround. Flipping the container's scale.x mirrors both of its
		# children (and their local positions) in one go.
		if direction.x < 0:
			sprite_2d.flip_h = true
			if vfx:
				vfx.scale.x = -1

		elif direction.x > 0:
			sprite_2d.flip_h = false
			if vfx:
				vfx.scale.x = 1

	pass

func _on_player_healed( amount : int ) -> void:
	hp += amount

func _on_player_casted( amount : int ) -> void:
	resource_current += amount


func _on_damage_taken( a : AttackArea ) -> void:
	if current_state is PlayerStateDeath:
		return

	hp -= a.damage
	damage_taken.emit()
	pass

func can_dash() -> bool:
	if dash == false or dash_count or resource_current < 15:
		return false
	return true


## Drives the three water sounds off in_water/swim_enabled/direction —
## all set on this node by DynamicWater2D's WaterArea while overlapping
## (see its _on_body_entered()/_on_body_exited()). Nothing here reaches
## into DynamicWater2D directly; it only reacts to state already poked
## onto Player, same as water_current is already consumed in
## _physics_process() above.
##
## water_splash_sfx is a short one-shot, fired fire-and-forget through
## Audio.play_spatial_sound() same as everywhere else in this file.
## water_wade_sfx/water_swim_sfx are long looping clips instead, so they
## can't be fired-and-forgotten the same way — nothing would ever stop
## them. Those two are played/stopped explicitly on water_movement_audio
## (see the programmatically-created nodes region above), started only
## when the desired clip actually changes (freshly moving, or switching
## between wade and swim) and stopped as soon as the player either stops
## moving or leaves the water.
func _update_water_audio( _delta : float ) -> void:
	if in_water != _was_in_water:
		if water_splash_sfx:
			Audio.play_spatial_sound( water_splash_sfx, global_position, false, true, 0.6 )
		_was_in_water = in_water

	var moving : bool = in_water and direction.length() >= water_movement_speed_threshold
	var desired_sfx : AudioStream = ( water_swim_sfx if swim_enabled else water_wade_sfx ) if moving else null

	if desired_sfx:
		# Only (re)start when the loop isn't already playing the right clip —
		# restarting every frame would keep yanking it back to the start.
		if water_movement_audio.stream != desired_sfx or not water_movement_audio.playing:
			water_movement_audio.stream = desired_sfx
			water_movement_audio.play()
	elif water_movement_audio.playing:
		water_movement_audio.stop()
