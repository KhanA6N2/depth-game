// https://pastebin.com/716RmTtj
shader_type spatial;

render_mode blend_mix, unshaded, cull_front;

uniform vec3 color : source_color = vec3(1,0,0);
uniform float border_width : hint_range(0,1,0.001);

uniform bool pattern;
uniform float line_number : hint_range(0,100,1);

uniform bool pulse;
uniform float pulse_speed : hint_range(0,100,1);

uniform bool line_movement;
uniform float line_movement_speed : hint_range(-100,100,1);

uniform bool wave;

float squarify(float input) {
	if (input > 0.)
		return 1.;
	else
		return 0.;
}

void vertex() {
	VERTEX += VERTEX * border_width;
}

void fragment() {
	ALBEDO = color.xyz;
	if (pattern) 
	{
		vec2 uv = VERTEX.xy * line_number;
		ALBEDO = squarify(sin(uv.x + uv.y)) * color.xyz;
 
		if (pulse)
		{
			ALBEDO = squarify(sin(uv.x + uv.y)) * color.xyz * sin(TIME * pulse_speed);
		}
 
		if (line_movement)
		{
			ALBEDO = squarify(sin(uv.x + uv.y + TIME * line_movement_speed)) * color.xyz;
		}
 
		if (pulse && line_movement)
		{
			ALBEDO = squarify(sin(uv.x + uv.y + TIME * line_movement_speed)) * color.xyz * sin(TIME * pulse_speed);
		}
	}
 
	if (wave)
	{
		vec2 uv = VERTEX.xy * line_number;
		ALBEDO = sin(uv.xxx + TIME * line_movement_speed) * color.xyz;
	}
 
}

