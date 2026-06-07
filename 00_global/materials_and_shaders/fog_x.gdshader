shader_type canvas_item;

uniform float speed = 0.2;

uniform float bottom_fade : hint_range(0.0, 2.0) = 0.1;
uniform float top_fade : hint_range(0.0, 2.0) = 0.1;
uniform float left_fade : hint_range(0.0, 2.0) = 0.1;
uniform float right_fade : hint_range(0.0, 2.0) = 0.1;
uniform float dir : hint_range(-1, +1) = 2;

void fragment() {
	// Scroll RIGHT -> LEFT
	float direction = TIME * dir;
	vec2 uv = UV;
	uv.x -= direction * speed;


	vec4 tex = texture(TEXTURE, uv);

	// --- Correct soft-edge masks ---
	float bottom_mask = smoothstep(0.0, top_fade, UV.y);
	float top_mask    = smoothstep(0.0, bottom_fade, 1.0 - UV.y);
	float left_mask   = smoothstep(0.0, left_fade, UV.x);
	float right_mask  = smoothstep(0.0, right_fade,1.0 - UV.x);

	float mask = bottom_mask * top_mask * left_mask * right_mask;

	tex.a *= mask;

	COLOR = tex;

	}