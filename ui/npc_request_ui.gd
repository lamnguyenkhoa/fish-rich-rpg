extends Control
class_name NPCRequestUI

const UI_FONT = preload("res://asset/font/AquinoDemo-511lj.ttf")

# A bigger fish charges more for their time. Index by npc tier.
const TIER_COST_MULTIPLIER := [1.0, 1.0, 2.5, 6.0]

# Flat amount a fish of each tier takes off you when they win a scrap.
const TIER_TAUNT_LOOT := [80, 80, 250, 900]

# Every request is paid work - real service, real time. Handing money over for
# nothing is not allowed, so nothing here is a gift.
# stat_index: 0 FOR, 1 INT, 2 STR, 3 HAR, 4 YEE. -1 means no stat gain.
const REQUESTS := [
	{
		"name": "Sing me a song",
		"desc": "Busking rates. A shanty picks you right up. Recover 15 stamina.",
		"cost": 25, "time": 2.0, "hp": 0, "sp": 15, "stat_index": - 1,
		"result": "{0} belts out a shanty about a shrimp who owed money. You feel oddly refreshed.",
	},
	{
		"name": "Cook me a meal",
		"desc": "Home cooking, cheaper than any restaurant. Recover 15 health.",
		"cost": 45, "time": 4.0, "hp": 15, "sp": 0, "stat_index": - 1,
		"result": "{0} fries something unidentifiable in far too much butter. It was excellent.",
	},
	{
		"name": "Swim laps with me",
		"desc": "A pacer for the morning current. +1 YEE, costs 10 stamina.",
		"cost": 60, "time": 6.0, "hp": 0, "sp": - 10, "stat_index": 4,
		"result": "{0} sets a brutal pace along the reef wall. You kept up. Mostly.",
	},
	{
		"name": "Spar with me",
		"desc": "A beating, but with rules and a coach. +1 STR, costs 8 health.",
		"cost": 90, "time": 8.0, "hp": - 8, "sp": 0, "stat_index": 2,
		"result": "{0} throws you around the training reef for an hour. Your fins ache, but you are stronger.",
	},
	{
		"name": "Tutor me",
		"desc": "Private lessons, undercutting the university. +1 INT.",
		"cost": 130, "time": 10.0, "hp": 0, "sp": 0, "stat_index": 1,
		"result": "{0} explains the tide charts twice, slowly. You understood most of it.",
	},
	{
		"name": "Introduce me around",
		"desc": "An afternoon of local connections. +1 HAR.",
		"cost": 160, "time": 8.0, "hp": 0, "sp": 0, "stat_index": 3,
		"result": "{0} walks you through the district nodding at everyone. You look connected now.",
	},
	{
		"name": "Haul my cargo",
		"desc": "A day of honest heavy lifting alongside them. +1 FOR.",
		"cost": 200, "time": 12.0, "hp": 0, "sp": - 15, "stat_index": 0,
		"result": "{0} works you like a dock hand until sundown. You are tougher for it.",
	},
]

const STAT_NAMES := ["FOR", "INT", "STR", "HAR", "YEE"]

@onready var npc_name_label: Label = $NPCName
@onready var tab_container: TabContainer = $TabContainer

# Normal
@onready var player_stat_label: Label = $TabContainer/Normal/PlayerStat
@onready var enemy_stat_label: Label = $TabContainer/Normal/EnemyStat
@onready var info_label: RichTextLabel = $TabContainer/Normal/InfoBG/InfoLabel
@onready var taunt_button: Button = $TabContainer/Normal/HBoxContainer/TauntButton
@onready var request_button: Button = $TabContainer/Normal/HBoxContainer/RequestButton

# Taunt
@onready var taunt_log: RichTextLabel = $TabContainer/Taunt/TauntLogArea/TauntLog
@onready var player_hp_bar: TextureProgressBar = $TabContainer/Taunt/PlayerHPBar
@onready var player_hp_label: Label = $TabContainer/Taunt/PlayerHPBar/Label
@onready var player_sp_bar: TextureProgressBar = $TabContainer/Taunt/PlayerSPBar
@onready var player_sp_label: Label = $TabContainer/Taunt/PlayerSPBar/Label
@onready var taunt_again_button: Button = $TabContainer/Taunt/TauntActions/TauntAgainButton

