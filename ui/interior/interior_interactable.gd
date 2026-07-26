@tool
extends Button
class_name InteriorInteractable

@export var image: CompressedTexture2D
@export var time_usage: float = 0
@export var money_cost: float = 0
@export var limited_stock = false
@export var max_service_stock: int = 1
@export var play_time_pass_transition: bool = false
@export var popup_panel_prefab: PackedScene
@export_multiline var pop_up_content: String

@export var give_item_id: EnumAutoload.ItemId = EnumAutoload.ItemId.NONE
@export var give_item_amount: int = 1
@export var gain_stat: Array[int] = [0, 0, 0, 0, 0]
@export var special_case: EnumAutoload.ServiceSpecialCase
@export var recover_hp: int = 0
@export var recover_sp: int = 0

var hp_cost_base_fee: float = 20.0
var hp_cost_per_point: float = 15.0
var hp_cost_severity_multiplier: float = 1.5

var hover_scale: float = 1.1
var hover_duration: float = 0.15
var squeeze_scale: float = 0.9
var squeeze_duration: float = 0.08
var _base_scale: Vector2
var _hover_tween: Tween

var popup_inst: Control
var current_service_stock: int


func _ready() -> void:
	if image != null:
		icon = image
	pivot_offset = size / 2.0
	_base_scale = scale
	resized.connect(func(): pivot_offset = size / 2.0)
	current_service_stock = max_service_stock

	if not Engine.is_editor_hint():
		update_interactable_button()
		GameManager.player.money_changed.connect(update_interactable_button)

func _process(_delta: float) -> void:
	if is_instance_valid(popup_inst):
		popup_inst.global_position = get_global_mouse_position()


func _on_pressed() -> void:
	if disabled:
		return
	var cost = get_current_cost()
	if GameManager.time_left < time_usage:
		return
	if GameManager.player.money < cost:
		return

	GameManager.time_left -= time_usage
	GameManager.player.money -= cost
	if give_item_id != EnumAutoload.ItemId.NONE:
		GameManager.player.acquired_item(give_item_id, give_item_amount)
	if special_case != EnumAutoload.ServiceSpecialCase.NONE:
		resolve_special_case()
	GameManager.player.recover("hp", recover_hp, false)
	# GameManager.player.recover("hp", recover_hp_percentage, true)
	GameManager.player.recover("sp", recover_sp, false)
	# GameManager.player.recover("sp", recover_sp_percentage, true)
	GameManager.player.for_stat += gain_stat[0]
	GameManager.player.int_stat += gain_stat[1]
	GameManager.player.str_stat += gain_stat[2]
	GameManager.player.har_stat += gain_stat[3]
	GameManager.player.yee_stat += gain_stat[4]
	if play_time_pass_transition:
		GameManager.game_ui.play_time_passed_transition()
	SoundManager.play_button_click_sfx()
	_squeeze()
	if limited_stock:
		current_service_stock -= 1
	update_interactable_button()


func update_interactable_button():
	disabled = false
	if GameManager.player.money < money_cost:
		disabled = true
	if limited_stock and current_service_stock <= 0:
		disabled = true
	if special_case == EnumAutoload.ServiceSpecialCase.HOSPITAL_HELP_DESK and get_current_cost() == 0:
		disabled = true


func get_current_cost() -> float:
	match special_case:
		EnumAutoload.ServiceSpecialCase.HOSPITAL_HELP_DESK:
			var lost_hp = GameManager.player.max_hp - GameManager.player.current_hp
			if lost_hp <= 0:
				return 0.0
			var lost_ratio = float(lost_hp) / GameManager.player.max_hp
			return hp_cost_base_fee + hp_cost_per_point * lost_hp * (1.0 + hp_cost_severity_multiplier * lost_ratio)
		_:
			return money_cost

func resolve_special_case():
	match special_case:
		EnumAutoload.ServiceSpecialCase.HOSPITAL_HELP_DESK:
			GameManager.player.recover("hp", GameManager.player.max_hp, false)
		EnumAutoload.ServiceSpecialCase.FINISH_THE_CHALLENGE:
			if GameManager.player.money <= 0.001:
				GameManager.finish_the_challenge()
				disabled = true


func _on_mouse_exited() -> void:
	_animate_scale(_base_scale)
	if is_instance_valid(popup_inst):
		popup_inst.queue_free()

func _on_mouse_entered() -> void:
	SoundManager.play_button_click_sfx()
	_animate_scale(_base_scale * hover_scale)
	if popup_inst == null:
		popup_inst = popup_panel_prefab.instantiate()
		get_parent().add_child(popup_inst)
		var cost_text = ""
		var current_cost = get_current_cost()
		if time_usage > 0:
			cost_text += "[color=red]Time: %.2fs [/color] | " % time_usage
		if current_cost > 0:
			cost_text += "Money: %.2f$ | " % current_cost
		if limited_stock:
			cost_text += "(%s left)" % current_service_stock
		popup_inst.get_node("RichTextLabel").text = cost_text + "\n" + pop_up_content


func _animate_scale(target_scale: Vector2) -> void:
	if disabled:
		return
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, hover_duration)

func _squeeze() -> void:
	if disabled:
		return
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", _base_scale * squeeze_scale, squeeze_duration)
	_hover_tween.tween_property(self, "scale", _base_scale * hover_scale, squeeze_duration)
