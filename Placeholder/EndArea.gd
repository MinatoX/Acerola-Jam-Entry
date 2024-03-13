extends Area3D

@export var intenseshd:ShaderMaterial

@onready var playerShd:MeshInstance3D = $/root/Node3D/Player.get_child(0).get_child(1).get_child(0).get_child(0)
@onready var endRect:TextureRect = $"../EndRect"

@onready var player = $/root/Node3D/Player.get_child(0)

@onready var amb:AudioStreamPlayer = $/root/Node3D/Ambience
@export var endBgm:AudioStreamWAV

@onready var chromRect:ColorRect = $/root/Node3D/CanvasLayer/CanvasPost

# Called when the node enters the scene tree for the first time.
func _ready():
	print(playerShd.name)
	pass # Replace with function body.

func _on_body_entered(body):
	if (body.name == "player"):
		print("Game over")
		playerShd.material_override = intenseshd #This is NOT the shader plane! Correct this!
		player.gameEnding = true
		amb.stop()
		amb.stream = endBgm
		amb.play()
		await get_tree().create_timer(5.00).timeout
		player.lockControls = true
		endRect.visible = true
		await get_tree().create_timer(10.00).timeout
		get_tree().quit()
