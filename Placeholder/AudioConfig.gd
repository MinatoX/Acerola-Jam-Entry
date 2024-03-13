extends Panel

var bgmBus = AudioServer.get_bus_index("BGM")
var sfxBus = AudioServer.get_bus_index("SE")
var masterBus = AudioServer.get_bus_index("Master")

@onready var bgmSlider:HSlider = $ambSlider
@onready var sfxSlider:HSlider = $sfxSlider
@onready var masterSlider:HSlider = $masterSlider


# Called when the node enters the scene tree for the first time.
func _ready():
	bgmSlider.value = db_to_linear(AudioServer.get_bus_volume_db(bgmBus))
	sfxSlider.value = db_to_linear(AudioServer.get_bus_volume_db(sfxBus))
	masterSlider.value = db_to_linear(AudioServer.get_bus_volume_db(masterBus))


func _on_amb_slider_value_changed(value):
	AudioServer.set_bus_volume_db(bgmBus, linear_to_db(value))


func _on_master_slider_value_changed(value):
	AudioServer.set_bus_volume_db(masterBus, linear_to_db(value))


func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(sfxBus, linear_to_db(value))
