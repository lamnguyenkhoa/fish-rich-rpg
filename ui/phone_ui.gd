extends Control
class_name PhoneUI

func _ready() -> void:
	GameManager.phone_ui = self


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("open_player_menu"):
		close_phone()
		get_viewport().set_input_as_handled()


func open_phone():
	visible = true

func close_phone():
	visible = false

func _on_close_button_pressed() -> void:
	close_phone()
