@tool
extends Button
class_name InteriorInteractable

@export var image: CompressedTexture2D
@export var time_usage: float = 0
@export var money_cost: float = 40
@export_group("Hospital help desk cost (per lost HP)")
@export var hp_cost_base_fee: float = 20.0
@export var hp_cost_per_point: float = 15.0
@export var hp_cost_severity_multiplier: float = 1.5
@export_group("")
@export var play_time_pass_transition: bool = false
@export var popup_panel_prefab: PackedScene
@export_multiline var pop_up_content: String

@export var give_item_id: EnumAutoload.ItemId = EnumAutoload.ItemId.NONE
@export var give_item_amount: int = 1
@export var gain_stat: Array[int] = [0, 0, 0, 0, 0]
@export var special_case: EnumAutoload.ServiceSpecialCase

var hover_scale: float = 1.1
var hover_duration: float = 0.15
var squeeze_scale: float = 0.9
var squeeze_duration: float = 0.08

var _base_scale: Vector2
var _hover_tween: Tween

var popup_inst: Control

signal activate_interior_effect

func _ready() -> void:
	if image != null:
		icon = image
	pivot_offset = size / 2.0
	_base_scale = scale
	resized.connect(func(): pivot_offset = size / 2.0)

func _process(_delta: float) -> void:
	if is_instance_valid(popup_inst):
		popup_inst.global_position = get_global_mouse_position()


func _on_pressed() -> void:
	var cost = get_current_cost()
	if GameManager.time_left < time_usage:
		return
	if GameManager.player.money < cost:
		return

	GameManager.time_left -= time_usage
	GameManager.player.money -= cost
	resolve_special_case()
	if play_time_pass_transition:
		GameManager.game_ui.play_time_passed_transition()
	activate_interior_effect.emit()
	SoundManager.play_button_click_sfx()
	_squeeze()

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

func _on_mouse_exited() -> void:
	_animate_scale(_base_scale)
	if is_instance_valid(popup_inst):
		popup_inst.queue_free()

func _on_mouse_entered() -> void:
	SoundManager.play_button_click_sfx()
	_animate_scale(_base_scale * hover_scale)
	if popup_inst == null:
		popup_inst = popup_panel_prefab.instantiate()
		add_child(popup_inst)
		var cost_text = ""
		var current_cost = get_current_cost()
		if time_usage > 0:
			cost_text += "Time: %.2f$ |" % time_usage
		if current_cost > 0:
			cost_text += "Money: %.2f$" % current_cost

		popup_inst.get_node("RichTextLabel").text = cost_text + "\n" + pop_up_content


func _animate_scale(target_scale: Vector2) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, hover_duration)

func _squeeze() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", _base_scale * squeeze_scale, squeeze_duration)
	_hover_tween.tween_property(self, "scale", _base_scale * hover_scale, squeeze_duration)
