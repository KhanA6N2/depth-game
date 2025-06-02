extends Node3D

@onready var shader : ShaderMaterial = $CharacterBody3D/Head/Camera3D/MeshInstance3D.get_surface_override_material(0)
@onready var character = $CharacterBody3D
@onready var head = $CharacterBody3D/Head
@onready var camera = $CharacterBody3D/Head/Camera3D
# Ray-casting
@onready var ray_cast = $Ray
@onready var top_left_ray = $Top_Left_Ray
@onready var bottom_left_ray = $Bottom_Left_Ray
@onready var top_right_ray = $Top_Right_Ray
@onready var bottom_right_ray = $Bottom_Right_Ray
@onready var extrusion_killer_ray = $Extrusion_Killer_Ray
@onready var extrusion_shadow = $TrueExtrusionShadow
@onready var invalid_extrusion_shadow = $InvalidExtrusionShadow
# Extrusion UI
@onready var extrusion_distance_bar = $Control/ExtrusionDistanceBar
@onready var extrusion_distance_label = $Control/ExtrusionDistanceBar/Label
@onready var extrusion_distance_limit := $Control/ExtrusionDistanceBar/ColorRect
@onready var extrusion_angle_bar_neg = $Control/ExtrusionAngleBarNegative
@onready var extrusion_angle_bar_pos = $Control/ExtrusionAngleBarPositive
@onready var extrusion_angle_label = $Control/ExtrusionAngleBarNegative/Label

# Instantiate scene tutorial https://www.youtube.com/watch?v=ZwXPV5v9NaU
@export var extrusion_scene : PackedScene

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
	
	# Ray-casting https://docs.godotengine.org/en/stable/classes/class_raycast3d.html#class-raycast3d
	var space_state = get_world_3d().direct_space_state
	var camera_position = camera.global_position
	var camera_basis = camera.global_basis
	var look_direction = -camera_basis.z
	var top_left_corner = camera_position + 0.5 * camera_basis.x + (0.5 + extrusion_angle/10.) * camera_basis.y
	var bottom_left_corner = camera_position + 0.5 * camera_basis.x - (0.5 - extrusion_angle/10.) * camera_basis.y
	var top_right_corner = camera_position - 0.5 * camera_basis.x + (0.5 + extrusion_angle/10.) * camera_basis.y
	var bottom_right_corner = camera_position - 0.5 * camera_basis.x - (0.5 - extrusion_angle/10.) * camera_basis.y
	var ray_origins = [top_left_corner,bottom_left_corner,top_right_corner,bottom_right_corner]
	var ray_extrusion = camera_position + look_direction * extrusion_distance + extrusion_angle/10. * camera.global_basis.y
	var extrusion_killer_hit
	var ray_hits = PackedVector3Array()
	ray_length = shader.get_shader_parameter("distance_cutoff")
	var valid_collision = true
	var within_ray_length = true
	var collided_extrusion
	var distances : Array
	var max_distance
	
	if ray_length and building_on:
		# Ray-cast to building surface
		for i in 4:
			var query = PhysicsRayQueryParameters3D.create(ray_origins[i], ray_origins[i] + look_direction * ray_length)
			query.exclude = [character]
			var result = space_state.intersect_ray(query)
			if result: # change to result.size() > 0 if this doesn't work
				# Prevent rays on forbidden objects
				if not result["collider"].get_layer_mask_value(1):
					valid_collision = false
				ray_hits.append(result["position"])
			else:
				within_ray_length = false
		
		# Ray-cast to extrusion
		var query = PhysicsRayQueryParameters3D.create(camera_position, camera_position + look_direction * ray_length)
		query.exclude = [character]
		var result = space_state.intersect_ray(query)		
		if result:
			# Store collided extrusion
			if result["collider"].get_layer_mask_value(3):
				collided_extrusion = result["collider"]
				extrusion_killer_hit = result["position"]
	
	# Display extrusions
	extrusion_distance_bar.value = extrusion_distance
	if building_on:
		extrusion_distance_label.text = str(extrusion_distance)
		if within_ray_length:
			for i in 4:
				distances.append(ray_origins[i].distance_squared_to(ray_hits[i]))
			max_distance = distances.max()
			if valid_collision:
				if camera_position.distance_squared_to(ray_extrusion) < max_distance:
					extrusion_shadow.visible = true
					invalid_extrusion_shadow.visible = false
					extrusion_shadow.position = ray_extrusion
					extrusion_shadow.depth = sqrt(max_distance) - extrusion_distance
					extrusion_shadow.look_at_from_position(ray_extrusion, camera_position - max_distance * camera_basis.z, camera_basis.y)
				else:
					extrusion_shadow.visible = false
					invalid_extrusion_shadow.visible = false
					extrusion_distance_label.text += " (Building too far in)"
				extrusion_distance_limit.position.x = 640 * sqrt(max_distance) / 20
			else:
				extrusion_shadow.visible = false
				invalid_extrusion_shadow.visible = true
				invalid_extrusion_shadow.position = ray_extrusion
				invalid_extrusion_shadow.look_at_from_position(ray_extrusion, camera_position - max_distance * camera_basis.z, camera_basis.y)
				extrusion_distance_label.text += " (Can't build here)"
		else:
			extrusion_shadow.visible = false
			invalid_extrusion_shadow.visible = true
			invalid_extrusion_shadow.position = ray_extrusion
			invalid_extrusion_shadow.look_at_from_position(ray_extrusion, camera_position - ray_length * 1.1 * camera_basis.z, camera_basis.y)
			extrusion_distance_label.text += " (Too far to build from)"
		# Extrusion killer
		if collided_extrusion:
			extrusion_killer_ray.visible = true
			extrusion_killer_ray.material.albedo_color = Color(0., 1., 0., 1.)
			extrusion_killer_ray.position = extrusion_killer_hit
			extrusion_distance_label.text += " (Delete extrusion?)"
		else:
			extrusion_killer_ray.visible = false
	else:
		extrusion_distance_label.text = ""
		extrusion_angle_label.text = ""
		extrusion_killer_ray.visible = false
		extrusion_shadow.visible = false
		invalid_extrusion_shadow.visible = false
	
	if extrusion_angle <= 0:
		extrusion_angle_bar_neg.value = -(extrusion_angle + 10)
		extrusion_angle_bar_pos.value = 0
	else:
		extrusion_angle_bar_pos.value = extrusion_angle
		extrusion_angle_bar_neg.value = -10
	extrusion_angle_label.text = str(extrusion_angle)
	
	# Extrusion distance adjustment
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
	if valid_collision:
		if Input.is_action_just_pressed("left_click"):
			_place_extrusion(max_distance, camera_position, camera_basis, ray_extrusion)
	
	if Input.is_action_just_pressed("right_click"):
		if collided_extrusion:
			collided_extrusion.queue_free()
	
	# Toggle building
	if Input.is_action_just_pressed("e"):
		if building_on:
			building_on = false
		else:
			building_on = true

func _place_extrusion(max_distance : float, camera_position : Vector3, camera_basis : Basis, ray_extrusion : Vector3) -> void:
	var extrusion = extrusion_scene.instantiate()
	extrusion.depth = sqrt(max_distance) - extrusion_distance
	extrusion.look_at_from_position(ray_extrusion, camera_position - max_distance * camera_basis.z, camera_basis.y)
	add_child(extrusion)
