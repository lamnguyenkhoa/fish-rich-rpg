extends Control
class_name NPCInteractUI

@onready var npc_name_label: Label = $NPCName
@onready var tab_container: TabContainer = $TabContainer

# Normal
@onready var player_stat_label: Label = $TabContainer/Normal/PlayerStat
@onready var enemy_stat_label: Label = $TabContainer/Normal/EnemyStat

# Steal stuff
@onready var steal_label: RichTextLabel = $TabContainer/Normal/StealLabelBG/StealLabel
@onready var steal_button: Button = $TabContainer/Normal/HBoxContainer/StealButton

# Fight stuff
@onready var fight_button: Button = $TabContainer/Normal/HBoxContainer/FightButton
@onready var combat_log: RichTextLabel = $TabContainer/Fight/BattleLogArea/BattleLog
@onready var player_hp_bar: TextureProgressBar = $TabContainer/Fight/PlayerHPBar
@onready var player_hp_label: Label = $TabContainer/Fight/PlayerHPBar/Label
@onready var player_sp_bar: TextureProgressBar = $TabContainer/Fight/PlayerSPBar
@onready var player_sp_label: Label = $TabContainer/Fight/PlayerSPBar/Label
@onready var enemy_hp_bar: TextureProgressBar = $TabContainer/Fight/EnemyHPBar
@onready var enemy_hp_label: Label = $TabContainer/Fight/EnemyHPBar/Label
@onready var attack_button: Button = $TabContainer/Fight/PlayerActions/AttackButton
@onready var special_button: Button = $TabContainer/Fight/PlayerActions/SpecialButton
@onready var defend_button: Button = $TabContainer/Fight/PlayerActions/DefendButton
@onready var escape_button: Button = $TabContainer/Fight/PlayerActions/EscapeButton
@onready var leave_button: Button = $TabContainer/Fight/LeaveButton

var target_npc: NPCFish

func _ready():
	visible = false

func open_ui(_target_npc: NPCFish):
	var player = GameManager.player
	player.is_busy = true
	visible = true
	tab_container.current_tab = 0
	target_npc = _target_npc
	npc_name_label.text = target_npc.fish_name
	if target_npc.is_hostile:
		npc_name_label.self_modulate = Color.RED
		steal_button.disabled = true
		fight_button.disabled = false
		steal_label.text = ""
	else:
		npc_name_label.self_modulate = Color.GREEN
		fight_button.disabled = true
		steal_button.disabled = false
		steal_label.text = "[center]Steal chance: [color=yellow]{0}%[/color][/center]".format([target_npc.calculate_steal_success_chance()])
	player_stat_label.text = "FOR: {0}\nINT: {1}\nSTR: {2}\nHAR: {3}\nYEE: {4}".format(
		[player.for_stat, player.int_stat, player.str_stat, player.har_stat, player.yee_stat])
	enemy_stat_label.text = "FOR: {0}\nINT: {1}\nSTR: {2}\nHAR: {3}\nYEE: {4}".format(target_npc.stats)

func close_ui():
	visible = false
	GameManager.player.is_busy = false

func _on_fight_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	check_for_special_attack_eligible()
	attack_button.visible = true
	special_button.visible = true
	defend_button.visible = true
	escape_button.visible = true
	leave_button.visible = false
	combat_log.text = ""
	update_statbar()
	tab_container.current_tab = 1

func _on_attack_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	var damage = GameManager.player.str_stat
	target_npc.damaged(GameManager.player.str_stat)
	combat_log.text += "You attacked the [color=red]enemy[/color] for [color=yellow]{0}[/color] damage\n".format([damage])
	if target_npc.current_hp <= 0:
		win_combat()
		return
	enemy_attack()

func _on_special_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	var damage = GameManager.player.str_stat * 2
	target_npc.damaged(damage)
	GameManager.player.damaged("sp", 20)
	check_for_special_attack_eligible()
	combat_log.text += "You use special attack on the [color=red]enemy[/color] for [color=yellow]{0}[/color] damage\n".format([damage])
	if target_npc.current_hp <= 0:
		win_combat()
		return
	enemy_attack()

