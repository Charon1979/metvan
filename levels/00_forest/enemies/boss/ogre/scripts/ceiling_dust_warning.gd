class_name CeilingDustWarning
extends GPUParticles2D

## One-shot "danger, something's about to fall here" telegraph. Matches
## HitParticles' pattern: instantiated by VisualEffects, runs for the
## given duration, frees itself. Design the actual particle material to
## taste (a narrow falling-dust column reads well) — this script only
## owns the lifetime.

func start( duration : float ) -> void:
	emitting = true
	await get_tree().create_timer( duration ).timeout
	queue_free()
