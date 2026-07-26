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

# How long a fish swims off for after a job or a scrap, by tier. Bigger fish
# have better places to be.
const TIER_AWAY_DURATION := [15.0, 15.0, 30.0, 60.0]

@onready var name_label: Label = $NameLabel
@onready var fish_sprite: Sprite2D = $Fish

var current_hp: int
var dead = false
var defeat_money: int
var steal_awareness = 0
var taunt_count = 0
var request_count = 0
var is_away = false
var return_at_time_left: float = 0.0

# Interactable is a Node2D, but every fish scene roots at a physics body, so the
# collision layer is fetched dynamically to switch interaction on and off.
var _base_collision_layer: int = 1

func _ready() -> void:
	if flip_sprite:
		fish_sprite.scale.x = - fish_sprite.scale.x
	if not Engine.is_editor_hint():
		current_hp = max_hp
		name_label.text = fish_name
		if "collision_layer" in self:
			_base_collision_layer = get("collision_layer")
		randomly_set_defeat_money()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_away:
		return
	# time_left counts down, so they are back once it drops past the mark.
	if GameManager.time_left <= return_at_time_left:
		come_back()

func interact(_player: Player):
	if dead or is_away:
		return
	GameManager.open_npc_request_ui(self)

func away_duration() -> float:
	if tier < TIER_AWAY_DURATION.size():
		return TIER_AWAY_DURATION[tier]
	return TIER_AWAY_DURATION[-1]

func leave_for_a_while():
	is_away = true
	return_at_time_left = GameManager.time_left - away_duration()
	visible = false
	set_deferred("collision_layer", 0)

func come_back():
	is_away = false
	visible = true
	set_deferred("collision_layer", _base_collision_layer)

func get_interact_text(_player: Player) -> String:
	return "Interact with {0}".format([fish_name])

func damaged(value: int, is_percentage_max: bool = false):
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
	taunt_count = 0
	request_count = 0
	randomly_set_defeat_money()
	current_hp = max_hp
	dead = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	come_back()

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