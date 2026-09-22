extends Node
@warning_ignore( "unused_signal")
signal player_interacted( player : Player )
@warning_ignore( "unused_signal")
signal player_healed( amount : int )
@warning_ignore( "unused_signal")
signal player_hp_changed( hp : int, max_hp : int )
@warning_ignore( "unused_signal")
signal input_hint_changed( hint : String, instant : bool )
@warning_ignore( "unused_signal")
signal player_casting( mp : int)
@warning_ignore( "unused_signal")
signal player_resource_changed( current : float, max : float, resource_name : String )
@warning_ignore( "unused_signal")
signal player_gold_changed( amount : int )
@warning_ignore( "unused_signal")
signal back_to_title_screen ( )
@warning_ignore( "unused_signal")
signal game_paused ( )
@warning_ignore( "unused_signal")
signal game_unpaused ( )
@warning_ignore( "unused_signal")
signal display_text( text : String, instant : bool )
@warning_ignore( "unused_signal")
signal battle_started
@warning_ignore( "unused_signal")
signal battle_ended
@warning_ignore( "unused_signal")
signal boss_reward_collected
@warning_ignore( "unused_signal")
signal boss_intro_started
@warning_ignore( "unused_signal")
signal boss_intro_ended
@warning_ignore( "unused_signal")
signal lair_action_1
@warning_ignore( "unused_signal")
signal lair_action_2
@warning_ignore( "unused_signal")
signal lair_action_3
