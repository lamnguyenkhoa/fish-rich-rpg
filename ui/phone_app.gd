extends VBoxContainer
class_name PhoneApp

@export var app_icon: CompressedTexture2D
@export var app_name: String

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready() -> void:
	texture_rect.texture = app_icon
	label.text = app_name

func _on_mouse_entered() -> void:
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	pass # Replace with function body.
