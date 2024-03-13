extends CharacterBody3D

#Movement controller settings
const SPEED = 5.0
const SPRINT_SPEED = 7.0
const JUMP_VELOCITY = 4.5
const mouseSens = 0.002


@onready var cam:Camera3D = $MeshInstance3D/Camera3D
@onready var camCast:RayCast3D = $MeshInstance3D/Camera3D/RayCast3D

#Noises
@onready var footstepSnd:AudioStreamPlayer = $"../FootstepSnd"

#Card swiping
@onready var swipePlayer:AudioStreamPlayer3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/Node/Reader/swipePlayer

#For later post processing
@onready var canvasPost:ColorRect = $/root/Node3D/CanvasLayer/CanvasPost

#Camera bobbing settings
var camBobSpd = 0.015
var camBobSprint = 0.02
var camRestY
var camBobHeight = 0.3
var camDir = 1

#Gameplay Vars
var cardsFound = 0
var swiped = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var isFlipped = false

#For sending animation play signal to the door
@onready var slideDoorAnim:AnimationPlayer = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/slidedoor/AnimationPlayer

var lockControls = false
@onready var pause = $/root/Node3D/Pause

var gameEnding = false

func _ready():
	camRestY = cam.position.y
	camBobHeight += camRestY
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if (pause.paused):
		return
	
	if (Input.is_action_just_pressed("mb_left")):
		checkPickup()

func _physics_process(delta):
	if (pause.paused):
		return

	camBob()
	var useSpd = SPEED
	if (Input.get_action_strength("kb_shift") > 0):
		useSpd = SPRINT_SPEED
	
	# Add the gravity.
	if (!is_on_floor() and !isFlipped):
		velocity.y -= gravity * delta
			
	if (isFlipped and !is_on_ceiling() or !isFlipped and !is_on_floor()):
		velocity.y -= gravity * delta
	
	if (is_on_ceiling() and isFlipped): #Disable chromatic aberration effect
		if (canvasPost.visible and !gameEnding):
			canvasPost.visible = false
			lockControls = false

	if (lockControls):
		move_and_slide() #Still apply gravity
		return #Dont run movement if controls are locked

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("kb_a", "kb_d", "kb_w", "kb_s")
	
	if (isFlipped):
		#Flip input vector if gravity is flipped
		input_dir = Input.get_vector("kb_d", "kb_a", "kb_s", "kb_w")
	#Update move direction based on camera rotation
	#var dir = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, cam.position.y)
	var direction = (cam.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if (isFlipped):
		#Flip only the x axis of direction vector if gravity is flipped
		direction.x *= -1
	
	if direction:
		velocity.x = direction.x * useSpd
		velocity.z = direction.z * useSpd
	else:
		velocity.x = move_toward(velocity.x, 0, useSpd)
		velocity.z = move_toward(velocity.z, 0, useSpd)

	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var rotX = cam.rotation.x - event.relative.y * mouseSens
		cam.rotation.x = clamp(rotX, -1.39626, 1.39626)
		cam.rotation.y -= event.relative.x * mouseSens

func checkPickup():
	camCast.force_raycast_update()
	if (camCast.is_colliding()):
		var collider = camCast.get_collider()
		if (collider.name == "card" and collider.get_parent().get_parent().get_parent().get_parent().get_parent().visible):
			cardsFound += 1
			print("Card found")
			#Lol this sucks
			collider.get_parent().get_parent().get_parent().get_parent().get_parent().visible = false
		elif (collider.name == "cardswipe"):
			if (cardsFound > 0):
				cardsFound -= 1
				swiped += 1
				swipePlayer.play()
				if (swiped == 1):
					#Swap out material color for indicator 1
					var mat:StandardMaterial3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/indicator/lightCube.material_override
					mat.albedo_color = Color(0, 1, 0)
					mat.emission = Color(0, 1, 0)
				elif (swiped == 2):
					#Swap out material color for indicator 2 and open the door
					var mat:StandardMaterial3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/indicator2/lightCube.material_override
					mat.albedo_color = Color(0, 1, 0)
					mat.emission = Color(0, 1, 0)
					slideDoorAnim.play("finalopen")
					pass
	
func camBob():
	var useBob = camBobSpd
	if (Input.get_action_strength("kb_shift") > 0):
		useBob = camBobSprint
		
	if (velocity.x != 0 or velocity.z != 0):
		cam.position.y += (useBob*camDir)
		if (camDir == 1): #Moving up
			if (cam.position.y > camBobHeight):
				camDir = -1
		else: #Moving down
			if (cam.position.y < camRestY):
				camDir = 1
				#Play footstep noise when cam reaches rest position
				footstepSnd.pitch_scale = randf_range(0.95, 1.05) #Add some slight variance to SE
				footstepSnd.play()
	elif (velocity.x == 0 and velocity.z == 0):
		#Rest
		if (cam.position.y > camRestY and cam.position.y > camRestY + camBobSpd):
			cam.position.y -= camBobSpd
		else:
			cam.position.y = camRestY


func _on_grav_area_body_entered(body):
	if (body.name == "player" and !isFlipped):
		print("Player reached the grav spot")
		canvasPost.visible = true
		gravity*=-1
		#Rotate the player
		rotation_degrees.x = 180
		isFlipped = true
		lockControls = true
		velocity.x = 0
		velocity.y = 0
