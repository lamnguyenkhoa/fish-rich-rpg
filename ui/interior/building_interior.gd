extends Control
class_name BuildingInterior

signal ui_opened


func _input(event):
	if event.is_action_pressed("leave_place") and visible:
		close_ui()
        
func open_ui():
	visible = true
	ui_opened.emit()

func close_ui():
	visible = false
	GameManager.player.is_busy = false
