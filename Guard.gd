extends KinematicBody2D

const walk_speed = 200
const gravity_vector = Vector2(0,1)
const gravity_strength = 5000

var walk_vector = Vector2(1,0)
var velocity = Vector2()

onready var raycaster = RayCast2D.new()
onready var collision_shape = get_node("CollisionShape2D")
onready var sprite = get_node("AnimatedSprite")

func _ready():
	raycaster.enabled = true
	add_child(raycaster)

	sprite.play("walk")

func _physics_process(delta):
	velocity.x = 0
	velocity += gravity_vector * gravity_strength * delta
	velocity += walk_vector * walk_speed

	raycaster.position = collision_shape.position
	raycaster.cast_to = walk_vector * (Global.TILE_SIZE * 2)

	if raycaster.is_colliding():
		walk_vector = -walk_vector
		raycaster.cast_to = walk_vector * (Global.TILE_SIZE * 2)

	velocity = move_and_slide(velocity, Vector2(0,1))

	sprite.flip_h = velocity.x < 0
