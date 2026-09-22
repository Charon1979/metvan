class_name InteractionActionSave
extends InteractionAction

## Saves the game — same call save_point.gd already made directly.

func execute( _player : Player, _trigger : InteractionTrigger ) -> void:
	SaveManager.save_game()
