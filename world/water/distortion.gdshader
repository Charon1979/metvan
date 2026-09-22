shader_type canvas_item;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.015;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.2;
uniform float distortion_scale : hint_range(1.0, 60.0) = 18.0;
uniform float refraction_amount : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	// Explicitly combine texture + modulate ourselves. If the node has no
	// texture, TEXTURE samples as flat white so this is a no-op and behaves
	// exactly like before. If it DOES have a texture, this is the fix.
	vec4 surface = texture(TEXTURE, UV) * COLOR;

	float t = TIME * distortion_speed;
	vec2 offset = vec2(
		sin(SCREEN_UV.y * distortion_scale + t),
		cos(SCREEN_UV.x * distortion_scale + t * 0.8)
	) * distortion_strength;
	vec4 behind = texture(screen_texture, SCREEN_UV + offset);

	// Tint the refracted background by the surface color instead of
	// replacing it outright — this is what keeps your modulate visible
	// even at high refraction_amount (think colored glass, not a cutout).
	vec3 tinted_behind = behind.rgb * surface.rgb;

	COLOR.rgb = mix(surface.rgb, tinted_behind, refraction_amount);
	COLOR.a = surface.a;
}