shader_type canvas_item;

uniform float speed = 0.2;

uniform float bottom_fade    : hint_range(0.0, 2.0) = 0.1;
uniform float top_fade : hint_range(0.0, 2.0) = 0.1;
uniform float left_fade   : hint_range(0.0, 2.0) = 0.1;

void fragment() {
	// Scroll RIGHT -> LEFT
	vec2 uv = UV;
	uv.x += TIME * speed;

	vec4 tex = texture(TEXTURE, uv);

	// --- Correct soft-edge masks ---
	float bottom_mask = smoothstep(0.0, top_fade, UV.y);
	float top_mask    = smoothstep(0.0, bottom_fade, 1.0 - UV.y);
	float left_mask   = smoothstep(0.0, left_fade, UV.x);

	float mask = bottom_mask * top_mask * left_mask;

	tex.a *= mask;

	COLOR = tex;
}

