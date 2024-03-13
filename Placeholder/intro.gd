extends Area3D

#Turn off the lights
@onready var title = $/root/Node3D/TitleScreen
@onready var lightParent = $/root/Node3D/Lights

@onready var audioPlayer:AudioStreamPlayer3D = $AudioStreamPlayer3D

@onready var birb = $"../ParrotModel".get_child(0)

var activated = false

var lightChildren

func _ready():
	lightChildren = lightParent.get_children()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (!activated):
		if (lightChildren[0].get_child(1).light_energy == 1):
			for lights in lightChildren:
				lights.get_child(1).light_energy = 3


func _on_body_entered(body):
	if (body.name == "player" and !activated):
		audioPlayer.play()
		for lights in lightChildren:
			lights.get_child(1).light_energy = 1 #Dim light levels for better atmosphere
		
		birb.get_parent().global_position = $/root/Node3D/Markers/PipingMark.global_position
		birb.position = Vector3.ZERO
		birb.activeState = birb.STATES.PATROL
		activated = true
