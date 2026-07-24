extends Node

var time_left: float = 300.0
var time_is_passing = false
var time_speed = 1.0
var item_database_dict: Dictionary = {}

var player: Player
var player_menu: PlayerMenu
var game_ui: GameUI
var map_manager: MapManager

signal time_passed
signal inventory_changed

func _ready():
	SoundManager.set_master_volume(1)
	SoundManager.set_music_volume(0.8)
	SoundManager.set_sound_volume(0.8)
	load_item_database()

func _process(delta: float) -> void:
	if time_is_passing:
		time_left -= delta * time_speed

func start_time():
	time_is_passing = true

func stop_time():
	time_is_passing = false

func change_time_speed():
	pass

	
func load_item_database():
	var directory_path = "res://item/"

	# Get a list of files in the directory
	var dir = DirAccess.open(directory_path)

	# Loop through each file in the directory
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		file_name = file_name.replace('.import', '')
		file_name = file_name.replace('.remap', '')
		if file_name.ends_with(".tres"):
			# Load each resource file using ResourceLoader
			var resource_path = directory_path + file_name
			var resource = ResourceLoader.load(resource_path) as ItemResource
			if resource != null:
				# Do something with the loaded resource, e.g., add it to the scene
				# item_database.append(resource)
				item_database_dict[resource.item_id] = resource
			else:
				print("Failed to load resource:", resource_path)

		# Get the next file in the directory
		file_name = dir.get_next()
	dir.list_dir_end()

func open_npc_interact_ui(target_npc: NPCFish):
	game_ui.npc_interact_ui.open_ui(target_npc)

func pass_time(time: float):
	time_left = clamp(time_left - time, 0, time_left)
	time_passed.emit()

func end_game(is_win):
	close_all_windows()
	if is_win:
		map_manager.endgame_ui.open_win_screen()
	else:
		map_manager.endgame_ui.open_lose_screen()
	GameManager.player.is_busy = true

func close_all_windows():
	player_menu.close_menu()
	for child: CompanyWork in map_manager.work_ui.get_children():
		child.close_ui()
	game_ui.notification_ui.close_ui()
	game_ui.npc_interact_ui.close_ui()

func reset():
	player.money = 1000000
	time_left = 300.0
