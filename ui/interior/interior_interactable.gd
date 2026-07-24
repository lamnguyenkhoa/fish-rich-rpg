@tool
extends Button
class_name InteriorInteractable

@export var image: CompressedTexture2D
@export var time_usage: float = 0

var hover_scale: float = 1.1
var hover_duration: float = 0.15
var squeeze_scale: float = 0.9
var squeeze_duration: float = 0.08

var _base_scale: Vector2
var _hover_tween: Tween


func _ready() -> void:
	if image != null:
		icon = image
	pivot_offset = size / 2.0
	_base_scale = scale
	resized.connect(func(): pivot_offset = size / 2.0)


func _on_pressed() -> void:
	SoundManager.play_button_click_sfx()
	_squeeze()

func _on_mouse_exited() -> void:
	_animate_scale(_base_scale)

func _on_mouse_entered() -> void:
	SoundManager.play_button_click_sfx()
	_animate_scale(_base_scale * hover_scale)

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
