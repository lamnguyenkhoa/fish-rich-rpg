extends Control
class_name EndgameUI

@onready var tab_container: TabContainer = $TabContainer

func _ready() -> void:
	visible = false

func open_win_screen():
	tab_container.current_tab = 0
	visible = true

func open_lose_screen():
	tab_container.current_tab = 1
	visible = true

func _on_back_menu_button_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
	SoundManager.play_button_click_sfx()

func _on_continue_button_pressed() -> void:
	visible = false
	GameManager.player.is_busy = false
	SoundManager.play_button_click_sfx()

func _on_back_menu_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()

func _on_continue_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()
