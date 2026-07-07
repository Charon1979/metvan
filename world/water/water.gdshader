shader_type canvas_item;

// ---- Water body tint ----
uniform vec4 water_color : source_color = vec4(0.2, 0.6, 1.0, 0.55);

// ---- Surface wave silhouette (adapted from "2D water surface with wave and noise") ----
uniform float base_y = 0.5;                          // nominal surface position, UV fraction from top — set by WaterArea
uniform float wave_frequency : hint_range(1.0, 60.0) = 15.0;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.035;
uniform float wave_speed : hint_range(0.0, 10.0) = 3.0;

// ---- Surface shimmer noise (same source shader) ----
uniform sampler2D water_noise : hint_default_white;
uniform sampler2D water_distortion_noise : hint_default_white;
uniform float distortion_force : hint_range(0.0, 0.2) = 0.026;
uniform float shimmer_brightness : hint_range(0.0, 1.0) = 0.386;
uniform float shimmer_freq : hint_range(0.0, 1.0) = 0.39;
uniform float shimmer_size : hint_range(0.0, 4.0) = 2.0;
uniform float shimmer_speed : hint_range(0.0, 10.0) = 3.658;
uniform vec2 tiling = vec2(1.164, 1.0);
uniform vec2 offset_speed = vec2(0.035, 0.01);

// ---- Refraction of whatever's behind the water (adapted from "2D Water distortion effect") ----
uniform sampler2D refraction_map : hint_default_white;
uniform vec2 refraction_stretch = vec2(1.0, 1.0);
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.02;
uniform float refraction_speed : hint_range(0.0, 1.0) = 0.1;
uniform float refraction_world_scale = 512.0;         // matches the source shader's "/ 512.0" world tiling
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// ---- Flow direction — shared with WaterArea's conveyor-belt physics ----
uniform vec2 flow_direction = vec2(1.0, 0.0);          // Vector2.ZERO = current disabled

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 dir = flow_direction;
	if (length(dir) < 0.0001) {
		dir = vec2(1.0, 0.0);
	} else {
		dir = normalize(dir);
	}
	float dir_sign = sign(dir.x);
	if (dir_sign == 0.0) {
		dir_sign = 1.0;
	}

	vec2 uv = UV;

	// --- Surface wave silhouette + mask ---
	float wave1 = sin(uv.x * wave_frequency + TIME * wave_speed * dir_sign);
	float wave2 = sin(uv.x * wave_frequency * 0.5 + TIME * wave_speed * 0.8 * dir_sign);
	float combined_wave = (wave1 + wave2) * 0.5;
	float dynamic_water_level = base_y - (combined_wave * wave_amplitude);
	float water_mask = smoothstep(dynamic_water_level - 0.004, dynamic_water_level + 0.004, uv.y);

	if (water_mask <= 0.001) {
		// Above the surface — fully transparent, nothing behind is touched.
		COLOR = vec4(0.0);
	} else {
		// --- Surface shimmer ---
		vec2 noise_uv = uv * tiling + offset_speed * TIME * 0.5 * dir_sign;
		float noise_value = texture(water_distortion_noise, noise_uv).r;

		vec2 water_uv = uv * tiling;
		water_uv += offset_speed * TIME * dir_sign;
		water_uv += noise_value * distortion_force * shimmer_speed;
		vec4 noise_color = texture(water_noise, water_uv);
		float intensity = smoothstep(shimmer_freq, shimmer_size, noise_color.r);
		vec3 shimmer = intensity * vec3(shimmer_brightness);

		// --- Refraction of whatever's behind the water ---
		vec2 refraction_uv = vec2(
			mod(world_pos.x / refraction_world_scale * refraction_stretch.x + TIME * refraction_speed * dir_sign, 1.0),
			mod(world_pos.y / refraction_world_scale * refraction_stretch.y + TIME * refraction_speed, 1.0)
		);
		vec2 refraction_offset = vec2(
			texture(refraction_map, refraction_uv).r - 0.5,
			texture(refraction_map, refraction_uv + vec2(0.37, 0.61)).r - 0.5
		);
		vec4 refraction = texture(SCREEN_TEXTURE, SCREEN_UV - refraction_offset * refraction_strength);

		vec3 col = mix(refraction.rgb, water_color.rgb, water_color.a) + shimmer;

		COLOR = vec4(col, water_mask);
	}
}
