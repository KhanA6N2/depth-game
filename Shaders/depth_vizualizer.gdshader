shader_type spatial;
render_mode unshaded, fog_disabled;

// Depth texture tutorial https://docs.godotengine.org/en/latest/tutorials/shaders/advanced_postprocessing.html
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// Updating head_position variable in World.gd https://www.youtube.com/watch?v=6-eIEFPcvrU
uniform vec3 head_position;
uniform float distance_cutoff = 20.;

// Function from https://www.reddit.com/r/godot/comments/1e2ijko/godot_spatial_shaders_are_not_linear/
vec3 srgb_to_linear(vec3 color){
	return mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)),color.rgb * (1.0 / 12.92),lessThan(color.rgb, vec3(0.04045)));}

vec3 among(float x){
    if (x < 0.05) {
            return vec3(0.19215686274509805, 0.5098039215686274, 0.7411764705882353);}
    if (x < 0.1) {
            return vec3(0.4196078431372549, 0.6823529411764706, 0.8392156862745098);}
    if (x < 0.15) {
            return vec3(0.6196078431372549, 0.792156862745098, 0.8823529411764706);}
    if (x < 0.2) {
            return vec3(0.7764705882352941, 0.8588235294117647, 0.9372549019607843);}
    if (x < 0.25) {
            return vec3(0.9019607843137255, 0.3333333333333333, 0.050980392156862744);}
    if (x < 0.3) {
            return vec3(0.9921568627450981, 0.5529411764705883, 0.23529411764705882);}
    if (x < 0.35) {
            return vec3(0.9921568627450981, 0.6823529411764706, 0.4196078431372549);}
    if (x < 0.4) {
            return vec3(0.9921568627450981, 0.8156862745098039, 0.6352941176470588);}
    if (x < 0.45) {
            return vec3(0.19215686274509805, 0.6392156862745098, 0.32941176470588235);}
    if (x < 0.5) {
            return vec3(0.4549019607843137, 0.7686274509803922, 0.4627450980392157);}
    if (x < 0.55) {
            return vec3(0.6313725490196078, 0.8509803921568627, 0.6078431372549019);}
    if (x < 0.6) {
            return vec3(0.7803921568627451, 0.9137254901960784, 0.7529411764705882);}
    if (x < 0.65) {
            return vec3(0.4588235294117647, 0.4196078431372549, 0.6941176470588235);}
    if (x < 0.7) {
            return vec3(0.6196078431372549, 0.6039215686274509, 0.7843137254901961);}
    if (x < 0.75) {
            return vec3(0.7372549019607844, 0.7411764705882353, 0.8627450980392157);}
    if (x < 0.8) {
            return vec3(0.8549019607843137, 0.8549019607843137, 0.9215686274509803);}
    if (x < 0.85) {
            return vec3(0.38823529411764707, 0.38823529411764707, 0.38823529411764707);}
    if (x < 0.9) {
            return vec3(0.5882352941176471, 0.5882352941176471, 0.5882352941176471);}
    if (x < 0.95) {
            return vec3(0.7411764705882353, 0.7411764705882353, 0.7411764705882353);}
    if (x < 1.0) {
            return vec3(0.8509803921568627, 0.8509803921568627, 0.8509803921568627);}
    return vec3(1.);}

vec3 depth_rgb(float depth_value){
	float X = abs(fract(depth_value * 6.0));
	if (depth_value < 1.0/6.0)
		return vec3(1.0, X, 0);
	else if (depth_value < 2.0/6.0)
		return vec3(1.0 - X, 1.0, 0);
	else if (depth_value < 3.0/6.0)
		return vec3(0, 1.0, X);
	else if (depth_value < 4.0/6.0)
		return vec3(0, 1.0 - X, 1.0);
	else
		return vec3(0, 0, 1.0);}

//vec3 depth_rgb(float depth_value) {
    //float X = abs(fract(depth_value * 6.0));
	//float division = 100.;
	//X  = float(int(division * X)) / division;
    //if (depth_value < 1.0 / 6.0)
        //return vec3 (1.0, X, 0.0);
    //else if (depth_value < 2.0 / 6.0)
        //return vec3 (1.0 - X, 1.0, 0.0);
    //else if (depth_value < 3.0 / 6.0)
        //return vec3 (0.0, 1.0, X);
    //else if (depth_value < 4.0 / 6.0)
        //return vec3 (0.0, 1.0 - X, 1.0);
    //else
        //return vec3 (0.0, 0.0, 1.0);
//}

void vertex()
{
	// Called for every vertex the material is visible on.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment()
{
	// Called for every pixel the material is visible on.
	// Get depth value
	float depth = texture(depth_texture, SCREEN_UV).x;
	// Normalized Device Coordinates, -1 to 1 in Godot
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	// Convert between NDC and view space to get distance to camera
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);

	// Partially depth texture tutorial, partially https://www.reddit.com/r/godot/comments/box2nq/help_with_difficult_shader/
	// World space position of fragment
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	float dist = distance(world_position, vec3(head_position[0],head_position[1],head_position[2]));

	// Get texture value
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;

	// Visualize distance
	if (c.rgb == vec3(0., 0., 0.))
		ALBEDO.rgb = vec3(0., 0., 0.);
	else if (c.rgb == vec3(1., 0., 0.))
		ALBEDO.rgb = vec3(0., 0., 0.);
	else if (c.rgb == vec3(0., 1., 0.))
		ALBEDO.rgb = vec3(1., 1., 1.);
	else if (c.rgb == vec3(0., 0., 1.))
		ALBEDO.rgb = vec3(0.5, 0.5, 0.5);
	else
		ALBEDO.rgb = srgb_to_linear(depth_rgb(dist/(distance_cutoff/(4./6.))));
		//ALBEDO.rgb = srgb_to_linear(among(dist/(distance_cutoff/(4./6.))));
}