# Request
@onready var request_list: VBoxContainer = $TabContainer/Request/RequestScroll/RequestList
@onready var request_result: RichTextLabel = $TabContainer/Request/ResultBG/RequestResult

var target_npc: NPCFish

func _ready():
	visible = false
	build_request_list()

func open_ui(_target_npc: NPCFish):
	var player = GameManager.player
	player.is_busy = true
	visible = true
	tab_container.current_tab = 0
	target_npc = _target_npc
	npc_name_label.text = target_npc.fish_name
	if target_npc.is_hostile:
		npc_name_label.self_modulate = Color.RED
	else:
		npc_name_label.self_modulate = Color.GREEN
	player_stat_label.text = format_stats([player.for_stat, player.int_stat, player.str_stat,
		player.har_stat, player.yee_stat])
	enemy_stat_label.text = format_stats(target_npc.stats)
	taunt_log.text = ""
	request_result.text = ""
	refresh_normal_tab()
	refresh_request_list()

func close_ui():
	visible = false
	GameManager.player.is_busy = false

func format_stats(stats: Array) -> String:
	var lines: PackedStringArray = []
	for i in range(STAT_NAMES.size()):
		lines.append("{0}: {1}".format([STAT_NAMES[i], stats[i]]))
	return "\n".join(lines)

func tier_multiplier() -> float:
	if target_npc.tier < TIER_COST_MULTIPLIER.size():
		return TIER_COST_MULTIPLIER[target_npc.tier]
	return TIER_COST_MULTIPLIER[-1]

func tier_taunt_loot() -> int:
	if target_npc.tier < TIER_TAUNT_LOOT.size():
		return TIER_TAUNT_LOOT[target_npc.tier]
	return TIER_TAUNT_LOOT[-1]

# - - - Normal tab - - -

func refresh_normal_tab():
	info_label.text = "[center]{0} is a [color=yellow]tier {1}[/color] fish.\nChance they take your bait: [color=yellow]{2}%[/color]\nThey would take [color=yellow]{3}$[/color] off you.[/center]".format(
		[target_npc.fish_name, target_npc.tier, taunt_chance(),
		GameManager.game_ui._format_money(taunt_loot())])
	# A dead fish neither fights you nor runs errands.
	var is_available = not target_npc.dead
	taunt_button.disabled = not is_available
	request_button.disabled = not is_available

func _on_taunt_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	taunt_log.text = ""
	update_statbar()
	update_taunt_button()
	tab_container.current_tab = 1

func _on_request_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	request_result.text = ""
	refresh_request_list()
	tab_container.current_tab = 2

func _on_leave_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	close_ui()

# - - - Taunt tab - - -

func taunt_chance() -> int:
	# Bigger fish are quicker to swing. A strong player is nobody's easy mark,
	# and every taunt so far has already put them more on edge.
	var chance = 45 + target_npc.tier * 15 + target_npc.taunt_count * 10 - GameManager.player.str_stat
	return clampi(chance, 5, 95)

func taunt_loot() -> float:
	# A flat mugging, not a percentage - they empty your wallet, not your bank.
	# They get bolder each time they get away with it.
	return snappedf(tier_taunt_loot() * (1.0 + 0.5 * target_npc.taunt_count), 0.01)

func taunt_damage() -> int:
	return int(target_npc.stats[2] * (1.0 + 0.25 * target_npc.taunt_count))

func _on_taunt_again_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	var player = GameManager.player
	GameManager.pass_time(2.0)
	if randi() % 100 >= taunt_chance():
		taunt_log.text += "You insult {0}'s mother. They just [color=gray]laugh at you[/color].\n- - -\n".format(
			[target_npc.fish_name])
		update_taunt_button()
		return

	var stolen = minf(taunt_loot(), player.money)
	var damage = taunt_damage()
	player.damaged("hp", damage)
	player.money -= stolen
	target_npc.taunt_count += 1
	taunt_log.text += "{0} beats you up for [color=yellow]{1}[/color] damage.\n".format(
		[target_npc.fish_name, damage])
	if stolen > 0:
		taunt_log.text += "They rifle through your pockets and take [color=green]{0}$[/color]!\n".format(
			[GameManager.game_ui._format_money(stolen)])
	else:
		taunt_log.text += "They find [color=gray]nothing[/color] worth taking.\n"
	if player.current_hp <= 0:
		# Never actually knock the player out - they still have money to burn.
		player.current_hp = 1
		taunt_log.text += "[color=red]You can barely swim. Get to a hospital.[/color]\n"
	taunt_log.text += "- - -\n"
	update_statbar()
	update_taunt_button()

