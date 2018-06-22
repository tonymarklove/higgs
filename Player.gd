extends KinematicBody2D

export (int) var SPEED

var run_speed = 350
var jump_speed = -1000
var gravity = 2500

var velocity = Vector2()
var gravity_direction = Vector2(0, 1)

func get_input():
	var face_direction = gravity_direction.tangent()
	
	var x_frac = face_direction.dot(Vector2(1,0))
	var y_frac = face_direction.dot(Vector2(0,-1))
	
	velocity.x *= 1 - x_frac
	velocity.y *= 1 - y_frac
	
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_select')
	var gravity_right = Input.is_action_just_pressed('gravity_right')
	
	if is_on_floor() and jump:
		velocity += gravity_direction * jump_speed
	if right:
		velocity += face_direction * run_speed
	if left:
		velocity -= face_direction * run_speed

	if x_frac > 0:
		$AnimatedSprite.play()
	else:
		$AnimatedSprite.stop()

	if gravity_right:
		gravity_direction = Vector2(1, 0)

func _physics_process(delta):
	velocity += gravity_direction * gravity * delta
	get_input()
	velocity = move_and_slide(velocity, -gravity_direction)
	
	$Camera2D.set_rotation(acos(gravity_direction.dot(Vector2(0,1))))
	