extends KinematicBody2D

export (int) var SPEED

func _process(delta):
	var velocity = Vector2() # the player's movement vector
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if velocity.length() > 0:
		velocity = velocity.normalized() * SPEED

	var collision_info = move_and_collide(velocity * delta)

	if collision_info:
		velocity = velocity.bounce(collision_info.normal)
	