func update_taunt_button():
	taunt_again_button.text = "Taunt ({0}%)".format([taunt_chance()])
	taunt_again_button.disabled = target_npc.dead

func update_statbar():
	var player = GameManager.player
	player_hp_bar.value = (player.current_hp / float(player.max_hp)) * 100
	player_hp_label.text = "{0} / {1}".format([player.current_hp, player.max_hp])
	player_sp_bar.value = (player.current_sp / float(player.max_sp)) * 100
	player_sp_label.text = "{0} / {1}".format([player.current_sp, player.max_sp])

func _on_taunt_back_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	refresh_normal_tab()
	tab_container.current_tab = 0

# - - - Request tab - - -

func build_request_list():
	for i in range(REQUESTS.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var button := Button.new()
		button.name = "RequestButton%d" % i
		button.custom_minimum_size = Vector2(300, 0)
		button.add_theme_font_override("font", UI_FONT)
		button.text = REQUESTS[i]["name"]
		button.clip_text = true
		button.pressed.connect(_on_request_pressed.bind(i))
		button.mouse_entered.connect(SoundManager.play_button_hover_sfx)
		var label := Label.new()
		label.name = "Desc"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 20)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(button)
		row.add_child(label)
		request_list.add_child(row)

func request_cost(index: int) -> float:
	# Every favour asked nudges the price up - they know you are good for it.
	var base = REQUESTS[index]["cost"] * tier_multiplier()
	return snappedf(base * (1.0 + 0.15 * target_npc.request_count), 0.01)

func refresh_request_list():
	for i in range(REQUESTS.size()):
		var request = REQUESTS[i]
		var row := request_list.get_child(i)
		var button: Button = row.get_node("RequestButton%d" % i)
		var label: Label = row.get_node("Desc")
		var cost = request_cost(i)
		var prefix = "{0}$".format([GameManager.game_ui._format_money(cost)])
		if request["time"] > 0:
			prefix += ", {0}s".format([request["time"]])
		label.text = "{0} - {1}".format([prefix, request["desc"]])
		button.disabled = (GameManager.player.money < cost
			or GameManager.time_left < request["time"]
			or target_npc.dead)

func _on_request_pressed(index: int):
	SoundManager.play_button_click_sfx()
	var request = REQUESTS[index]
	var cost = request_cost(index)
	var player = GameManager.player
	if player.money < cost or GameManager.time_left < request["time"]:
		return

	player.money -= cost
	target_npc.request_count += 1
	if request["time"] > 0:
		GameManager.pass_time(request["time"])
	if request["hp"] > 0:
		player.recover("hp", request["hp"])
	elif request["hp"] < 0:
		player.damaged("hp", -request["hp"])
		player.current_hp = maxi(player.current_hp, 1)
	if request["sp"] > 0:
		player.recover("sp", request["sp"])
	elif request["sp"] < 0:
		player.damaged("sp", -request["sp"])

	request_result.text = "[center]{0}\n[color=red]-{1}$[/color]".format(
		[request["result"].format([target_npc.fish_name]), GameManager.game_ui._format_money(cost)])
	var stat_index: int = request["stat_index"]
	if stat_index >= 0:
		apply_stat_gain(stat_index)
		request_result.text += " [color=green]+1 {0}[/color]".format([STAT_NAMES[stat_index]])
	request_result.text += "[/center]"
	refresh_request_list()

func apply_stat_gain(stat_index: int):
	var player = GameManager.player
	match stat_index:
		0: player.for_stat += 1
		1: player.int_stat += 1
		2: player.str_stat += 1
		3: player.har_stat += 1
		4: player.yee_stat += 1

func _on_request_back_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	refresh_normal_tab()
	tab_container.current_tab = 0

func _on_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()
