extends CharacterBody3D

#Settings
@export var spd = 7
@export var pursueSpd = 10
@export var acc = 10
@export var idleTime = 5
@export var maxLooks = 4
@export var lookTime = 2

#Look settings
var currLook = 0
var lookCount = 0
var currIdle = 0
var changeLook = false
var hasLooked = false

#References
@onready var nav:NavigationAgent3D = $NavigationAgent3D
@onready var anim:AnimationTree = $AnimationTree
@onready var animPlayer:AnimationPlayer = $"../AnimationPlayer"
@onready var losArea:Area3D = $LineOfSight
@onready var losRay:RayCast3D = $losRay
@onready var player:Node3D = $/root/Node3D/Player
@onready var head:Node3D = $Parrot/Head/Beak
@onready var gameOverCam:Camera3D = $GameOverCam
@onready var pSpawn:Node3D = $/root/Node3D/TitleScreen/PlayerSpawn

@onready var card1:Node3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/Keycard
@onready var card2:Node3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/Keycard2

@onready var pause = $/root/Node3D/Pause

#Audio management
@onready var mainPlayer:AudioStreamPlayer = $/root/Node3D/Ambience
@onready var parrotPlayer:AudioStreamPlayer3D = $parrotPlayer
@onready var parrotPlayer2:AudioStreamPlayer3D = $parrotPlayer2

@export var footstep:AudioStreamWAV
@export var scream:AudioStreamWAV
@export var bite:AudioStreamWAV
@export var chaseFan:AudioStreamWAV
@export var talkNoise:AudioStreamWAV
@export var grabFan:AudioStreamWAV
@export var ambience:AudioStreamWAV

#Chasing Player Stuffs
var lastPlayerPos:Vector3 = Vector3.ZERO
var moveToLastSeen = false

var phase2 = false

var chomped = false

#Set up state machine
enum STATES {
	IDLE,
	PATROL,
	PURSUE,
	LOOK,
	GAMEOVER,
	TITLESCREEN
}

#Navigation Stuffs
var posFound = false
var lastPos = 0
var waypoints:Array
var phase2Waypoints:Array

#Set current state
var activeState:STATES = STATES.TITLESCREEN

var gameOverSetUp = false

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	idleTime *= 30 #Not using a timer for this cuz i didnt learn til later that timer node was a thing
	lookTime *= 30
	
	var markParent = $/root/Node3D/Markers
	var phase2Parent = $/root/Node3D/Phase2Markers
	
	#Get our navigation markers
	waypoints = markParent.get_children()
	nav.target_position = waypoints[0].position
	lastPos = 0
	
	phase2Waypoints = phase2Parent.get_children()


