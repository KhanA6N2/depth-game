extends Node3D

@onready var shader : ShaderMaterial = $CharacterBody3D/Head/Camera3D/MeshInstance3D.get_surface_override_material(0)
@onready var character = $CharacterBody3D
@onready var head = $CharacterBody3D/Head
@onready var camera = $CharacterBody3D/Head/Camera3D
@onready var top_left_ray = $Top_Left_Ray
@onready var bottom_left_ray = $Bottom_Left_Ray
@onready var top_right_ray = $Top_Right_Ray
@onready var bottom_right_ray = $Bottom_Right_Ray
@onready var top_left_ray2 = $Top_Left_Ray2
@onready var bottom_left_ray2 = $Bottom_Left_Ray2
@onready var top_right_ray2 = $Top_Right_Ray2
@onready var bottom_right_ray2 = $Bottom_Right_Ray2

var distance_cutoff
var ray_length
var extrusion_default = 1.
var extrusion_distance = extrusion_default
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
	var top_left_corner = camera_position + 0.5 * camera_basis.x + 0.5 * camera_basis.y
	var bottom_left_corner = camera_position + 0.5 * camera_basis.x - 0.5 * camera_basis.y
	var top_right_corner = camera_position - 0.5 * camera_basis.x + 0.5 * camera_basis.y
	var bottom_right_corner = camera_position - 0.5 * camera_basis.x - 0.5 * camera_basis.y
	var top_left_extrusion = top_left_corner + look_direction * extrusion_distance
	var bottom_left_extrusion = bottom_left_corner + look_direction * extrusion_distance
	var top_right_extrusion = top_right_corner + look_direction * extrusion_distance
	var bottom_right_extrusion = bottom_right_corner + look_direction * extrusion_distance
	var ray_origins = [top_left_corner,bottom_left_corner,top_right_corner,bottom_right_corner]
	var ray_hits = PackedVector3Array()
	var ray_length = distance_cutoff
	#var collided_object
	if ray_length:
		for i in 4:
			var origin = ray_origins[i]
			var end = origin + look_direction * ray_length
			var query = PhysicsRayQueryParameters3D.create(origin, end)
			query.exclude = [character]
			var result = space_state.intersect_ray(query)
			# Prevent rays on different objects
			#if result.size() > 0 and i == 0:
				#collided_object = result["collider_id"]
			#if result.size() > 0 and collided_object == result["collider_id"]:
				#ray_hits.append(result["position"])
			#if collided_object.
			if result.size() > 0:
				# Prevent rays on forbidden objects
				var collided_object = result["collider"]
				if collided_object.get_layer_mask_value(1):
					ray_hits.append(result["position"])
	# Display ray hits
	if ray_hits.size() == 4 and building_on:
		top_left_ray.visible = true
		bottom_left_ray.visible = true
		top_right_ray.visible = true
		bottom_right_ray.visible = true
		top_left_ray.position = ray_hits[0]
		bottom_left_ray.position = ray_hits[1]
		top_right_ray.position = ray_hits[2]
		bottom_right_ray.position = ray_hits[3]
	else:
		top_left_ray.visible = false
		bottom_left_ray.visible = false
		top_right_ray.visible = false
		bottom_right_ray.visible = false
	
	# Display extrusions
	if ray_hits.size() == 4 and building_on:
		var cond1 = top_left_corner.distance_squared_to(top_left_extrusion) < top_left_corner.distance_squared_to(ray_hits[0])
		var cond2 = bottom_left_corner.distance_squared_to(bottom_left_extrusion) < bottom_left_corner.distance_squared_to(ray_hits[1])
		var cond3 = top_right_corner.distance_squared_to(top_right_extrusion) < top_right_corner.distance_squared_to(ray_hits[2])
		var cond4 = bottom_right_corner.distance_squared_to(bottom_right_extrusion) < bottom_right_corner.distance_squared_to(ray_hits[3])
		if cond1 or cond2 or cond3 or cond4:
			top_left_ray2.visible = true
			bottom_left_ray2.visible = true
			top_right_ray2.visible = true
			bottom_right_ray2.visible = true
			top_left_ray2.position = top_left_extrusion
			bottom_left_ray2.position = bottom_left_extrusion
			top_right_ray2.position = top_right_extrusion
			bottom_right_ray2.position = bottom_right_extrusion
		else:
			top_left_ray2.visible = false
			bottom_left_ray2.visible = false
			top_right_ray2.visible = false
			bottom_right_ray2.visible = false
	else:
		top_left_ray2.visible = false
		bottom_left_ray2.visible = false
		top_right_ray2.visible = false
		bottom_right_ray2.visible = false
	
	# Extrusion distance
	if Input.is_action_just_released("scroll_up"):
		var new_extrusion_distance = extrusion_distance + 0.25
		if new_extrusion_distance < ray_length:
			extrusion_distance = new_extrusion_distance
	if Input.is_action_pressed("sprint") and Input.is_action_just_released("scroll_up"):
		var new_extrusion_distance = extrusion_distance + 1.
		if new_extrusion_distance < ray_length:
			extrusion_distance = new_extrusion_distance
	if Input.is_action_just_released("scroll_down"):
		var new_extrusion_distance = extrusion_distance - 0.25
		if new_extrusion_distance > 1.0:
			extrusion_distance = new_extrusion_distance
	if Input.is_action_pressed("sprint") and Input.is_action_just_released("scroll_down"):
		var new_extrusion_distance = extrusion_distance - 1.
		if new_extrusion_distance > 1.0:
			extrusion_distance = new_extrusion_distance
	
	# Place extrusion
	if top_left_ray2.visible:
		if Input.is_action_just_pressed("left_click"):
			var ray_starts_and_end = PackedVector3Array(ray_origins)
			ray_starts_and_end.append_array(ray_hits)
			_place_extrusion(ray_starts_and_end, bottom_right_extrusion)
	
	if Input.is_action_just_pressed("build"):
		if building_on:
			building_on = false
		else:
			building_on = true

func _place_extrusion(vectors: PackedVector3Array, bottom_right_corner : Vector3) -> void:
	var extrusion = CSGPolygon3D.new()
	var distances : Array
	for i in 4:
		distances.append(vectors[i].distance_squared_to(vectors[i + 4]))
	var max_distance = distances.max()
	extrusion.depth = sqrt(max_distance) - extrusion_distance
	var camera_position = camera.global_position
	var camera_basis = camera.global_basis
	extrusion.look_at_from_position(bottom_right_corner, camera_position - max_distance * camera_basis.z, camera_basis.y)
	extrusion.use_collision = true
	add_child(extrusion)
