extends Node3D

@onready var shader : ShaderMaterial = $CharacterBody3D/Head/Camera3D/MeshInstance3D.get_surface_override_material(0)
@onready var character = $CharacterBody3D
@onready var head = $CharacterBody3D/Head
@onready var camera = $CharacterBody3D/Head/Camera3D
@onready var ray : CSGSphere3D = $Ray
@onready var extrusion_shadow = $Extrusion_Shadow
@onready var extrusion_distance_bar = $Control/ExtrusionDistanceBar
@onready var extrusion_distance_label = $Control/ExtrusionDistanceBar/Label
@onready var extrusion_distance_limit := $Control/ExtrusionDistanceBar/ColorRect
@onready var extrusion_angle_bar_neg = $Control/ExtrusionAngleBarNegative
@onready var extrusion_angle_bar_pos = $Control/ExtrusionAngleBarPositive
@onready var extrusion_angle_label = $Control/ExtrusionAngleBarNegative/Label
# Instantiate object https://www.reddit.com/r/godot/comments/fsz77h/how_do_you_instantiate_an_object/

var distance_cutoff
var ray_length
var extrusion_default = 1.
var extrusion_distance = extrusion_default
var extrusion_angle = 0
var building_on = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Setting shader parameter https://www.youtube.com/watch?v=6-eIEFPcvrU
	shader.set_shader_parameter("head_position",head.global_position)
	distance_cutoff = shader.get_shader_parameter("distance_cutoff")
	
	# Increase distance cutoff
	#if Input.is_action_just_released("scroll_up"):
		#shader.set_shader_parameter("distance_cutoff",distance_cutoff + 1)
	#if Input.is_action_pressed("sprint") and Input.is_action_just_released("scroll_up"):
		#shader.set_shader_parameter("distance_cutoff",distance_cutoff + 0.1)
	#if Input.is_action_pressed("up_arrow"):
		#shader.set_shader_parameter("distance_cutoff",distance_cutoff + 1)
	
	# Decrease distance cutoff
	#if Input.is_action_just_released("scroll_down"):
		#shader.set_shader_parameter("distance_cutoff",distance_cutoff - 1)
	#if Input.is_action_pressed("sprint") and Input.is_action_just_released("scroll_down"):
		#shader.set_shader_parameter("distance_cutoff",distance_cutoff - 0.1)
	#if Input.is_action_pressed("down_arrow"):
		#shader.set_shader_parameter("distance_cutoff",distance_cutoff - 1)
	
	# Ray-casting https://docs.godotengine.org/en/stable/classes/class_raycast3d.html#class-raycast3d
	var space_state = get_world_3d().direct_space_state
	var camera_position = camera.global_position
	var camera_basis = camera.global_basis
	var look_direction = -camera_basis.z
	var ray_origin = camera_position
	var ray_extrusion = ray_origin + look_direction * extrusion_distance + extrusion_angle/10. * camera_basis.y
	var ray_hit
	var ray_length = distance_cutoff
	var collided_object
	#var collided_object
	if ray_length:
		var ray_end = ray_origin + look_direction * ray_length
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = [character]
		var result = space_state.intersect_ray(query)
		if result:
			# Store collided object
			collided_object = result["collider"]
			ray_hit = result["position"]
	# Display ray hits
	if ray_hit and building_on:
		ray.visible = true
		ray.position = ray_hit
	else:
		ray.visible = false
	
	# Display extrusions
	if ray_hit and building_on:
		if ray_origin.distance_squared_to(ray_extrusion) < ray_origin.distance_squared_to(ray_hit) and collided_object.get_layer_mask_value(1):
			extrusion_shadow.visible = true
			extrusion_shadow.position = ray_extrusion
			extrusion_shadow.look_at_from_position(ray_extrusion, Vector3(ray_hit.x, ray_extrusion.y, ray_hit.z), Vector3(0, 1, 0))
		else:
			extrusion_shadow.visible = false
		# Prevent extrusion distance from being larger than ray cast
		#if collided_object.get_layer_mask_value(1) and extrusion_distance * extrusion_distance > ray_origin.distance_squared_to(ray_hit):
			#extrusion_distance = floor(ray_origin.distance_to(ray_hit) * 4. + 1.) / 4.
		if not collided_object.get_layer_mask_value(1):
			ray.material.albedo_color = Color(0., 1., 0., 1.)
			extrusion_distance_label.text = "Incompatible surface"
		elif extrusion_distance * extrusion_distance > ray_origin.distance_squared_to(ray_hit):
			ray.material.albedo_color = Color(0., 0., 1., 1.)
			extrusion_distance_label.text = "Too far"
		else:
			ray.material.albedo_color = Color(0., 0., 0., 1.)
	else:
		extrusion_shadow.visible = false
	
	# Extrusion distance
	if Input.is_action_pressed("ctrl") and Input.is_action_just_released("scroll_up"):
		var new_extrusion_angle = extrusion_angle + 1
		if new_extrusion_angle <= 10:
			extrusion_angle = new_extrusion_angle
	elif Input.is_action_pressed("shift") and Input.is_action_just_released("scroll_up"):
		var new_extrusion_distance = extrusion_distance + 1.
		if new_extrusion_distance <= ray_length:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = ray_length
	elif Input.is_action_just_released("scroll_up"):
		var new_extrusion_distance = extrusion_distance + 0.25
		if new_extrusion_distance <= ray_length:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = ray_length
	if Input.is_action_pressed("ctrl") and Input.is_action_just_released("scroll_down"):
		var new_extrusion_angle = extrusion_angle - 1
		if new_extrusion_angle >= -10:
			extrusion_angle = new_extrusion_angle
	elif Input.is_action_pressed("shift") and Input.is_action_just_released("scroll_down"):
		var new_extrusion_distance = extrusion_distance - 1.
		if new_extrusion_distance >= 1.0:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = 1.0
	elif Input.is_action_just_released("scroll_down"):
		var new_extrusion_distance = extrusion_distance - 0.25
		if new_extrusion_distance >= 1.0:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = 1.0
	
	# Place extrusion
	if extrusion_shadow.visible:
		if Input.is_action_just_pressed("left_click"):
			_place_extrusion(ray_origin, ray_hit, ray_extrusion)
	
	if Input.is_action_just_pressed("right_click"):
		if collided_object:
			if collided_object.get_layer_mask_value(3):
				collided_object.queue_free()
	
	if Input.is_action_just_pressed("e"):
		if building_on:
			building_on = false
		else:
			building_on = true
	
	extrusion_distance_bar.value = extrusion_distance
	
	if ray_hit and building_on:
		if not collided_object.get_layer_mask_value(1):
			extrusion_distance_label.text = "Can't place here"
		elif extrusion_distance * extrusion_distance > ray_origin.distance_squared_to(ray_hit):
			extrusion_distance_label.text = "Too far"
		else:
			extrusion_distance_label.text = str(extrusion_distance)
		extrusion_distance_limit.position.x = 640 * ray_origin.distance_to(ray_hit) / 20
	if extrusion_angle <= 0:
		extrusion_angle_bar_neg.value = -(extrusion_angle + 10)
		extrusion_angle_bar_pos.value = 0
	else:
		extrusion_angle_bar_pos.value = extrusion_angle
		extrusion_angle_bar_neg.value = -10
	extrusion_angle_label.text = str(extrusion_angle)
	if not building_on:
		extrusion_distance_label.text = ""
		extrusion_angle_label.text = ""

func _place_extrusion(ray_origin : Vector3, ray_hit : Vector3, ray_extrusion : Vector3) -> void:
	var extrusion : CSGBox3D = CSGBox3D.new()
	var camera_position = camera.global_position
	var camera_basis = camera.global_basis
	extrusion.look_at_from_position(ray_extrusion, Vector3(ray_hit.x, ray_extrusion.y, ray_hit.z), Vector3(0, 1, 0))
	extrusion.size = Vector3(1., 0.1, 1.)
	extrusion.use_collision = true
	extrusion.set_layer_mask_value(3,true)
	extrusion.set_layer_mask_value(1,false)	
	add_child(extrusion)
