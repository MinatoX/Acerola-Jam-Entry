extends Control

var paused = false
@onready var player = $"../Player".get_child(0)
@onready var parrot = $"../ParrotModel".get_child(0)
@onready var title = $/root/Node3D/TitleScreen

#Resolution Settings
@onready var vidPanel:Panel = $VideoConfig
@onready var titleVidPanel:Panel = $/root/Node3D/TitleScreen/Control/VideoConfig
@onready var resDrop:OptionButton = $VideoConfig/ResDrop
@onready var titleRes:OptionButton = $/root/Node3D/TitleScreen/Control/VideoConfig/titleRes
@onready var titleFs:CheckBox = $/root/Node3D/TitleScreen/Control/VideoConfig/fsBox
@onready var fsCheck:CheckBox = $VideoConfig/CheckBox
var Resolutions: Dictionary = {
	"3840x2160":Vector2(3840,2160),
	"2560x1440":Vector2(2560,1440),
	"1920x1080":Vector2(1920,1080),
	"1366x768":Vector2(1366,768),
	"1536x864":Vector2(1535,864),
	"1280x720":Vector2(1280,720),
	"1440x900":Vector2(1440,900),
	"1600x900":Vector2(1600,900),
	"1024x600":Vector2(1024,600),
	"800x600":Vector2(800,600),
	"640x360":Vector2(640,360)
}

#Credits gag
@onready var credPnl:Panel = $/root/Node3D/TitleScreen/Control/credPnl
@onready var playBtn:Button = $/root/Node3D/TitleScreen/Control/PlayBtn

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	addRes()
	if (OS.get_name() == "Web"): #Hide resolution settings
		vidPanel.visible = false
		titleVidPanel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Don't let player pause if their controls are locked by other means
	if (Input.is_action_just_pressed("kb_esc") and !player.lockControls or Input.is_action_just_pressed("kb_tab") and !player.lockControls):
		visible = !visible
		paused = visible
		if (visible):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#This is easy
func _on_resume_btn_pressed():
	visible = false
	paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Do some hax to get to title screen early
func _on_title_btn_pressed():
	parrot.activeState = parrot.STATES.TITLESCREEN
	title.gameRestart = true
	parrot.position = Vector3.ZERO
	parrot.global_position = title.inCage.global_position
	parrot.rotation = Vector3.ZERO
	parrot.card1.visible = true
	parrot.card2.visible = true
	player.isFlipped = false
	player.rotation = Vector3.ZERO
	parrot.phase2 = false
	visible = false
	paused = false

func addRes():
	var currRes:Vector2 = get_viewport().get_size()
	
	print(currRes)
	
	var ind = 0
	
	for r in Resolutions:
		resDrop.add_item(r, ind)
		titleRes.add_item(r, ind)
		
		if (Resolutions[r] == currRes):
			resDrop._select_int(ind)
			titleRes._select_int(ind)
		ind += 1

#Quit the game
func _on_quit_btn_pressed():
	get_tree().quit()

#Fullscreen
func _on_check_box_toggled(toggled_on):
	titleFs.button_pressed = toggled_on
	if (toggled_on):
		resDrop.visible = false
		titleRes.visible = false
		get_tree().root.set_mode(Window.MODE_FULLSCREEN)
	else:
		resDrop.visible = true
		get_tree().root.set_mode(Window.MODE_WINDOWED)


func _on_res_drop_item_selected(index):
	var size = Resolutions.get(resDrop.get_item_text(index))
	DisplayServer.window_set_size(size)
	titleRes._select_int(index)


func _on_fs_box_toggled(toggled_on): #Title screen fullscreen
	fsCheck.button_pressed = toggled_on
	if (toggled_on):
		resDrop.visible = false
		titleRes.visible = false
		get_tree().root.set_mode(Window.MODE_FULLSCREEN)
	else:
		titleRes.visible = true
		resDrop.visible = true
		get_tree().root.set_mode(Window.MODE_WINDOWED)


func _on_title_res_item_selected(index): #Title scren resolution
	var size = Resolutions.get(titleRes.get_item_text(index))
	DisplayServer.window_set_size(size)
	resDrop._select_int(index)


func _on_credits_btn_pressed():
	credPnl.visible = !credPnl.visible
	playBtn.visible = !credPnl.visible
