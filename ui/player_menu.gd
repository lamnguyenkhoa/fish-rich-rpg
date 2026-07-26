extends Control
class_name PlayerMenu

@onready var tab_container: TabContainer = $TabContainer
@onready var inventory_menu: InventoryMenu = $TabContainer/Inventory
@onready var retry_button: Button = $RetryButton

var player: Player = null
var press_retry_once = false

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
	press_retry_once = false
	retry_button.text = "Retry"

func close_menu():
	press_retry_once = false
	retry_button.text = "Retry"
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


func _on_retry_button_pressed() -> void:
	if press_retry_once:
		GameManager.reset()
		get_tree().reload_current_scene()
	else:
		press_retry_once = true
		retry_button.text = "Sure?"
