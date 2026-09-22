shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;

const int SAMPLES = 4;

void fragment() {
	vec4 modulate = COLOR; // grab self_modulate/modulate before we overwrite COLOR
	vec4 tex_color;

	if (blur_amount > 0.0) {
		tex_color = vec4(0.0);
		vec2 texel_size = TEXTURE_PIXEL_SIZE * blur_amount;
		float total_weight = 0.0;

		for (int x = -SAMPLES; x <= SAMPLES; x++) {
			for (int y = -SAMPLES; y <= SAMPLES; y++) {
				vec2 offset = vec2(float(x), float(y)) * texel_size;
				float weight = 1.0 - (length(vec2(float(x), float(y))) / float(SAMPLES + 1));
				weight = max(weight, 0.0);
				tex_color += texture(TEXTURE, UV + offset) * weight;
				total_weight += weight;
			}
		}
		tex_color /= total_weight;
	} else {
		tex_color = texture(TEXTURE, UV);
	}

	COLOR = tex_color * modulate; // reapply self_modulate/modulate manually
}