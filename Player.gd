extends KinematicBody2D

export var rotate_to_follow_gravity = true
export var rotate_camera_with_player = false
export var player_relative_controls = false

const GRAVITY_DIRECTIONS = [
	Vector2(0,1),
	Vector2(1,0),
	Vector2(0,-1),
	Vector2(-1,0)
]

var run_speed = 500
var jump_speed = -1500
var gravity = 5000
var rotation_time = 0.5

var velocity = Vector2()
var gravity_direction = 0

var game_time = 0
var rotation_at_gravity_change = 0
var last_gravity_change_time = 0

var gravity_jump_charge = 0.0
var gravity_jump_maximum_time = 0.5
var gravity_jump_start_time = 0

func clamp_and_normalize(input, a, b):
	return clamp(input, a, b) / (b - a)

func gravity_vector():
	return GRAVITY_DIRECTIONS[gravity_direction]

func gravity_index_from_offset(offset):
	return (gravity_direction + offset) % GRAVITY_DIRECTIONS.size()

func gravity_select(direction_index):
	gravity_direction = direction_index
	last_gravity_change_time = game_time
	rotation_at_gravity_change = self.rotation

func gravity_change_from_input():
	if Input.is_action_just_pressed('gravity_right'):
		return 1

	if Input.is_action_just_pressed('gravity_left'):
		return -1
	
	if Input.is_action_just_pressed('gravity_up'):
		return 2

	return 0

func rotating_camera_gravity_select():
	var change = gravity_change_from_input()
	
	if change != 0:
		gravity_select(gravity_index_from_offset(change))

func fixed_camera_gravity_select():
	if Input.is_action_just_pressed('gravity_right'):
		gravity_select(1)

	if Input.is_action_just_pressed('gravity_left'):
		gravity_select(3)
	
	if Input.is_action_just_pressed('gravity_up'):
		gravity_select(2)

	if Input.is_action_just_pressed('gravity_down'):
		gravity_select(0)

func get_input():
	var player_right_direction = gravity_vector().tangent()

	var x_frac = player_right_direction.dot(Vector2(1,0))
	var y_frac = player_right_direction.dot(Vector2(0,-1))

	# Stop player movement from previous the frame along the walk axis
	velocity.x *= 1 - abs(x_frac)
	velocity.y *= 1 - abs(y_frac)

	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var up = Input.is_action_pressed('ui_up')
	var down = Input.is_action_pressed('ui_down')
	var jump = Input.is_action_just_pressed('ui_select')

	if is_on_floor() and jump:
		velocity += gravity_vector() * jump_speed

	var control_direction = Vector2(0,0)

	if right:
		control_direction.x = 1 * abs(x_frac)
	if left:
		control_direction.x = -1 * abs(x_frac)
	if up:
		control_direction.y = -1 * abs(y_frac)
	if down:
		control_direction.y = 1 * abs(y_frac)

	velocity += control_direction * run_speed
			
	if right:
		$AnimatedSprite.flip_h = false
	if left:
		$AnimatedSprite.flip_h = true
		
	var walking = left || right || up || down

	if walking:
		$AnimatedSprite.play()
	else:
		$AnimatedSprite.stop()
		$AnimatedSprite.frame = 0

	if player_relative_controls || rotate_camera_with_player:
		rotating_camera_gravity_select()
	else:
		fixed_camera_gravity_select()

func rotate_to_gravity():
	var desired_rotation = -gravity_vector().angle_to(Vector2(0,1))

	if abs(rotation_at_gravity_change - desired_rotation) > PI:
		if rotation_at_gravity_change > desired_rotation:
			rotation_at_gravity_change -= 2 * PI
		else:
			rotation_at_gravity_change += 2 * PI

	var weight = clamp_and_normalize(game_time - last_gravity_change_time, 0, rotation_time)
	var rotation = lerp(rotation_at_gravity_change, desired_rotation, weight)

	set_rotation(rotation)

func _physics_process(delta):
	game_time += delta

	$Camera2D.rotating = rotate_camera_with_player

	velocity += gravity_vector() * gravity * delta
	get_input()
	velocity = move_and_slide(velocity, -gravity_vector())

	if rotate_to_follow_gravity:
		rotate_to_gravity()
