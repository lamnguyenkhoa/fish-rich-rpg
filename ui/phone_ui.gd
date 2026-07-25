extends Control
class_name PhoneUI

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var mermaid_connect_ui: PhoneAppUI = $PhonePortrait/MermaidConnectUI

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


func _on_phone_app_app_opened(app_name: String) -> void:
	anim_player.play("rotate_phone")
	await anim_player.animation_finished
	match (app_name):
		"Mermaid Connect":
			mermaid_connect_ui.open_app_ui()


func _on_mermaid_connect_ui_app_closed() -> void:
	anim_player.play_backwards("rotate_phone")
