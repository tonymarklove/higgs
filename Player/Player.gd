extends KinematicBody2D

export var rotate_to_follow_gravity = false
export var rotate_camera_with_player = false
export var player_relative_controls = false

signal jump_charge_changed(value)

var smoke_emitter = preload("res://Particles/SmokePuff.tscn")

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
const MAX_SAFE_IMPACT_SPEED = 50

var on_wall = false
var on_floor = false
var on_ceiling = false
var floor_velocity = Vector2()

var health = 5

func is_on_floor():
	return self.on_floor

func is_on_wall():
	return self.on_wall

func is_on_ceiling():
	return self.on_ceiling

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

func stop_controlled_movement():
	var player_right_direction = gravity_vector().tangent()

	var x_frac = player_right_direction.dot(Vector2(1,0))
	var y_frac = player_right_direction.dot(Vector2(0,-1))

	# Stop player movement from previous the frame along the walk axis
	velocity.x *= 1 - abs(x_frac)
	velocity.y *= 1 - abs(y_frac)

func get_input(delta):
	var player_right_direction = gravity_vector().tangent()
	var move = movement_option()

	if Input.is_action_pressed('ui_up'):
		for doorway in get_tree().get_nodes_in_group("doorways"):
			if doorway.overlaps_body(self):
				doorway.use_door()
				break

	velocity += player_right_direction * move * run_speed

	if move > 0:
		$AnimatedSprite.play("walk")
		$AnimatedSprite.flip_h = false
	elif move < 0:
		$AnimatedSprite.play("walk")
		$AnimatedSprite.flip_h = true
	else:
		$AnimatedSprite.play("idle")
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

	$Camera.rotating = rotate_camera_with_player

	var floor_normal = -gravity_vector() if gravity_mode == GRAVMODE_DIRECTION else Vector2(0,-1)

	stop_controlled_movement()

	if health > 0:
		get_input(delta)
	else:
		$AnimatedSprite.play("dead")

	velocity += gravity_vector() * gravity_strength * delta
	velocity = move_and_slide(velocity, floor_normal)

	if rotate_to_follow_gravity:
		rotate_to_gravity()

func move_and_slide(linear_velocity, floor_normal=Vector2(), slope_stop_min_velocity=5, max_bounces=4, floor_max_angle=0.785398):
	var motion = (floor_velocity + linear_velocity) * get_physics_process_delta_time();
	var lv = linear_velocity

	self.on_floor = false
	self.on_ceiling = false
	self.on_wall = false
	floor_velocity = Vector2()

	while(max_bounces):
		var collision = move_and_collide(motion)

		if !collision: break

		var collision_velocity = (collision.collider_velocity - motion).slide(collision.normal.tangent()).length()

		if collision_velocity > 30:
			var smoke = smoke_emitter.instance()
			smoke.position = collision.position
			smoke.emitting = true
			get_node("/root/GameWorld").add_child(smoke)
			health -= 1

		var cos_max_floor_angle = cos(floor_max_angle)
		var floor_collision_dot = collision.normal.dot(floor_normal)
		var ceiling_collision_dot = -floor_collision_dot

		if floor_collision_dot >= cos_max_floor_angle:
			# On floor. Do some extra work to stick to moving floors.
			self.on_floor = true
			floor_velocity = collision.collider_velocity

			var rel_v = lv - floor_velocity
			var hor_v = rel_v - floor_normal * floor_normal.dot(rel_v);

			if collision.travel.length() < 1 && hor_v.length() < slope_stop_min_velocity:
				var gt = get_global_transform()
				gt.origin -= collision.travel
				set_global_transform(gt)
				return Vector2()
		elif ceiling_collision_dot >= cos_max_floor_angle:
			self.on_ceiling = true
		else:
			self.on_wall = true

		var n = collision.normal
		motion = collision.remainder.slide(n)
		lv = lv.slide(n)

		max_bounces -= 1

		if motion.length() == 0:
			break

	return lv
