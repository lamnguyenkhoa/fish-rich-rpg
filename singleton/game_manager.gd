extends Node

var debt_money = 1000000
var interest_rate = 1.05
var day_left = 20
var current_time = 0 # from 0 to 8, 8 unit of time
var item_database_dict: Dictionary = {}
var debt_paid = false

var player: Player
var player_menu: PlayerMenu
var game_ui: GameUI
var map_manager: MapManager

signal time_passed
signal inventory_changed
signal day_passed

func _ready():
	SoundManager.set_master_volume(1)
	SoundManager.set_music_volume(0.8)
	SoundManager.set_sound_volume(0.8)
	load_item_database()

func get_time_left():
	return 8 - current_time

func pass_time(time: int):
	current_time = clampi(current_time + time, 0, 8)
	emit_signal("time_passed")

func move_to_next_day(amount: int=1):
	day_left -= amount
	current_time = 0
	emit_signal("time_passed")
	emit_signal("day_passed")
	close_all_windows()
	GameManager.game_ui.play_day_transition()
	if day_left <= 0 and not debt_paid:
		end_game(false)

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

func force_go_home_and_rest():
	close_all_windows()
	var respawn_pos = map_manager.player_apartment.get_node("RespawnSpot").global_position
	player.global_position = respawn_pos
	move_to_next_day(2)
	if day_left > 0:
		player.recover("hp", 100, true)
		player.recover("sp", 100, true)
		GameManager.game_ui.notification_ui.notify_injured()

func prison_smuggle():
	var random_num = randi() % 100
	if random_num < 25:
		sent_to_prison()
	else:
		player.money += 5000

func sent_to_prison():
	close_all_windows()
	var respawn_pos = map_manager.prison.get_node("RespawnSpot").global_position
	player.global_position = respawn_pos
	move_to_next_day(3)
	if day_left > 0:
		player.recover("hp", 100, true)
		player.recover("sp", 100, true)
		player.money -= int(player.money * 0.2)
		GameManager.game_ui.notification_ui.notify_caught()

func paid_the_debt():
	debt_paid = true
	end_game(true)

func end_game(is_win):
	close_all_windows()
	if is_win:
		map_manager.endgame_ui.open_win_screen()
	else:
		# Automatically pay if enough money, last chance
		if not debt_paid and player.money >= debt_money:
			player.money -= debt_money
			debt_paid = true
			map_manager.endgame_ui.open_win_screen()
			return
		map_manager.endgame_ui.open_lose_screen()
	GameManager.player.is_busy = true

func close_all_windows():
	player_menu.close_menu()
	for child: CompanyWork in map_manager.work_ui.get_children():
		child.close_ui()
	game_ui.notification_ui.close_ui()
	game_ui.npc_interact_ui.close_ui()

func reset():
	debt_money = 1000000
	interest_rate = 1.05
	day_left = 20
	current_time = 0
	debt_paid = false
