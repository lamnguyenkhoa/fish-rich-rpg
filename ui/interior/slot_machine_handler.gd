extends ColorRect
class_name SlotMachineHandler
## Mostly self-contained, only needs GameManager for money.

## Slot machine for the casino. Stays hidden until `trigger_button` is pressed,
## then spins three reels for a payout multiplied against the player's bet.

const REEL_COUNT := 3
const SYMBOL_DISPLAY_SIZE := Vector2(140, 140)
## How long each reel keeps blurring before it locks, left to right.
const REEL_STOP_DELAY := 0.55
const SPIN_TICK := 0.06

const STATUS_COLOR_NEUTRAL := Color(1, 1, 1)
const STATUS_COLOR_LOSE := Color(0.9, 0.3, 0.3)
const STATUS_COLOR_JACKPOT := Color(1.0, 0.85, 0.2)

## Ordered weakest to strongest. `weight` only drives honest (non-ultraluck)
## spins; `payout` is the multiplier paid when all three reels match.
const SYMBOLS := [
	{
		"name": "Cherry",
		"path": "res://asset/sprite/ui/slot_machine/cherry.png",
		"weight": 34,
		"payout": 5.0,
	},
	{
		"name": "Banana",
		"path": "res://asset/sprite/ui/slot_machine/banana.png",
		"weight": 28,
		"payout": 8.0,
	},
	{
		"name": "Bell",
		"path": "res://asset/sprite/ui/slot_machine/bell.png",
		"weight": 24,
		"payout": 10.0,
	},
	{
		"name": "Clover",
		"path": "res://asset/sprite/ui/slot_machine/clover.png",
		"weight": 18,
		"payout": 15.0,
	},
	{
		"name": "Horseshoe",
		"path": "res://asset/sprite/ui/slot_machine/horseshoe.png",
		"weight": 14,
		"payout": 20.0,
	},
	{
		"name": "Diamond",
		"path": "res://asset/sprite/ui/slot_machine/diamond.png",
		"weight": 10,
		"payout": 25.0,
	},
	{
		"name": "Seven",
		"path": "res://asset/sprite/ui/slot_machine/number7.png",
		"weight": 6,
		"payout": 50.0,
	},
]

## Ultraluck outcome mix. The remainder lands as a near miss - two matching
## reels, which pays nothing but reads as "so close" rather than a flat loss.
const ULTRALUCK_TRIPLE_CHANCE := 0.85

@export var trigger_button: Button
@export var bet_step: float = 100.0
@export var time_cost_per_spin: float = 0.0
## Prank mode: rigs which symbols the reels land on instead of touching the
## payout after the fact. The reels still settle one at a time on ordinary
## looking symbols, so a rigged jackpot is indistinguishable from a lucky one.
var ultraluck = false
@export var force_ultraluck: bool = false
@export var ultraluck_bet_lower_threshold: float = 100_000
@export var ultraluck_bet_upper_threshold: float = 1_100_000

var _textures: Array[Texture2D] = []
var _bet: float = 0.0
var _busy := false

var _status_label: Label
var _reels: Array[TextureRect] = []
var _bet_label: Label
var _bet_input: LineEdit
var _bet_down_button: Button
var _bet_up_button: Button
var _spin_button: Button
var _leave_button: Button


func _ready() -> void:
	for symbol in SYMBOLS:
		_textures.append(load(symbol["path"]) as Texture2D)
	_build_ui()
	visible = false
	if trigger_button != null:
		trigger_button.pressed.connect(open_machine)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("leave_place"):
		# Swallow the key so the casino interior behind us does not close too.
		get_viewport().set_input_as_handled()
		if not _busy:
			close_machine()


func open_machine() -> void:
	visible = true
	_bet = bet_step
	for i in REEL_COUNT:
		_reels[i].texture = _textures[i % _textures.size()]
	_set_status("Place your bet and pull.")
	_refresh()


func close_machine() -> void:
	visible = false


# ----------------------------------------------------------------- spin flow

