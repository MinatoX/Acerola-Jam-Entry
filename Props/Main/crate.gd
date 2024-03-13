extends CharacterBody3D


const SPEED = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var player = $/root/Node3D/Player.get_child(0) 

func _physics_process(delta):
	
	gravity = (player.gravity*2)
	
	if (player.gravity > 0):
		if not is_on_floor():
			velocity.y -= gravity * delta
	else:
		if not is_on_ceiling():
			velocity.y -= gravity * delta

	move_and_slide()
