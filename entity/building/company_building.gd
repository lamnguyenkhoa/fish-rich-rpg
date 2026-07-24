extends Interactable
class_name CompanyBuilding

@export var interact_text: String
@export var open_interior_ui: BuildingInterior

func interact(_player: Player):
	SoundManager.play_button_click_sfx()
	open_interior_ui.open_ui()
	GameManager.player.is_busy = true
	GameManager.player_menu.close_menu()

func get_interact_text(_player: Player) -> String:
	return interact_text
