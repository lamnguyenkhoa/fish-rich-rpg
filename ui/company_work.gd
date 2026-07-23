extends Control
class_name CompanyWork

@export var xp_per_level: Array[int] = [100] # Need at least 1

@onready var reputation_label: Label = $ReputationLabel
@onready var reputation_progress: TextureProgressBar = $ReputationProgress
@onready var progress_label: RichTextLabel = $ReputationProgress/ProgressLabel
@onready var promote_button: Button = $PromoteButton
@onready var job_box = $JobBox

signal ui_opened

var max_reputation_level: int = 1
var current_reputation_level: int = 1
var current_xp: int = 0
var current_position_id = 0

func _ready() -> void:
	max_reputation_level = len(xp_per_level) + 1
	reputation_label.text = "Reputation - {0}".format([current_reputation_level])
	reputation_progress.value = (float(current_xp) / xp_per_level[current_reputation_level - 1]) * 100
	progress_label.text = "[center]{0} / {1}[/center]".format([current_xp, xp_per_level[current_reputation_level - 1]])
	show_position_id_work(0)
	refresh_promote_eligibility()
	await get_tree().process_frame
	await get_tree().process_frame
	GameManager.player.stat_changed.connect(refresh_promote_eligibility)

func _input(event):
	if event.is_action_pressed("leave_place") and visible:
		close_ui()

func open_ui():
	visible = true
	refresh_promote_eligibility()
	emit_signal("ui_opened")

func close_ui():
	visible = false
	GameManager.player.is_busy = false

func gain_xp(amount: int):
	if current_reputation_level >= max_reputation_level:
		return

	current_xp = clampi(0, current_xp + amount, 99999)
	if current_xp >= xp_per_level[current_reputation_level - 1]:
		current_reputation_level += 1
		current_xp = 0
		if current_reputation_level >= max_reputation_level:
			reputation_label.text = "Reputation - {0}".format([current_reputation_level])
			reputation_progress.value = 100
			progress_label.text = "[center][rainbow]Maxed reputation![/rainbow][/center]"
			return
	
	reputation_label.text = "Reputation - {0}".format([current_reputation_level])
	reputation_progress.value = (float(current_xp) / xp_per_level[current_reputation_level - 1]) * 100
	progress_label.text = "[center]{0} / {1}[/center]".format([current_xp, xp_per_level[current_reputation_level - 1]])

func _on_leave_button_pressed() -> void:
	SoundManager.play_button_click_sfx()
	close_ui()

func show_position_id_work(id: int):
	if id >= job_box.get_child_count():
		return
	for child in job_box.get_children():
		child.visible = false
	job_box.get_child(id).visible = true

func promote():
	if current_position_id + 1 >= job_box.get_child_count():
		return
	current_position_id += 1
	show_position_id_work(current_position_id)
	refresh_promote_eligibility()

func refresh_promote_eligibility():
	if current_position_id + 1 >= job_box.get_child_count():
		promote_button.disabled = true
		promote_button.text = "You are peaked!"
		return

	promote_button.disabled = false
	promote_button.text = "Apply for Promotion"
	var next_job: WorkButton = job_box.get_child(current_position_id + 1)
	if GameManager.player.for_stat < next_job.need_for_stat:
		promote_button.disabled = true
		promote_button.text = "Need {0} FOR.".format([next_job.need_for_stat])
	if GameManager.player.int_stat < next_job.need_int_stat:
		promote_button.disabled = true
		promote_button.text = "Need {0} INT.".format([next_job.need_int_stat])
	if GameManager.player.str_stat < next_job.need_str_stat:
		promote_button.disabled = true
		promote_button.text = "Need {0} STR.".format([next_job.need_str_stat])
	if GameManager.player.har_stat < next_job.need_har_stat:
		promote_button.disabled = true
		promote_button.text = "Need {0} HAR.".format([next_job.need_har_stat])
	if GameManager.player.yee_stat < next_job.need_yee_stat:
		promote_button.disabled = true
		promote_button.text = "Need {0} YEE.".format([next_job.need_yee_stat])

func _on_promote_button_pressed():
	SoundManager.play_button_click_sfx()
	promote()

func play_button_hover_sfx():
	SoundManager.play_button_hover_sfx()
