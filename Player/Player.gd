extends KinematicBody2D

export var rotate_to_follow_gravity = false
export var rotate_camera_with_player = false
export var player_relative_controls = false

signal jump_charge_changed(value)

const GRAVITY_DIRECTIONS = [
	Vector2(0,1),
	Vector2(1,0),
	Vector2(0,-1),
	Vector2(-1,0)
]

enum {
	GRAVMODE_DIRECTION,
	GRAVMODE_JUMP
}

enum {
	GRAVJUMP_HELD,
	GRAVJUMP_RELEASED,
	GRAVJUMP_USED
}

var run_speed = 500
var jump_speed = -1500
var gravity_strength = 5000
var rotation_time = 0.5

var velocity = Vector2()
var gravity_direction = 0

var game_time = 0
var rotation_at_gravity_change = 0
var last_gravity_change_time = 0

var gravity_mode = GRAVMODE_JUMP
var gravity_jump_action = GRAVJUMP_RELEASED

var gravity_jump_charge = 1.0
const GRAVITY_JUMP_MAXIMUM_TIME = 0.5

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

func rotating_camera_movement():
	var right = 1 if Input.is_action_pressed('ui_right') else 0
	var left = 1 if Input.is_action_pressed('ui_left') else 0

	return (right - left)

func fixed_camera_movement():
	var player_right_direction = gravity_vector().tangent()

	var x_frac = player_right_direction.dot(Vector2(1,0))
	var y_frac = player_right_direction.dot(Vector2(0,-1))

	var right = 1 if Input.is_action_pressed('ui_right') else 0
	var left = 1 if Input.is_action_pressed('ui_left') else 0
	var up = 1 if Input.is_action_pressed('ui_up') else 0
	var down = 1 if Input.is_action_pressed('ui_down') else 0

	return ((right * x_frac) - (left * x_frac) + (up * y_frac) - (down * y_frac))

func movement_option():
	if player_relative_controls || rotate_camera_with_player:
		return rotating_camera_movement()
	else:
		return fixed_camera_movement()

func gravity_direction_select():
	if player_relative_controls || rotate_camera_with_player:
		rotating_camera_gravity_select()
	else:
		fixed_camera_gravity_select()

func gravity_jump(delta):
	var jump = Input.is_action_pressed('ui_select')

	var change_in_charge = clamp(delta / GRAVITY_JUMP_MAXIMUM_TIME, 0, 1)

	if gravity_jump_action == GRAVJUMP_HELD:
		if jump:
			if gravity_jump_charge < 0.01:
				gravity_jump_action = GRAVJUMP_USED
				gravity_select(gravity_index_from_offset(2))
			else:
				gravity_jump_charge = clamp(gravity_jump_charge - change_in_charge, 0, 1)
		else:
			gravity_jump_action = GRAVJUMP_RELEASED
			gravity_select(gravity_index_from_offset(2))
	elif gravity_jump_action == GRAVJUMP_RELEASED:
		if jump:
			gravity_jump_action = GRAVJUMP_HELD
			gravity_select(gravity_index_from_offset(2))
			gravity_jump_charge = clamp(gravity_jump_charge - change_in_charge, 0, 1)
	else:
		if !jump:
			gravity_jump_action = GRAVJUMP_RELEASED

	if is_on_floor():
		gravity_jump_charge = clamp(gravity_jump_charge + change_in_charge, 0, 1)

	emit_signal("jump_charge_changed", gravity_jump_charge)

func get_input(delta):
	var player_right_direction = gravity_vector().tangent()

	var x_frac = player_right_direction.dot(Vector2(1,0))
	var y_frac = player_right_direction.dot(Vector2(0,-1))

	# Stop player movement from previous the frame along the walk axis
	velocity.x *= 1 - abs(x_frac)
	velocity.y *= 1 - abs(y_frac)

	var move = movement_option()

	if Input.is_action_pressed('ui_up'):
		for doorway in get_tree().get_nodes_in_group("doorways"):
			if doorway.overlaps_body(self):
				doorway.use_door()
				break

	velocity += player_right_direction * move * run_speed

	if move > 0:
		$AnimatedSprite.play()
		$AnimatedSprite.flip_h = false
	elif move < 0:
		$AnimatedSprite.play()
		$AnimatedSprite.flip_h = true
	else:
		$AnimatedSprite.stop()
		$AnimatedSprite.frame = 0

	match gravity_mode:
		GRAVMODE_DIRECTION:
			var jump = Input.is_action_just_pressed('ui_select')

			if is_on_floor() and jump:
				velocity += gravity_vector() * jump_speed
				
			gravity_direction_select()

		GRAVMODE_JUMP:
			gravity_jump(delta)

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

	get_input(delta)
	velocity += gravity_vector() * gravity_strength * delta
	velocity = move_and_slide(velocity, -gravity_vector())

	if rotate_to_follow_gravity:
		rotate_to_gravity()