func _on_defend_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	GameManager.player.recover("sp", 10, true)
	check_for_special_attack_eligible()
	combat_log.text += "You braced for defend. Reduce damage taken by 50% and recover 10% stamina\n"
	if target_npc.current_hp <= 0:
		win_combat()
		return
	enemy_attack(0.5)
	
func _on_escape_button_pressed() -> void:
	close_ui()
	SoundManager.play_button_click_sfx()

func update_statbar():
	player_hp_bar.value = (GameManager.player.current_hp / float(GameManager.player.max_hp)) * 100
	player_hp_label.text = "{0} / {1}".format([GameManager.player.current_hp, GameManager.player.max_hp])
	player_sp_bar.value = (GameManager.player.current_sp / float(GameManager.player.max_sp)) * 100
	player_sp_label.text = "{0} / {1}".format([GameManager.player.current_sp, GameManager.player.max_sp])
	enemy_hp_bar.value = (target_npc.current_hp / float(target_npc.max_hp)) * 100
	enemy_hp_label.text = "{0} / {1}".format([target_npc.current_hp, target_npc.max_hp])

func enemy_attack(damage_modifier: float=1.0):
	var damage = int(target_npc.stats[2] * damage_modifier)
	GameManager.player.damaged("hp", damage)
	combat_log.text += "The [color=red]enemy[/color] attacked you for [color=yellow]{0}[/color] damage\n".format([damage])
	update_statbar()
	combat_log.text += '- - -\n'
	if GameManager.player.current_hp <= 0:
		lost_combat()

func win_combat():
	combat_log.text += "[color=green]The enemy is defeated. You won![/color]\n"
	if target_npc.defeat_money > 0:
		combat_log.text += "Received [color=green]{0}$[/color]!\n".format([target_npc.defeat_money])
	if len(target_npc.defeat_loot) > 0:
		for loot in target_npc.defeat_loot:
			combat_log.text += "Received [color=green]{0}[/color]!\n".format([GameManager.item_database_dict[loot].name])
	update_statbar()
	attack_button.visible = false
	special_button.visible = false
	defend_button.visible = false
	escape_button.visible = false
	leave_button.text = "Leave"
	leave_button.visible = true

func lost_combat():
	combat_log.text += "[color=red]The enemy has defeated you! You lost![/color]\n"
	update_statbar()
	attack_button.visible = false
	special_button.visible = false
	defend_button.visible = false
	escape_button.visible = false
	leave_button.text = "Go home and rest"
	leave_button.visible = true

func attempt_to_steal():
	var random_num = randi() % 100
	var steal_chance = target_npc.calculate_steal_success_chance()
	if random_num < steal_chance:
		target_npc.steal_awareness += 1
		var stolen_item = target_npc.roll_steal_loot()
		var stolen_money = target_npc.steal_money()
		if stolen_item != EnumAutoload.ItemId.NONE:
			steal_label.text = "[center]Steal chance: [color=yellow]{0}%[/color]\nReceived [color=green]{1}$[/color]\nReceived [color=green]{2}[/color][/center]".format(
				[target_npc.calculate_steal_success_chance(), int(stolen_money), GameManager.item_database_dict[stolen_item].name])
			GameManager.player.acquired_item(stolen_item, 1)
		else:
			steal_label.text = "[center]Steal chance: [color=yellow]{0}%[/color]\nReceived [color=green]{1}$[/color][/center]".format(
				[target_npc.calculate_steal_success_chance(), int(stolen_money)])
	else:
		GameManager.sent_to_prison()

func check_for_special_attack_eligible():
	# Current it cost 20 SP to special attack
	if GameManager.player.current_sp < 20:
		special_button.disabled = true
	else:
		special_button.disabled = false

func _on_leave_button_pressed() -> void:
	close_ui()
	SoundManager.play_button_click_sfx()
	if GameManager.player.current_hp <= 0:
		GameManager.force_go_home_and_rest()

func _on_steal_button_pressed() -> void:
	attempt_to_steal()

func _on_leave_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()

func _on_fight_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()

func _on_steal_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()
