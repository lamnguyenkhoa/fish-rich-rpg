@tool
extends Button
class_name InteriorInteractable

@export var image: CompressedTexture2D
@export var time_usage: float = 0
@export var money_cost: float = 0
@export var play_time_pass_transition: bool = false
@export var popup_panel_prefab: PackedScene
@export_multiline var pop_up_content: String

@export_group("Player effect")


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
	if GameManager.time_left < time_usage:
		return
	if GameManager.player.money < money_cost:
		return

	GameManager.time_left -= time_usage
	GameManager.player.money -= money_cost
	if play_time_pass_transition:
		GameManager.game_ui.play_time_passed_transition()
	activate_interior_effect.emit()
	SoundManager.play_button_click_sfx()
	_squeeze()

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
		if time_usage > 0:
			cost_text += "Time: %.2f$ |" % time_usage
		if money_cost > 0:
			cost_text += "Money: %.2f$" % money_cost

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