func _spin() -> void:
	if _busy:
		return
	if GameManager.player.money < _bet:
		_set_status("You cannot afford that bet.", STATUS_COLOR_LOSE)
		return

	var wager := _bet
	GameManager.player.money -= wager
	if time_cost_per_spin > 0:
		GameManager.pass_time(time_cost_per_spin)

	_busy = true
	_set_status("Spinning...")
	_refresh()

	var result := _roll_symbols()

	# Settle left to right, leaving the not-yet-locked reels blurring so a
	# two-of-a-kind builds tension on the last reel.
	for i in REEL_COUNT:
		var elapsed := 0.0
		while elapsed < REEL_STOP_DELAY:
			for j in range(i, REEL_COUNT):
				_reels[j].texture = _textures[randi() % _textures.size()]
			await get_tree().create_timer(SPIN_TICK).timeout
			elapsed += SPIN_TICK
		_reels[i].texture = _textures[result[i]]
		_pop_reel(_reels[i])
		SoundManager.play_button_click_sfx()

	_busy = false
	_resolve(result, wager)


func _resolve(result: Array[int], wager: float) -> void:
	var multiplier := 0.0
	var message := ""
	var status_color := STATUS_COLOR_LOSE

	if result[0] == result[1] and result[1] == result[2]:
		multiplier = SYMBOLS[result[0]]["payout"]
		message = "%s x3! You win %.2f$." % [SYMBOLS[result[0]]["name"], wager * multiplier]
		status_color = STATUS_COLOR_JACKPOT
	elif result[0] == result[1] or result[1] == result[2] or result[0] == result[2]:
		message = "So close! You lose %.2f$." % wager
	else:
		message = "No match. You lose %.2f$." % wager

	if multiplier > 0:
		GameManager.player.money += wager * multiplier

	_set_status(message, status_color)
	_refresh()


# ------------------------------------------------------------------- helpers

## Picks the symbols the reels will land on. Ultraluck decides the shape of the
## outcome first (triple / pair / miss) and then fills reels to match, rather
## than rolling honestly and rewriting the payout afterwards.
func _roll_symbols() -> Array[int]:
	var result: Array[int] = []

	if not ultraluck:
		for _i in REEL_COUNT:
			result.append(_weighted_symbol())
		return result

	if randf() < ULTRALUCK_TRIPLE_CHANCE:
		# Bias toward the high payout symbols, since this is meant to dump money.
		var symbol := _weighted_symbol(true)
		for _i in REEL_COUNT:
			result.append(symbol)
	else:
		# A genuine loss, so the machine still looks beatable - but land it as a
		# near miss rather than a blank one.
		var symbol := _weighted_symbol(true)
		var other := _weighted_symbol()
		while other == symbol:
			other = _weighted_symbol()
		result = [symbol, symbol, other]
		result.shuffle()

	return result


## Weighted pick over SYMBOLS. `invert` flips the weights so the rare, high
## paying symbols become the likely ones.
func _weighted_symbol(invert: bool = false) -> int:
	# Mirror each weight around the table's actual min+max rather than assuming
	# SYMBOLS is sorted, so reordering or reweighting it can't silently produce
	# zero or negative weights.
	var pivot := 0
	if invert:
		var lowest: int = SYMBOLS[0]["weight"]
		var highest: int = SYMBOLS[0]["weight"]
		for symbol in SYMBOLS:
			lowest = mini(lowest, symbol["weight"])
			highest = maxi(highest, symbol["weight"])
		pivot = lowest + highest

	var weights: Array[int] = []
	var total := 0
	for symbol in SYMBOLS:
		var weight: int = symbol["weight"]
		if invert:
			weight = pivot - weight
		weights.append(weight)
		total += weight

	var pick := randi() % total
	for i in weights.size():
		pick -= weights[i]
		if pick < 0:
			return i
	return weights.size() - 1


