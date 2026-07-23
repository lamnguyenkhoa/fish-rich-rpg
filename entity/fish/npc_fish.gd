@tool
extends Interactable
class_name NPCFish

@export var fish_name: String
@export var tier: int = 1
@export var is_hostile: bool
@export var flip_sprite: bool
@export var max_hp: int
@export var stats: Array[int] = [0, 0, 0, 0, 0]
@export var defeat_loot: Array[EnumAutoload.ItemId]
@export var possible_steal_loot: Array[EnumAutoload.ItemId]

@onready var name_label: Label = $NameLabel
@onready var fish_sprite: Sprite2D = $Fish

var current_hp: int
var dead = false
var defeat_money: int
var steal_awareness = 0

func _ready() -> void:
	if flip_sprite:
		fish_sprite.scale.x = -fish_sprite.scale.x
	if not Engine.is_editor_hint():
		current_hp = max_hp
		name_label.text = fish_name
		randomly_set_defeat_money()
		GameManager.day_passed.connect(revive)

func interact(_player: Player):
	GameManager.open_npc_interact_ui(self)

func get_interact_text(_player: Player) -> String:
	return "Interact with {0}".format([fish_name])

func damaged(value: int, is_percentage_max: bool=false):
	if is_percentage_max:
		current_hp = clamp(current_hp - (max_hp * (value / 100.0)), 0, max_hp)
	else:
		current_hp = clamp(current_hp - value, 0, max_hp)
	if current_hp <= 0:
		death()

func death():
	GameManager.player.money += defeat_money
	for item_id in defeat_loot:
		GameManager.player.acquired_item(item_id, 1)
	dead = true
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func revive():
	steal_awareness = 0
	randomly_set_defeat_money()
	current_hp = max_hp
	dead = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT

func calculate_steal_success_chance() -> int:
	# By default, steal chance is equal to HAR plus 50
	var steal_chance = 50 + GameManager.player.har_stat
	# For each tier beyond 1, steal chance reduced by 10
	steal_chance -= (tier - 1) * 10
	# For each count of steal awareness, steal chance reduce by 15
	steal_chance -= steal_awareness * 15
	steal_chance = clampi(steal_chance, 0, 100)
	return steal_chance

func steal_money() -> int:
	# You steal half of their current money
	var steal_amount = int(defeat_money * 0.5)
	defeat_money = clampi(defeat_money - steal_amount, 0, 99999999)
	GameManager.player.money += steal_amount
	return steal_amount

func roll_steal_loot() -> EnumAutoload.ItemId:
	if len(possible_steal_loot) == 0:
		return EnumAutoload.ItemId.NONE
	var random_index = randi() % len(possible_steal_loot)
	var random_item = possible_steal_loot[random_index]
	return random_item

func randomly_set_defeat_money():
	match tier:
		1:
			defeat_money = randi_range(300, 1000)
		2:
			defeat_money = randi_range(5000, 20000)
		3:
			defeat_money = randi_range(50000, 90000)
		_:
			defeat_money = randi_range(100, 500)