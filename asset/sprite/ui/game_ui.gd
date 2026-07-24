extends Control
class_name GameUI

@onready var money_label: Label = $TopBanner/MoneyLabel
@onready var time_left_label: RichTextLabel = $TopBanner/TimeLeft
@onready var notification_ui: NotificationUI = $NotificationUI
@onready var npc_interact_ui: NPCInteractUI = $NPCInteractUI
@onready var tutorial_ui = $TutorialUI
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	GameManager.game_ui = self

func _process(_delta: float) -> void:
	if GameManager.time_left <= 10.0:
		time_left_label.text = "%.2f" % GameManager.time_left
	else:
		time_left_label.text = "%d" % GameManager.time_left

func update_money_text(amount: int):
	money_label.text = "Money: {0}$".format([amount])

func play_day_transition():
	anim_player.play("day_transition")

func _on_close_tutorial_button_pressed() -> void:
	tutorial_ui.visible = false
	SoundManager.play_button_click_sfx()

func _on_close_tutorial_button_mouse_entered() -> void:
	SoundManager.play_button_hover_sfx()
