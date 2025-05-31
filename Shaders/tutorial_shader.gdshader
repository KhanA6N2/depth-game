shader_type spatial;
render_mode unshaded,blend_mul;

uniform float wave_height = 0.2;
uniform sampler2D example_texture : source_color;
uniform vec3 head_color = vec3(1.0, 0.5, 0.0);
uniform vec3 face_color = vec3(0.0, 1.0, 1.0);

void vertex() {
	//VERTEX.y += sin(TIME * 5.0 + VERTEX.x * 10.0) * wave_height;
}

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * 50.0 + TIME * 5.0) * 0.01;
	vec3 wave_color;
	wave_color.r = (sin(TIME * 6.0 + VERTEX.x * 10.0) + 1.0) * 0.5;
	wave_color.g = (sin(TIME * 7.0 + VERTEX.x * 10.0) + 1.0) * 0.5;
	wave_color.b = (sin(TIME * 8.0 + VERTEX.x * 10.0) + 1.0) * 0.5;
	vec3 texture_color = texture(example_texture, uv).rgb;
	vec3 out_color = texture_color.r * head_color + texture_color.g * wave_color;
	ALBEDO = out_color;
}