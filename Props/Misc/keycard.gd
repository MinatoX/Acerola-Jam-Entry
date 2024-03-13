extends Node3D

@onready var snd = $pickupSnd

var isPicked = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (!visible and !isPicked):
		snd.play()
		isPicked = true
	elif (visible and isPicked):
		isPicked = false
