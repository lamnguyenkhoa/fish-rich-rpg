extends CharacterBody2D
class_name Player

@onready var sprite: Sprite2D = $FishSprite
@onready var interact_label: Label = $InteractLabel
@onready var interact_area: Area2D = $InteractArea

const BASE_MOVESPEED = 200
const BASE_HEALTH = 50
const BASE_STAMINA = 50

signal money_changed
signal inventory_changed
signal stat_changed

var max_hp: int = BASE_HEALTH:
	set(value):
		max_hp = value
		player_menu.inventory_menu.update_health_bar(current_hp, value)
var max_sp: int = BASE_STAMINA:
	set(value):
		max_sp = value
		player_menu.inventory_menu.update_stamina_bar(current_sp, value)
var current_hp: int = BASE_HEALTH:
	set(value):
		current_hp = value
		player_menu.inventory_menu.update_health_bar(value, max_hp)
var current_sp: int = BASE_STAMINA:
	set(value):
		current_sp = value
		player_menu.inventory_menu.update_stamina_bar(value, max_sp)
var for_stat: int = 9: # Each point increase health and stamina by 5
	set(value):
		for_stat = value
		recalculate_stat()
var int_stat: int = 9:
	set(value):
		int_stat = value
		recalculate_stat()
var str_stat: int = 9:
	set(value):
		str_stat = value
		recalculate_stat()
var har_stat: int = 9:
	set(value):
		har_stat = value
		recalculate_stat()
var yee_stat: int = 9: # Each point increase movespeed by 2%
	set(value):
		yee_stat = value
		recalculate_stat()
var money: int = 100:
	set(value):
		if value < 0:
			value = 0
		money = value
		GameManager.game_ui.update_money_text(value)
		GameManager.player_menu.inventory_menu.refresh_stat()
		emit_signal("money_changed")

var player_menu: PlayerMenu = null
var direction: Vector2 = Vector2.ZERO
var things_in_range = []
var is_busy = false
var inventory: Dictionary = {}

func _ready() -> void:
	GameManager.player = self
	await get_tree().process_frame
	await get_tree().process_frame
	player_menu = GameManager.player_menu
	recalculate_stat()
	current_hp = max_hp
	current_sp = max_sp
	init_inventory()
	GameManager.game_ui.update_money_text(money)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_player_menu") and not is_busy:
		GameManager.player_menu.toggle_menu()

func _physics_process(_delta):
	# Clear previous items in range
	things_in_range.clear()
	# Check for nearby items
	var bodies = interact_area.get_overlapping_bodies()
	for body in bodies:
		if body is Interactable:
			things_in_range.append(body)
	if things_in_range.size() > 0:
		set_interact_label(things_in_range[0].get_interact_text(self))
	else:
		set_interact_label("")
	# Handle pickup input
	if Input.is_action_just_pressed("interact") and things_in_range.size() > 0 and not is_busy:
		# You can prioritize certain types of items or implement a way for the player to cycle through them
		things_in_range[0].interact(self) # For simplicity, picking up the first item in range
	# Movement
	direction = Vector2.ZERO
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not is_busy:
		velocity = direction * BASE_MOVESPEED * (1 + yee_stat / 50.0)
	else:
		velocity = Vector2.ZERO

	if velocity.x < 0:
		sprite.scale.x = 0.2
	if velocity.x > 0:
		sprite.scale.x = -0.2

	move_and_slide()

func recalculate_stat():
	max_hp = BASE_HEALTH + for_stat * 5
	max_sp = BASE_STAMINA + for_stat * 5
	emit_signal("stat_changed")

func damaged(type: String, value: int, is_percentage_max: bool=false):
	if type == "hp":
		if is_percentage_max:
			current_hp = clamp(current_hp - (max_hp * (value / 100.0)), 0, max_hp)
		else:
			current_hp = clamp(current_hp - value, 0, max_hp)
	else:
		if is_percentage_max:
			current_hp = clamp(current_sp - (max_sp * (value / 100.0)), 0, max_sp)
		else:
			current_sp = clamp(current_sp - value, 0, max_sp)

func recover(type: String, value: int, is_percentage_max: bool=false):
	if type == "hp":
		if is_percentage_max:
			current_hp = clamp(current_hp + (max_hp * (value / 100.0)), 0, max_hp)
		else:
			current_hp = clamp(current_hp + value, 0, max_hp)
	else:
		if is_percentage_max:
			current_sp = clamp(current_sp + (max_sp * (value / 100.0)), 0, max_sp)
		else:
			current_sp = clamp(current_sp + value, 0, max_sp)

func set_interact_label(text: String):
	if text != interact_label.text:
		interact_label.text = text

func acquired_item(item_id: EnumAutoload.ItemId, amount: int):
	inventory[item_id] += amount
	emit_signal("inventory_changed")

func lost_item(item_id: EnumAutoload.ItemId, amount: int):
	inventory[item_id] -= amount
	emit_signal("inventory_changed")

func init_inventory():
	for item_id in GameManager.item_database_dict.keys():
		inventory[item_id] = 0
	inventory[EnumAutoload.ItemId.FRIED_RICE] = 1
