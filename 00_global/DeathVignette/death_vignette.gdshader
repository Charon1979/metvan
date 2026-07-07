shader_type canvas_item;

uniform vec2 spotlight_screen_pos = vec2(0.5, 0.5); // normalized 0-1 viewport position
uniform float spotlight_radius : hint_range(0.0, 1.0) = 0.12;
uniform float spotlight_softness : hint_range(0.0, 1.0) = 0.08;
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = 1.0 / SCREEN_PIXEL_SIZE.x * SCREEN_PIXEL_SIZE.y;
	vec2 diff = uv - spotlight_screen_pos;
	diff.x *= aspect;
	float dist = length(diff);
	float alpha = smoothstep(spotlight_radius, spotlight_radius + spotlight_softness, dist);
	COLOR = vec4(dark_color.rgb, alpha);
}