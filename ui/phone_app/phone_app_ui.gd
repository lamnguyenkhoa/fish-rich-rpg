extends Control
class_name PhoneAppUI

@export var draw_one_cost: float = 2.99
@export var draw_ten_cost: float = 29.9
@export var draw_one_button: Button
@export var draw_ten_button: Button
@export var gacha_result_container: Container
@export var gacha_result_prefab: PackedScene
@export var collection_info_label: RichTextLabel

@onready var tab_container: TabContainer = $TabContainer

var unit_pulled_count = [0, 0, 0, 0, 0]

signal app_closed

func _ready():
	draw_one_button.text = "Draw 1\n(${0})".format([draw_one_cost])
	draw_ten_button.text = "Draw 10\n(${0})".format([draw_ten_cost])

func open_app_ui():
	tab_container.current_tab = 0
	visible = true

func close_app_ui():
	visible = false
	app_closed.emit()

func update_collection_label():
	collection_info_label.text = ("[color=silver]1 star:[/color] {0}\n[color=gold]2 stars:[/color] {1}" + \
		"\n[rainbow]3 stars:[/rainbow] {2}").format([unit_pulled_count[0], unit_pulled_count[1], unit_pulled_count[2]])

func _on_start_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	tab_container.current_tab = 1


func _on_play_button_pressed() -> void:
	SoundManager.play_button_click_sfx()


func _on_gacha_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	tab_container.current_tab = 2


func _on_draw_one_pressed() -> void:
	if GameManager.player.money < draw_one_cost:
		return
	SoundManager.play_button_click_sfx()
	GameManager.player.money -= draw_one_cost
	clear_all_gacha_result()
	tab_container.current_tab = 3
	pull_gacha()
	update_collection_label()

func _on_draw_ten_pressed() -> void:
	if GameManager.player.money < draw_ten_cost:
		return
	SoundManager.play_button_click_sfx()
	GameManager.player.money -= draw_ten_cost
	clear_all_gacha_result()
	tab_container.current_tab = 3
	for i in range(10):
		pull_gacha()
		await get_tree().create_timer(0.03).timeout
	update_collection_label()


func pull_gacha():
	SoundManager.play_button_hover_sfx()
	var inst = gacha_result_prefab.instantiate()
	gacha_result_container.add_child(inst)
	unit_pulled_count[inst.rarity_index] += 1

func clear_all_gacha_result():
	for child in gacha_result_container.get_children():
		child.queue_free()


func _on_back_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	tab_container.current_tab -= 1


func _on_quit_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	close_app_ui()
