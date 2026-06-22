@tool
@icon( "uid://dy178uirc4rfd" )
class_name Enemy
extends CharacterBody2D

signal direction_changed( new_dir)
signal was_hit( a: AttackArea )
signal was_killed()


@export var health : float = 1
@export var affected_by_gravity : bool = true
@export var face_left_on_start : bool = false :
	set( value ):
		face_left_on_start = value
		_update_face_left()

@export_category( "Audio" )
@export var death_sound : AudioStream

@onready var sprite: Node2D = get_node_or_null("Sprite")


var animation : AnimationPlayer
var damage_area : DamageArea
var hazard_area : HazardArea


var state_machine : EnemyStateMachine
var decision_engine : DecisionEngine
var blackboard : Blackboard


func _ready() -> void:
	
	if Engine.is_editor_hint():
		set_physics_process( false )
		return
	setup()
	
	pass


func setup() -> void:
	blackboard = Blackboard.new()
	blackboard.health = health
	
	for c in get_children():
		if c is AnimationPlayer and not animation:
			animation = c
		elif c is Node2D and not sprite:
			sprite = c
		elif c is DamageArea and not damage_area:
			damage_area = c
			c.damage_taken.connect( on_damage_taken )
		elif c is HazardArea and not hazard_area:
			hazard_area = c
		elif c is EnemyStateMachine and not state_machine:
			state_machine = c
		elif c is DecisionEngine and not decision_engine:
			decision_engine = c
	
	if state_machine and decision_engine:
		state_machine.setup( self, blackboard )
		decision_engine.enemy = self
		decision_engine.blackboard = blackboard
	else:
		set_physics_process( false )
	pass




func _physics_process( delta: float ) -> void:
	blackboard.update_distance_to_target( global_position )
	if blackboard.can_decide:
		state_machine.change_state(decision_engine.decide())

	if affected_by_gravity:
		velocity += get_gravity() * delta

	state_machine.physics_update(delta)
	move_and_slide()
	pass


func change_dir( new_dir : float ) -> void:
	blackboard.dir = new_dir
	direction_changed.emit( new_dir )
	if sprite:
		if new_dir < 0:
			sprite.scale.x = -1
		elif new_dir > 0:
			sprite.scale.x = 1
	
	pass

func _update_face_left() -> void:
	if not Engine.is_editor_hint():
		return
	for c in get_children():
		if c is Node2D:
			if face_left_on_start == true:
				c.scale.x = -1
			else:
				c.scale.x = 1
	pass

func play_animation( anim_name : String ) -> void:
	if animation.has_animation( anim_name ):
		animation.play( anim_name )
	else:
		printerr("Animation missing: ", anim_name)
	pass

func on_damage_taken( a : AttackArea ) -> void:
	
	blackboard.damage_source = a
	blackboard.force = a.force
	blackboard.damage_element = a.dmg_element
	blackboard.health -= a.damage
	if blackboard.health <= 0:
		damage_area.queue_free()
		hazard_area.queue_free()
		was_killed.emit()
	was_hit.emit( a )

	pass

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not find_children( "*", "AnimationPlayer", true ):
		warnings.append( "Requires an AnimationPlayer!" )
	if not find_children( "*", "Sprite2D", true ):
		warnings.append( "Needs Node2D as parent of Sprite2D to flip" )
	if not find_children( "*", "DamageArea", true ):
		warnings.append( "Requires a DamageArea!" )
	if not find_children( "*", "HazardArea", true ):
		warnings.append( "Requires a HazardArea!" )
	if not find_children( "*", "EnemyStateMachine", true ):
		warnings.append( "Requires an EnemyStateMachine!" )
	if not find_children( "*", "DecisionEngine", true ):
		warnings.append( "Requires a DecisionEngine!" )
	
	return warnings
