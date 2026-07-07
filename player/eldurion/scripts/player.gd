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







#endregion

#region /// export variables
@export var move_speed : float = 150
@export var max_fall_velocity : float = 600.0
#endregion


#region /// State Machine Variables
var states : Array[ PlayerState ]
var current_state : PlayerState :
	get : return states.front()
var previous_state : PlayerState :
	get : return states[ 1 ]
#endregion

#region /// player stats
var hp : int = 6 :
	set( value ):
		hp = clampi( value, 0, max_hp )
		Messages.player_hp_changed.emit( hp, max_hp )
var max_hp : int = 6 :
	set( value ):
		max_hp = value
		Messages.player_hp_changed.emit( hp, max_hp )
var mp : float = 50 :
	set( value ):
		mp = clampf( value, 0, max_mp )
		Messages.player_mana_changed.emit( mp, max_mp )
var max_mp : float = 100 :
	set( value ):
		max_mp = value
		Messages.player_mana_changed.emit( mp, max_mp )
var gold : int = 0:
	set(value):
		gold = value
		Messages.player_gold_changed.emit(value)

var dash : bool = false
var dash_count : int = 0
var double_jump : bool = false
var jump_count : int = 0
var ground_slam : bool = false
var morph_roll : bool = false
#endregion

#region /// standard variables
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980
var gravity_mulitplier : float = 1.0
var attack_held := false
var direction_locked : bool = false
#endregion

#region /// water
var water_current : Vector2 = Vector2.ZERO   # set by WaterArea while overlapping; Vector2.ZERO otherwise
var water_max_speed : float = -1.0           # -1 = no clamp; set by WaterArea alongside water_current
#endregion



func _ready() -> void:
	if get_tree().get_first_node_in_group("Player") != self:
		self.queue_free()
	initialize_states()
	self.call_deferred( "reparent", get_tree().root )
	Messages.player_healed.connect( _on_player_healed )
	Messages.player_casting.connect( _on_player_casted )
	Messages.back_to_title_screen.connect ( queue_free )
	damage_area.damage_taken.connect( _on_damage_taken )
	
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
	change_state( current_state.process( _delta ) )
	pass



func _physics_process( _delta: float ) -> void:
	velocity.y += gravity * _delta * gravity_mulitplier
	velocity.y = clampf( velocity.y, -1000.0, max_fall_velocity )
	move_and_slide()
	change_state( current_state.physics_process( _delta ) )

	# Applied after state logic has set this frame's base velocity, so it
	# layers on top of movement/state changes instead of racing them.
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
	$Label.text = current_state.name
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
	$Label.text = current_state.name
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
		if direction.x < 0:
			sprite_2d.flip_h = true
			
			
		elif direction.x > 0:
			sprite_2d.flip_h = false
			
	pass
	
func _on_player_healed( amount : int ) -> void:
	hp += amount

func _on_player_casted( amount : int ) -> void:
	mp += amount


func _on_damage_taken( a : AttackArea ) -> void:
	if current_state is PlayerStateDeath:
		return
		
	hp -= a.damage
	damage_taken.emit()
	pass

func can_dash() -> bool:
	if dash == false or dash_count or mp < 15:
		return false
	return true
