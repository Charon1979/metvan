class_name InteractionActionAnimation
extends InteractionAction

## Plays an animation on interact — e.g. a chest opening, a lever pulling.
##
## This is a Resource (see InteractionAction), so it can't @export a direct
## AnimationPlayer reference — a Resource can be saved/shared independent of
## any scene, so it has no way to hold a live pointer to one specific node.
## animation_player_path is resolved against the InteractionTrigger this
## action belongs to instead, at the moment it actually runs. In the
## Inspector, set it relative to that InteractionTrigger node — e.g.
## "../AnimationPlayer" for a sibling, or "AnimationPlayer" for a child.

@export var animation_player_path : NodePath
@export var animation_name : String = ""


func execute( _player : Player, trigger : InteractionTrigger ) -> void:
	if animation_player_path.is_empty():
		push_warning( "InteractionActionAnimation has no animation_player_path assigned!" )
		return
	var animation_player : AnimationPlayer = trigger.get_node_or_null( animation_player_path )
	if not animation_player:
		push_warning( "InteractionActionAnimation: no AnimationPlayer found at '%s' relative to %s" % [ animation_player_path, trigger.name ] )
		return
	animation_player.play( animation_name )
