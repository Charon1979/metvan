extends Node

@warning_ignore( "unused_signal")
signal player_interacted( player : Player )

@warning_ignore( "unused_signal")
signal player_healed( amount : int )

@warning_ignore( "unused_signal")
signal player_hp_changed( hp : int, max_hp : int )

@warning_ignore( "unused_signal")
signal input_hint_changed( hint : String )

@warning_ignore( "unused_signal")
signal player_casting( mp : int)

@warning_ignore( "unused_signal")
signal player_mana_changed( mp : int, max_mp : int )

@warning_ignore( "unused_signal")
signal player_gold_changed( amount : int )


@warning_ignore( "unused_signal")
signal back_to_title_screen ( )

@warning_ignore( "unused_signal")
signal game_paused ( )

@warning_ignore( "unused_signal")
signal game_unpaused ( )
