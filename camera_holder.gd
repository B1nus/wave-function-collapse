extends CharacterBody2D

@export var speed = 100.0


func _physics_process(delta):
	var direction = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if direction:
		velocity = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)

	move_and_slide()
