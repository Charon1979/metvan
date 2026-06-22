class_name LootData
extends Resource

@export_file( "*.tscn" ) var item : String
@export  var minimum : int = 1
@export var maximum : int = 1
@export_range(0.01, 1.0, 0.01) var drop_chance : float = 1.0
