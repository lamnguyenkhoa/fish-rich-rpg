extends Control
class_name PhoneAppUI

@export var draw_one_cost: float = 2.99
@export var draw_ten_cost: float = 29.9
@export var draw_one_button: Button
@export var draw_ten_button: Button

@onready var tab_container: TabContainer = $TabContainer

func _ready():
	draw_one_button.text = "Draw 1\n(${0})".format([draw_one_cost])
	draw_ten_button.text = "Draw 10\n(${0})".format([draw_ten_cost])

func open_app_ui():
	tab_container.current_tab = 0
	visible = true

func close_app_ui():
	visible = false

func _on_start_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	tab_container.current_tab = 1


func _on_play_button_pressed() -> void:
	SoundManager.play_button_click_sfx()


func _on_gacha_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	tab_container.current_tab = 2


func _on_draw_one_pressed() -> void:
	SoundManager.play_button_click_sfx()
	GameManager.player.money -= draw_one_cost


func _on_draw_ten_pressed() -> void:
	SoundManager.play_button_click_sfx()
	GameManager.player.money -= draw_ten_cost
