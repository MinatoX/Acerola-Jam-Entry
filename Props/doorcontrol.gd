extends Node3D

#Closes the door after the player has entered the safe area to break LoS with the parrot

@onready var anim:AnimationPlayer = $/root/Node3D/NavigationRegion3D/Props/MainProps/CardSwipe/slidedoor/AnimationPlayer
@onready var pc = $/root/Node3D/Player.get_child(0)
@onready var parrot = $/root/Node3D/ParrotModel

@onready var doorPlayer:AudioStreamPlayer3D = $doorPlayer

var hasPlayed = false


func _ready():
	anim.animation_finished.connect(_playCloseSnd)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if (pc.is_on_ceiling() and !hasPlayed):
		anim.play()
		hasPlayed = true

func _playCloseSnd():
	doorPlayer.play()

func _on_door_close_body_entered(body):
	if (body.name == "player"):
		#parrot.position = $/root/Node3D/Phase2Markers/Marker3D.position
		var pScript = parrot.get_child(0)
		pScript.nav.target_position = $/root/Node3D/ParrotP2Spawn.position
		pScript.position = $/root/Node3D/ParrotP2Spawn.position
		pScript.currIdle = 0
		pScript.activeState = pScript.STATES.IDLE
		pScript.moveToLastSeen = false
		anim.play_backwards("finalopen")
		hasPlayed = false
