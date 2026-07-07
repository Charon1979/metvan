# VFXParticleConfig.gd
class_name VFXParticleConfig
extends Resource

# Core
@export var process_material: ParticleProcessMaterial = null
@export var amount: int = 32
@export var lifetime: float = 0.5
@export var one_shot: bool = false
@export var explosiveness: float = 0.0
@export var randomness: float = 0.0
@export var speed_scale: float = 1.0
@export var trail_enabled : bool = false

# Timing
@export var preprocess: float = 0.0

# Visibility
@export var visibility_aabb: Rect2 = Rect2(-100, -100, 200, 200)
@export var local_coords: bool = false

# Texture
@export var texture: Texture2D = null
