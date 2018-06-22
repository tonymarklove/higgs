extends KinematicBody2D

export (int) var SPEED

const GRAVITY_DIRECTIONS = [
	Vector2(0,1),
	Vector2(1,0),
	Vector2(0,-1),
	Vector2(-1,0)
]

var run_speed = 350
var jump_speed = -1000
var gravity = 5000
var rotation_time = 0.5

var velocity = Vector2()
var gravity_direction = 0

var game_time = 0
var rotation_at_gravity_change = 0
var last_gravity_change_time = 0

func gravity_vector():
	return GRAVITY_DIRECTIONS[gravity_direction]

func gravity_select(change):
	gravity_direction = (gravity_direction + change) % GRAVITY_DIRECTIONS.size()
	last_gravity_change_time = game_time
	rotation_at_gravity_change = self.rotation

func get_input():
	var face_direction = gravity_vector().tangent()
	
	var x_frac = face_direction.dot(Vector2(1,0))
	var y_frac = face_direction.dot(Vector2(0,-1))
	
	velocity.x *= 1 - abs(x_frac)
	velocity.y *= 1 - abs(y_frac)
	
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_select')
	var gravity_right = Input.is_action_just_pressed('gravity_right')
	var gravity_left = Input.is_action_just_pressed('gravity_left')
	var gravity_flip = Input.is_action_just_pressed('gravity_flip')
	
	if is_on_floor() and jump:
		velocity += gravity_vector() * jump_speed
	if right:
		$AnimatedSprite.flip_h = false		
		velocity += face_direction * run_speed
	if left:
		$AnimatedSprite.flip_h = true
		velocity -= face_direction * run_speed
		
	var walk_movement = velocity.dot(face_direction)
	
	if abs(walk_movement) > 0.1:
		$AnimatedSprite.play()
	else:
		$AnimatedSprite.stop()
		$AnimatedSprite.frame = 0

	if gravity_right:
		gravity_select(1)
		
	if gravity_left:
		gravity_select(-1)
		
	if gravity_flip:
		gravity_select(2)
		
func _physics_process(delta):
	game_time += delta
	
	velocity += gravity_vector() * gravity * delta
	get_input()
	velocity = move_and_slide(velocity, -gravity_vector())
	
	var desired_rotation = -acos(gravity_vector().dot(Vector2(0,1)))
	
	if gravity_vector().dot(Vector2(-1,0)) > 0:
		desired_rotation = -desired_rotation
		
	var weight = clamp(game_time - last_gravity_change_time, 0, rotation_time) / rotation_time
	var rotation = lerp(rotation_at_gravity_change, desired_rotation, weight)

	set_rotation(rotation)
	