func _process(delta):
	animHandler() #Animate this stupid bird
	audioHandler() #Sound
	
	#Check for phase 2
	if (!phase2 and player.get_child(0).isFlipped):
		phase2 = true
		currIdle = 0
		activeState = STATES.IDLE
	
	if (activeState != STATES.LOOK and hasLooked): #Fix disoriented head
		print("Fixing disoriented features")
		head.rotation = Vector3.ZERO
		losArea.rotation = Vector3.ZERO
		losRay.rotation = Vector3.ZERO
		hasLooked = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if (pause.paused): #Stop running AI if paused
		return
	
	if (velocity.x != 0 or velocity.z != 0):
		bounce()
	elif (!is_on_floor()):
		velocity.y=-0.5
	
	################################
	#GAME OVER STATE
	################################
	if (activeState == STATES.GAMEOVER):
		if (!gameOverSetUp):
			player.get_child(0).lockControls = true
			var pCam:Camera3D = player.get_child(0).get_child(1).get_child(0)
			player.visible = false
			pCam.current = false
			player.global_position = pSpawn.global_position
			
			gameOverCam.current = true
			gameOverSetUp = true
		elif(chomped):
			#parrotPlayer2.stream = bite
			#parrotPlayer2.play()
			gameOverCam.get_child(0).visible = true
			var title = $/root/Node3D/TitleScreen
			#Reset parrot vars
			await get_tree().create_timer(1.00).timeout #Wait for black screen to be here for a bit
			title.gameRestart = true
			gameOverCam.current = false
			activeState = STATES.TITLESCREEN
			gameOverSetUp = false
			player.visible = true
			gameOverCam.get_child(0).visible = false
			position = Vector3.ZERO
			global_position = title.inCage.global_position
			rotation = Vector3.ZERO
			card1.visible = true
			card2.visible = true
			chomped = false
			#Reset Audio
			mainPlayer.stop()
			mainPlayer.stream = ambience
			mainPlayer.play()
			
	################################
	#PATROL STATE
	################################
	elif (activeState == STATES.PATROL):
		
		if (!posFound):
			pickDest()
			posFound = true
		
		if (global_position.distance_to(nav.target_position) < 5):
			#activeState = STATES.IDLE #TODO: Look state
			activeState = STATES.LOOK
			currIdle = 0
	
		var dir = Vector3()
	
		dir = nav.get_next_path_position() - global_position
		look_at(nav.get_next_path_position())
		dir = dir.normalized()
	
		velocity = velocity.lerp(dir*spd, acc*delta)
	
		move_and_slide()
	
	################################
	#PURSUE STATE
	################################
	elif (activeState == STATES.PURSUE):
		
		if (phase2):
			var pc = player.get_child(0)
			pc.isFlipped = false
			pc.rotation_degrees.x = 0
			pc.gravity *= -1
			phase2 = false
		
		if (!moveToLastSeen):
			nav.target_position = player.get_child(0).global_transform.origin
		else:
			nav.target_position = lastPlayerPos
		
		var dir = Vector3()
		dir = nav.get_next_path_position() - global_position
		look_at(nav.get_next_path_position())
		dir = dir.normalized()
		velocity = velocity.lerp(dir*pursueSpd, acc*delta)
		move_and_slide()
		
		if (global_position.distance_to(nav.target_position) < 2):
			if (moveToLastSeen):
				activeState = STATES.LOOK
			else:
				activeState = STATES.GAMEOVER
		
	################################
	#LOOK STATE
	################################
	elif (activeState == STATES.LOOK):
		#Look in some directions
		if (lookCount <= maxLooks):
			if (changeLook):
				var xLook = randi_range(-3, 3)
				var zLook = randi_range(-3, 3)
				var lookPos = Vector3(global_position.x+xLook, global_position.y+2, global_position.z+zLook)
				if (phase2):
					lookPos.y+=4
				
				var pChance = randi_range(0, 4) #25% chance to look directly at the player
				if (phase2):
					if (pChance < 4): #Make the parrot much more likely to look at the player in phase 2 to encourage crate usage
						print("Rolled to look at the player")
						lookPos = player.get_child(0).global_transform.origin
				else:
					if (pChance == 0):
						print("Rolled to look at the player")
						lookPos = player.get_child(0).global_transform.origin
				
				#look_at(lookPos)
				head.look_at(lookPos)
				head.rotation.x = 0
				head.rotation.z = 0
				losArea.look_at(lookPos)
				losRay.look_at(lookPos)
				
				print("Changing look direction")
				
				hasLooked = true
				changeLook = false

			currLook+=1
			
			if (currLook >= lookTime):
				changeLook = true
				lookCount+=1
				currLook = 0
		else:
			lookCount = 0
			activeState = STATES.IDLE
			currIdle = 0
	
	################################
	#IDLE STATE
	################################
	elif (activeState == STATES.IDLE):
		currIdle+=1
		if (currIdle > idleTime):
			activeState = STATES.PATROL
			posFound = false

func pickDest():
	var randIndex = lastPos
	while (randIndex == lastPos): #Ensure we don't pick the same target dest twice
		if (!phase2):
			randIndex = randi_range(0, waypoints.size()-1)
			nav.target_position = waypoints[randIndex].position
		else:
			randIndex = randi_range(0, phase2Waypoints.size()-1)
			nav.target_position = phase2Waypoints[randIndex].position
	lastPos = randIndex

