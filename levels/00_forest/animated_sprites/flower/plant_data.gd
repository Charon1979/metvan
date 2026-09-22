class_name PlantData
extends Resource

## Pool of possible "alive" appearances — one is picked at random when the
## plant spawns.
@export var flower_textures: Array[Texture2D] = []

## Shown once the plant takes damage and is destroyed.
@export var destroyed_texture: Texture2D
