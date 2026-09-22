shader_type canvas_item;

uniform float sway_strength : hint_range(0.0, 30.0) = 8.0;
uniform float sway_speed : hint_range(0.5, 10.0) = 4.0;
uniform float trigger_x = 0.0;
uniform float trigger_y = 0.0;
uniform float trigger_range : hint_range(8.0, 256.0) = 64.0;
uniform float plant_x = 0.0;
uniform float plant_y = 0.0;

void vertex() {
	float sway_falloff = 1.0 - UV.y;

	vec2 delta = vec2(trigger_x - plant_x, trigger_y - plant_y);
	float distance_to_trigger = length(delta);
	float proximity = clamp(1.0 - (distance_to_trigger / trigger_range), 0.0, 1.0);

	float push_direction = -sign(delta.x);

	float phase = proximity * sway_speed * 3.14159;
	float oscillation = sin(phase);

	float sway = oscillation * sway_strength * sway_falloff * proximity * push_direction;

	VERTEX.x += sway;
}