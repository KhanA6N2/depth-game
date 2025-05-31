extends CharacterBody3D

# Speeds
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
#const SCROLL_SPEED = 50.0;

# Head bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
var base_fov = 90.0
const FOV_CHANGE = 1.5

# Focus
var focused = true

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and focused:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	if Input.is_action_just_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		focused = false
	if Input.is_action_just_pressed("left_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		focused = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if is_on_floor():
		#if direction:
			#velocity.x = direction.x * speed
			#velocity.z = direction.z * speed
		#else:
			#velocity.x = lerp(velocity.x, direction.x * speed, delta * 10.0)
			#velocity.z = lerp(velocity.z, direction.z * speed, delta * 10.0)
	#else:
		#velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		#velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
			velocity.x = 0
			velocity.z = 0
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	#var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	#var target_fov = base_fov + FOV_CHANGE * velocity_clamped
	#camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
