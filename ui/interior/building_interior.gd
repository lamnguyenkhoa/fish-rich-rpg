extends Control
class_name BuildingInterior

signal ui_opened

func _input(event):
	if event.is_action_pressed("leave_place") and visible:
		close_ui()

func open_ui():
	visible = true
	GameManager.stop_time()
	ui_opened.emit()

func close_ui():
	visible = false
	GameManager.start_time()
	GameManager.player.is_busy = false
