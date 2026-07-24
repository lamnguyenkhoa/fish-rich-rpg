extends Control
class_name PlayerMenu

@onready var tab_container: TabContainer = $TabContainer
@onready var inventory_menu: InventoryMenu = $TabContainer/Inventory

var player: Player = null

func _ready():
	GameManager.player_menu = self
	close_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	player = GameManager.player
	inventory_menu.init()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_player_menu") and not player.is_busy and not GameManager.phone_ui.visible:
		toggle_menu()


func toggle_menu():
	if visible:
		close_menu()
	else:
		open_menu()

func open_menu():
	visible = true
	inventory_menu.refresh_stat()
	inventory_menu.refresh_inventory_data()
	SoundManager.play_button_click_sfx()

func close_menu():
	visible = false

func _on_close_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	close_menu()

func _on_tab_container_tab_hovered(_tab: int) -> void:
	SoundManager.play_button_hover_sfx()

func _on_tab_container_tab_clicked(_tab: int) -> void:
	SoundManager.play_button_click_sfx()

func _on_close_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()
