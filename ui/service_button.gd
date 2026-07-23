@tool
extends HBoxContainer
class_name ServiceButton

@export var service_name: String = "Buy item"
@export var service_desc: String = "Buy item desc"
@export var service_cost: int = 10
@export var service_time_needed: int = 0
@export var reputation_xp: int = 0
@export var company: CompanyWork
@export var limited_stock = false
@export var max_service_stock: int = 10
@export var no_restock = false

@export_group("Service effect")
@export var give_item_id: EnumAutoload.ItemId = EnumAutoload.ItemId.NONE
@export var give_item_amount: int = 1
@export var recover_hp: int = 0
@export var recover_sp: int = 0
@export var recover_hp_percentage: int = 0
@export var recover_sp_percentage: int = 0
@export var gain_stat: Array[int] = [0, 0, 0, 0, 0]
@export var special_case: EnumAutoload.ServiceSpecialCase

@onready var button: Button = $Button
@onready var label: Label = $Label

var current_service_stock: int

func _ready() -> void:
	current_service_stock = max_service_stock
	button.text = service_name
	if limited_stock:
		button.text = "{0} ({1} left)".format([service_name, current_service_stock])
	label.text = service_desc
	if service_cost > 0:
		label.text = "{0}$, ".format([service_cost]) + label.text
	if service_time_needed > 0:
		label.text = "{0} period(s), ".format([service_time_needed]) + label.text

	if not Engine.is_editor_hint():
		if special_case == EnumAutoload.ServiceSpecialCase.PAY_DEBT:
			service_cost = GameManager.debt_money
			label.text = "Pay debt {0}$, ".format([service_cost]) + service_desc
			button.text = service_name
		update_service_status()
		company.ui_opened.connect(update_service_status)
		GameManager.time_passed.connect(update_service_status)
		GameManager.day_passed.connect(restock)
		GameManager.player.money_changed.connect(update_service_status)

func update_service_status():
	button.disabled = false
	button.text = service_name
	if special_case == EnumAutoload.ServiceSpecialCase.PAY_DEBT and GameManager.debt_paid:
		visible = false
	if limited_stock and special_case != EnumAutoload.ServiceSpecialCase.PAY_DEBT:
		button.text = "{0} ({1} left)".format([service_name, current_service_stock])
	if limited_stock and current_service_stock <= 0:
		button.disabled = true
	if GameManager.player.money < service_cost:
		button.disabled = true
	if GameManager.get_time_left() < service_time_needed:
		button.disabled = true

func _on_button_pressed():
	GameManager.pass_time(service_time_needed)
	company.gain_xp(reputation_xp)
	GameManager.player.money -= service_cost
	if limited_stock:
		current_service_stock -= 1
	SoundManager.play_button_click_sfx()
	if give_item_id != EnumAutoload.ItemId.NONE:
		GameManager.player.acquired_item(give_item_id, give_item_amount)
	if special_case != EnumAutoload.ServiceSpecialCase.NONE:
		resolve_special_case(special_case)
	GameManager.player.recover("hp", recover_hp, false)
	GameManager.player.recover("hp", recover_hp_percentage, true)
	GameManager.player.recover("sp", recover_sp, false)
	GameManager.player.recover("sp", recover_sp_percentage, true)
	GameManager.player.for_stat += gain_stat[0]
	GameManager.player.int_stat += gain_stat[1]
	GameManager.player.str_stat += gain_stat[2]
	GameManager.player.har_stat += gain_stat[3]
	GameManager.player.yee_stat += gain_stat[4]

func resolve_special_case(_special_case: EnumAutoload.ServiceSpecialCase):
	match _special_case:
		EnumAutoload.ServiceSpecialCase.NEXT_DAY:
			GameManager.move_to_next_day()
		EnumAutoload.ServiceSpecialCase.SMUGGLE:
			GameManager.prison_smuggle()
		EnumAutoload.ServiceSpecialCase.PAY_DEBT:
			GameManager.paid_the_debt()
			visible = false

func play_button_hover_sfx():
	SoundManager.play_button_hover_sfx()

func restock():
	if limited_stock and not no_restock:
		current_service_stock = max_service_stock
