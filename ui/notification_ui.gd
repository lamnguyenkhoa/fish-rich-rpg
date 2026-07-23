extends Control
class_name NotificationUI

@onready var title: Label = $Title
@onready var desc: Label = $Desc

func _ready() -> void:
	visible = false

func close_ui():
	visible = false

func notify_injured():
	visible = true
	title.text = "You was heavily injured"
	desc.text = "You have to stay at home for 2 days to recover"

func notify_caught():
	visible = true
	title.text = "You was caught commit crime"
	desc.text = "You have to stay in prison for 3 days and lost 20% of your money"

func _on_close_button_pressed() -> void:
	visible = false
	SoundManager.play_button_click_sfx()

func _on_close_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()
