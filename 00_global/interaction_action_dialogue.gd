class_name InteractionActionDialogue
extends InteractionAction

## Shows a line of text via Messages.display_text — same signal the old
## hardcoded InteractionTrigger.text field used to drive directly.
## Covers ANSEHEN / LESEN / UNTERHALTEN-style interactions.

@export_multiline var text : String = ""


func execute( _player : Player, _trigger : InteractionTrigger ) -> void:
	if text.is_empty():
		push_warning( "InteractionActionDialogue has no text set!" )
	Messages.display_text.emit( text, false )
