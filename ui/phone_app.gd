extends VBoxContainer
class_name PhoneApp

@export var app_icon: CompressedTexture2D
@export var app_name: String

@onready var button: Button = $Button
@onready var label: Label = $Label

var hover_scale: float = 1.1
var hover_duration: float = 0.15
var squeeze_scale: float = 0.9
var squeeze_duration: float = 0.08
var _base_scale: Vector2
var _hover_tween: Tween

signal app_opened(String)

func _ready() -> void:
	button.icon = app_icon
	label.text = app_name
	pivot_offset = size / 2.0
	_base_scale = scale
	resized.connect(func(): pivot_offset = size / 2.0)


func _on_button_pressed() -> void:
	app_opened.emit(app_name)
	
func _on_button_mouse_exited() -> void:
	_animate_scale(_base_scale)


func _on_button_mouse_entered() -> void:
	SoundManager.play_button_click_sfx()
	_animate_scale(_base_scale * hover_scale)


func _animate_scale(target_scale: Vector2) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, hover_duration)