func bounce():
	if (is_on_floor()):
		
		#Play bounce noise
		if (parrotPlayer.stream != footstep):
			parrotPlayer.stream = footstep
		parrotPlayer.play()
		
		velocity.y = 10
	else:
		velocity.y-=0.5

func animHandler(): #Set animation states
	anim.set("parameters/conditions/isIdling", activeState == STATES.IDLE or activeState == STATES.LOOK or activeState == STATES.TITLESCREEN)
	anim.set("parameters/conditions/isPatrolling", activeState == STATES.PATROL)
	anim.set("parameters/conditions/isPursuing", activeState == STATES.PURSUE)
	anim.set("parameters/conditions/isGameOver", activeState == STATES.GAMEOVER)

func audioHandler():
	if (activeState == STATES.PURSUE):
		if (mainPlayer.stream != chaseFan):
			mainPlayer.stop()
			mainPlayer.stream = chaseFan
			mainPlayer.play()
			parrotPlayer2.stream = talkNoise
			parrotPlayer2.play()
	elif (mainPlayer.stream != ambience and activeState != STATES.GAMEOVER):
		mainPlayer.stop()
		mainPlayer.stream = ambience
		mainPlayer.play()
		parrotPlayer2.stop()
		
	if (activeState == STATES.GAMEOVER):
		if (mainPlayer.stream != grabFan):
			mainPlayer.stop()
			mainPlayer.stream = grabFan
			mainPlayer.play()
	
	if (player.get_child(0).lockControls and player.get_child(0).isFlipped):
		#Play scream SE
		if (parrotPlayer2.stream != scream):
			parrotPlayer2.stop()
			parrotPlayer2.stream = scream
			parrotPlayer2.play()
	elif (parrotPlayer2.stream == scream and player.get_child(0).isFlipped and !player.get_child(0).lockControls):
		parrotPlayer2.stream = talkNoise

#Check area and los raycast to see if the player has been spotted
func _on_col_check_time_timeout():
	if (activeState == STATES.GAMEOVER or activeState == STATES.TITLESCREEN): #Game has ended stop searching
		return
	
	if (activeState == STATES.PURSUE):
		#Check to see if player is still in LoS
		var playerPos = player.get_child(0).global_transform.origin
		losRay.look_at(playerPos, Vector3.UP)
		losRay.force_raycast_update()
		if (losRay.is_colliding()):
			if (moveToLastSeen):
				#Need to get area confirmation as well as LoS
				var overlaps = losArea.get_overlapping_bodies()
				if (overlaps.size() > 0):
					for overlap in overlaps:
						if (overlap.name == "player"):
							var collider = losRay.get_collider()
							if (collider.name == "player"): #Player has been relocated
								moveToLastSeen = false
								lastPlayerPos = playerPos
			else:
				var collider = losRay.get_collider()
				if (collider.name != "player"):
					#He's done escaped; move to last player position
					moveToLastSeen = true
				else:
					#Record last player position
					#TODO: Maybe move to closest marker to player?
					lastPlayerPos = playerPos
	else:
		var overlaps = losArea.get_overlapping_bodies()
		if (overlaps.size() > 0):
			for overlap in overlaps:
				if (overlap.name == "player"):
					var playerPosition = overlap.global_transform.origin
					losRay.look_at(playerPosition, Vector3.UP)
					losRay.force_raycast_update()
				
					if (losRay.is_colliding()):
						var collider = losRay.get_collider()
						if (collider.name == "player"):
							activeState = STATES.PURSUE
							moveToLastSeen = false
							

func _on_animation_tree_animation_finished(anim_name):
	if (gameOverSetUp):
		parrotPlayer2.stream = bite
		parrotPlayer2.play()
		chomped = true
