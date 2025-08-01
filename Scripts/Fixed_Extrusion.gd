extends Node3D

@onready var shader : ShaderMaterial = $CharacterBody3D/Head/Camera3D/MeshInstance3D.get_surface_override_material(0)
@onready var character = $CharacterBody3D
@onready var head = $CharacterBody3D/Head
@onready var camera = $CharacterBody3D/Head/Camera3D
# Ray-casting
@onready var extrusion_killer_ray = $Extrusion_Killer_Ray
@onready var extrusion_shadow : CSGBox3D = $TrueExtrusionShadow
@onready var invalid_extrusion_shadow = $InvalidExtrusionShadow
# Extrusion UI
@onready var extrusion_distance_bar = $Control/ExtrusionDistanceBar
@onready var extrusion_distance_label = $Control/ExtrusionDistanceBar/Label
@onready var extrusion_distance_limit := $Control/ExtrusionDistanceBar/ColorRect
#@onready var extrusion_angle_bar_neg = $Control/ExtrusionAngleBarNegative
#@onready var extrusion_angle_bar_pos = $Control/ExtrusionAngleBarPositive
@onready var extrusion_angle_label = $Control/ExtrusionAngleBarNegative/Label

# Instantiate scene tutorial https://www.youtube.com/watch?v=ZwXPV5v9NaU
@export var extrusion_scene : PackedScene

var distance_cutoff
var extrusion_default = 1.
var extrusion_distance = extrusion_default
var extrusion_angle = 0
var building_on = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Setting shader parameter https://www.youtube.com/watch?v=6-eIEFPcvrU
	shader.set_shader_parameter("head_position",head.global_position)
	
	# Ray-casting https://docs.godotengine.org/en/stable/classes/class_raycast3d.html#class-raycast3d
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.global_position
	var camera_basis = camera.global_basis
	var look_direction = -camera_basis.z
	var ray_extrusion = ray_origin + look_direction * extrusion_distance + extrusion_angle/10. * camera.global_basis.y
	var extrusion_killer_hit
	var ray_hit_position : Vector3
	var ray_hit_normal : Vector3
	distance_cutoff = shader.get_shader_parameter("distance_cutoff")
	var valid_collision = true
	var within_distance_cutoff = true
	var collided_extrusion
	var distance
	
	if distance_cutoff and building_on:
		# Ray-cast to building surface
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + look_direction * distance_cutoff)
		query.exclude = [character]
		var result = space_state.intersect_ray(query)
		if result:
			# Prevent rays on forbidden objects
			if not result["collider"].get_layer_mask_value(1):
				valid_collision = false
			if result["collider"].get_layer_mask_value(3):
				collided_extrusion = result["collider"]
				extrusion_killer_hit = result["position"]
			ray_hit_position = result["position"]
			ray_hit_normal = result["normal"]
		else:
			within_distance_cutoff = false
	
	# Update extrusion angle text
	#if extrusion_angle <= 0:
		#extrusion_angle_bar_neg.value = -(extrusion_angle + 10)
		#extrusion_angle_bar_pos.value = 0
	#else:
		#extrusion_angle_bar_pos.value = extrusion_angle
		#extrusion_angle_bar_neg.value = -10
	#extrusion_angle_label.text = str(extrusion_angle)
	
	# Display extrusions
	extrusion_distance_bar.value = extrusion_distance
	if building_on:
		extrusion_distance_label.text = str(extrusion_distance)
		if within_distance_cutoff:
			distance = ray_origin.distance_squared_to(ray_hit_position)
			if valid_collision:
				extrusion_shadow.visible = true
				invalid_extrusion_shadow.visible = false
				extrusion_shadow.size.z = extrusion_distance
				extrusion_shadow.look_at_from_position(ray_hit_position + extrusion_distance / 2 * ray_hit_normal, ray_hit_position - extrusion_distance * ray_hit_normal, Vector3(0,1,0))
				extrusion_distance_limit.position.x = 640
			else:
				extrusion_shadow.visible = false
				invalid_extrusion_shadow.visible = true
				invalid_extrusion_shadow.position = ray_extrusion
				invalid_extrusion_shadow.look_at_from_position(ray_extrusion, ray_origin - distance * camera_basis.z, camera_basis.y)
				extrusion_distance_label.text += " (Build overlaps with invalid surface)"
		else:
			extrusion_shadow.visible = false
			invalid_extrusion_shadow.visible = true
			invalid_extrusion_shadow.position = ray_extrusion
			invalid_extrusion_shadow.look_at_from_position(ray_extrusion, ray_origin - distance_cutoff * 1.1 * camera_basis.z, camera_basis.y)
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
	
	# Extrusion distance adjustment
	if Input.is_action_pressed("ctrl") and Input.is_action_just_released("scroll_up"):
		var new_extrusion_angle = extrusion_angle + 1
		if new_extrusion_angle <= 10:
			extrusion_angle = new_extrusion_angle
	elif Input.is_action_pressed("shift") and Input.is_action_just_released("scroll_up"):
		var new_extrusion_distance = extrusion_distance + 0.1
		if new_extrusion_distance <= distance_cutoff:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = distance_cutoff
	elif Input.is_action_just_released("scroll_up"):
		var new_extrusion_distance = extrusion_distance + 1.
		if new_extrusion_distance <= distance_cutoff:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = distance_cutoff
	if Input.is_action_pressed("ctrl") and Input.is_action_just_released("scroll_down"):
		var new_extrusion_angle = extrusion_angle - 1
		if new_extrusion_angle >= -10:
			extrusion_angle = new_extrusion_angle
	elif Input.is_action_pressed("shift") and Input.is_action_just_released("scroll_down"):
		var new_extrusion_distance = extrusion_distance - 0.1
		if new_extrusion_distance >= 1.0:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = 1.0
	elif Input.is_action_just_released("scroll_down"):
		var new_extrusion_distance = extrusion_distance - 1.
		if new_extrusion_distance >= 1.0:
			extrusion_distance = new_extrusion_distance
		else:
			extrusion_distance = 1.0
	
	# Place extrusion
	if within_distance_cutoff and valid_collision:
		if Input.is_action_just_pressed("left_click"):
			_place_extrusion(extrusion_distance, ray_hit_position, ray_hit_normal, camera_basis)
	
	if Input.is_action_just_pressed("right_click"):
		if collided_extrusion:
			collided_extrusion.queue_free()
	
	# Toggle building
	if Input.is_action_just_pressed("e"):
		if building_on:
			building_on = false
		else:
			building_on = true

func _place_extrusion(extrusion_distance : float, ray_hit_position : Vector3, ray_hit_normal : Vector3, camera_basis : Basis) -> void:
	var extrusion : CSGBox3D = extrusion_scene.instantiate()
	extrusion.size.z = extrusion_distance
	extrusion.look_at_from_position(ray_hit_position + extrusion_distance / 2 * ray_hit_normal, ray_hit_position - ray_hit_normal, Vector3(0,1,0))
	# Check collision https://www.youtube.com/watch?v=ZwXPV5v9NaU
	var world_space = get_world_3d().direct_space_state
	var params = PhysicsShapeQueryParameters3D.new()
	params.collide_with_bodies = true
	params.collision_mask = 1
	params.shape = BoxShape3D.new()
	params.shape.size = extrusion.size
	params.transform = extrusion.transform
	var collision = world_space.collide_shape(params,1)
	if collision.is_empty():
		add_child(extrusion)
	else:
		pass
