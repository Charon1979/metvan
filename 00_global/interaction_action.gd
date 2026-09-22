@icon( "uid://dvc1rhwgsy4mo" )
class_name InteractionAction
extends Resource

## Base class for one step of an InteractionTrigger's action list. Add a
## subclass per action type (dialogue, scene transition, animation, save,
## ...) — InteractionTrigger runs every action in its `actions` array, in
## order, on interact, so combining several is just adding more entries.

## Override in each subclass. Called once per interaction, in array order.
## trigger is the InteractionTrigger this action belongs to — since this is
## a Resource, it can't @export a direct Node reference (see
## InteractionActionAnimation for why that matters); trigger is how a
## subclass reaches into the scene tree when it needs to.
func execute( _player : Player, _trigger : InteractionTrigger ) -> void:
	pass
