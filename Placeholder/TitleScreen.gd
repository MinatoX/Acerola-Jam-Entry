extends Node3D

@onready var titleCam:Camera3D = $TitleCam
@onready var pCam:Camera3D = $"../Player".get_child(0).get_child(1).get_child(0) #Should be the camera I hope
@onready var player = $"../Player".get_child(0)
@onready var titleUI = $Control
@onready var titleCard = $titleCard

@onready var inCage:Marker3D = $InCage
@onready var birb = $"../ParrotModel".get_child(0)
@onready var pSpawn:Node3D = $PlayerSpawn

@onready var introBox = $"../Introbox"

var pRet

#TODO: REPLACE PICKED UP KEYCARDS
#Set keycards to invisible instead of outright removing them from the scene
#Make the keycards visible again once the Play button is clicked
#Also reset cards obtained and cards swiped

var gameRestart = false

# Called when the node enters the scene tree for the first time.
func _ready():
	player.lockControls = true
	pRet = player.get_parent().get_child(2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (gameRestart):
		pRet.visible = false
		titleCam.current = true
		introBox.activated = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		titleCam.visible = true
		titleUI.visible = true
		player.global_position = pSpawn.global_position
		player.rotation = Vector3.ZERO
		player.velocity = Vector3.ZERO
		titleCard.visible = true
		gameRestart = false


func _on_play_btn_pressed():
	#holy moly so much setup is needed to get the game functional
	titleCam.current = false
	titleCam.visible = false
	titleCard.visible = false
	pCam.current = true
	player.lockControls = false
	player.cardsFound = 0
	player.swiped = 0
	pRet.visible = true
	
	var mat:StandardMaterial3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/indicator/lightCube.material_override
	mat.albedo_color = Color(1, 0, 0)
	mat.emission = Color(1, 0, 0)
	
	var mat2:StandardMaterial3D = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/indicator2/lightCube.material_override
	mat2.albedo_color = Color(1, 0, 0)
	mat2.emission = Color(1, 0, 0)
	
	player.slideDoorAnim.play_backwards("finalopen") #Ensures door is shut
	
	titleUI.visible = false
	#birb.activeState = birb.STATES.PATROL
	birb.posFound = false
	birb.get_parent().global_position = inCage.global_position
	birb.phase2 = false
	player.global_position = pSpawn.global_position
	player.rotation = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
