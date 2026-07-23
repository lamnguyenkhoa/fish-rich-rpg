extends Node2D

@export var main_game_scene: PackedScene

@onready var intro_cutscene: TabContainer = $CanvasLayer/IntroCutscene

var max_tabs = 0

func _ready():
	max_tabs = intro_cutscene.get_tab_count() - 1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and intro_cutscene.visible:
		SoundManager.play_button_click_sfx()
		if intro_cutscene.current_tab < max_tabs:
			intro_cutscene.current_tab += 1
		else:
			get_tree().change_scene_to_packed(main_game_scene)

func _on_play_button_pressed() -> void:
	intro_cutscene.visible = true
	SoundManager.play_button_click_sfx()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	SoundManager.play_button_click_sfx()

func _on_continue_button_pressed() -> void:
	SoundManager.play_button_click_sfx()

func play_ui_hover_sound() -> void:
	SoundManager.play_button_hover_sfx()