func _pop_reel(reel: TextureRect) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(reel, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(reel, "scale", Vector2.ONE, 0.12)


func _set_status(text: String, status_color: Color = STATUS_COLOR_NEUTRAL) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", status_color)


func _refresh() -> void:
	var idle := not _busy

	_bet = clampf(_bet, bet_step, maxf(bet_step, GameManager.player.money))
	# Recomputed here rather than in the bet handlers, so it always reflects the
	# clamped bet that will actually be wagered - including the opening bet.
	_update_ultraluck()
	_bet_label.text = "Bet: %.2f$" % _bet
	if not _bet_input.has_focus():
		_bet_input.text = "%.2f" % _bet

	_bet_input.editable = idle
	_bet_down_button.disabled = not idle or _bet <= bet_step
	_bet_up_button.disabled = not idle or _bet + bet_step > GameManager.player.money
	_spin_button.disabled = not idle or GameManager.player.money < _bet
	_leave_button.disabled = not idle


func _update_ultraluck() -> void:
	if (_bet >= ultraluck_bet_lower_threshold and _bet <= ultraluck_bet_upper_threshold) or force_ultraluck:
		ultraluck = true
	else:
		ultraluck = false


func _change_bet(delta: float) -> void:
	_bet += delta
	_refresh()


func _on_bet_input_committed(text: String) -> void:
	if text.is_valid_float():
		_bet = clampf(text.to_float(), bet_step, maxf(bet_step, GameManager.player.money))
	_refresh()


# ------------------------------------------------------------------------ ui

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 32)
	margin.add_child(layout)

	layout.add_child(_make_rules_panel())

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(root)

	_status_label = _make_label("", 28)
	root.add_child(_status_label)

	var reel_row := HBoxContainer.new()
	reel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reel_row.add_theme_constant_override("separation", 16)
	reel_row.custom_minimum_size.y = SYMBOL_DISPLAY_SIZE.y
	root.add_child(reel_row)

	for i in REEL_COUNT:
		var slot := PanelContainer.new()
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		reel_row.add_child(slot)

		var reel := TextureRect.new()
		reel.custom_minimum_size = SYMBOL_DISPLAY_SIZE
		reel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		reel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		reel.pivot_offset = SYMBOL_DISPLAY_SIZE / 2.0
		slot.add_child(reel)
		_reels.append(reel)

	_bet_label = _make_label("Bet", 24)
	root.add_child(_bet_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 16)
	root.add_child(controls)

	_bet_down_button = _make_button("- Bet", controls)

	_bet_input = LineEdit.new()
	_bet_input.custom_minimum_size = Vector2(100, 48)
	_bet_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bet_input.max_length = 12
	controls.add_child(_bet_input)

	_bet_up_button = _make_button("+ Bet", controls)
	_spin_button = _make_button("Spin", controls)
	_leave_button = _make_button("Leave machine", controls)

	_bet_input.text_submitted.connect(_on_bet_input_committed)
	_bet_input.focus_exited.connect(func(): _on_bet_input_committed(_bet_input.text))
	_bet_down_button.pressed.connect(_change_bet.bind(-bet_step))
	_bet_up_button.pressed.connect(_change_bet.bind(bet_step))
	_spin_button.pressed.connect(_spin)
	_leave_button.pressed.connect(close_machine)


func _make_rules_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var rules := RichTextLabel.new()
	rules.bbcode_enabled = true
	rules.fit_content = true
	rules.scroll_active = false
	rules.add_theme_font_size_override("normal_font_size", 18)
	rules.add_theme_font_size_override("bold_font_size", 20)

	var paytable := ""
	# Strongest first, so the jackpot reads at the top of the paytable.
	for i in range(SYMBOLS.size() - 1, -1, -1):
		paytable += "[img=28]%s[/img] x3  —  %dx bet\n" % [SYMBOLS[i]["path"], int(SYMBOLS[i]["payout"])]

	rules.text = "[b]Slot Machine Rules[/b]\n\n" \
			+"Match all three reels to win. Payouts are multiples of your bet.\n\n" \
			+ paytable \
			+"\nAnything else  —  you lose your bet\n\n" \
			+"• Only a full three-of-a-kind pays - two matching is still a loss\n" \
			+"• Every spin is independent - the reels have no memory"
	margin.add_child(rules)

	return panel


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 48)
	parent.add_child(button)
	return button
