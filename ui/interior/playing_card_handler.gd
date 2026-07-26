extends ColorRect
class_name PlayingCardHandler
## Mostly self-contained, only need PlayingCard

## Blackjack table for the casino. Stays hidden until `trigger_button` is
## pressed, then plays a normal round against the dealer using the player's money.

const CARD_DISPLAY_SIZE := Vector2(112, 156)
const DEAL_DELAY := 0.35
const CHARLIE_CARD_COUNT := 5

const STATUS_COLOR_NEUTRAL := Color(1, 1, 1)
const STATUS_COLOR_WIN := Color(0.35, 0.85, 0.35)
const STATUS_COLOR_LOSE := Color(0.9, 0.3, 0.3)
const STATUS_COLOR_PUSH := Color(0.9, 0.8, 0.3)

@export var trigger_button: Button
@export var card_back_style: int = 0
@export var bet_step: float = 100.0
@export var time_cost_per_round: float = 0.0
## Prank mode: rigs which card comes off the deck instead of touching the
## outcome after the fact. Player draws are steered toward a strong hand,
## the dealer's starting hand is steered weak so the normal "hit below 17"
## rule forces more draws, and those forced draws are steered toward busting.
## The player can still lose - a card that satisfies the bias just isn't
## always left in the deck - so it plays like a bad-beat streak, not a switch.
var ultraluck = false
@export var force_ultraluck: bool = false
@export var ultraluck_bet_lower_threshold: float = 100_000

var _deck: Array[int] = []
var _player_hand: Array[int] = []
var _dealer_hand: Array[int] = []
var _bet: float = 0.0
var _round_active := false
var _busy := false

var _status_label: Label
var _dealer_row: HBoxContainer
var _player_row: HBoxContainer
var _dealer_label: Label
var _player_label: Label
var _bet_label: Label
var _bet_input: LineEdit
var _bet_down_button: Button
var _bet_up_button: Button
var _deal_button: Button
var _hit_button: Button
var _stand_button: Button
var _leave_button: Button


func _ready() -> void:
	_build_ui()
	visible = false
	if trigger_button != null:
		trigger_button.pressed.connect(open_table)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("leave_place"):
		# Swallow the key so the casino interior behind us does not close too.
		get_viewport().set_input_as_handled()
		if not _round_active and not _busy:
			close_table()


func open_table() -> void:
	visible = true
	_deck = PlayingCard.new_shuffled_deck()
	_bet = bet_step
	_clear_table()
	_set_status("Place your bet and deal.")
	_refresh()


func close_table() -> void:
	visible = false


# ---------------------------------------------------------------- round flow

func _deal() -> void:
	if _round_active or _busy:
		return
	if GameManager.player.money < _bet:
		_set_status("You cannot afford that bet.")
		return

	GameManager.player.money -= _bet
	if time_cost_per_round > 0:
		GameManager.pass_time(time_cost_per_round)
	# No shoe carried between rounds - every deal is a brand new 52-card deck.
	_deck = PlayingCard.new_shuffled_deck()

	_clear_table()
	_round_active = true
	_busy = true
	_refresh()

	_draw_card(_player_hand, _player_row, false, _DrawBias.PLAYER)
	await _pause()
	_draw_card(_dealer_hand, _dealer_row, false, _DrawBias.DEALER_WEAK)
	await _pause()
	_draw_card(_player_hand, _player_row, false, _DrawBias.PLAYER)
	await _pause()
	_draw_card(_dealer_hand, _dealer_row, true, _DrawBias.DEALER_WEAK)
	_busy = false

	if PlayingCard.is_natural_blackjack(_player_hand) or PlayingCard.is_natural_blackjack(_dealer_hand):
		_round_active = false
		_reveal_hole_card()
		await _pause()
		_resolve()
		return

	_set_status("Hit or stand?")
	_refresh()


func _hit() -> void:
	if not _round_active or _busy:
		return
	_draw_card(_player_hand, _player_row, false, _DrawBias.PLAYER)
	_refresh()

	var total := PlayingCard.hand_value(_player_hand)
	if total > 21:
		_round_active = false
		_reveal_hole_card()
		_resolve()
	elif total == 21 or _player_hand.size() >= CHARLIE_CARD_COUNT:
		_auto_win("21!" if total == 21 else "%d-card Charlie!" % _player_hand.size())


func _stand() -> void:
	if not _round_active or _busy:
		return
	_round_active = false
	_busy = true
	_refresh()

	_reveal_hole_card()
	await _pause()
	while PlayingCard.hand_value(_dealer_hand) < 17:
		_draw_card(_dealer_hand, _dealer_row, false, _DrawBias.DEALER_RISKY)
		_refresh()
		await _pause()

	_busy = false
	_resolve()


func _auto_win(reason: String) -> void:
	_round_active = false
	_reveal_hole_card()
	GameManager.player.money += _bet * 2.0
	_set_status("%s You win %.2f$ automatically." % [reason, _bet], STATUS_COLOR_WIN)
	_refresh()


func _resolve() -> void:
	var player_total := PlayingCard.hand_value(_player_hand)
	var dealer_total := PlayingCard.hand_value(_dealer_hand)
	var player_natural := PlayingCard.is_natural_blackjack(_player_hand)
	var dealer_natural := PlayingCard.is_natural_blackjack(_dealer_hand)

	var payout := 0.0
	var message := ""

	if player_total > 21:
		message = "Bust! You lose %.2f$." % _bet
	elif player_natural and not dealer_natural:
		payout = _bet * 2.5 # blackjack pays 3:2
		message = "Blackjack! You win %.2f$." % (_bet * 1.5)
	elif dealer_natural and not player_natural:
		message = "Dealer has blackjack. You lose %.2f$." % _bet
	elif dealer_total > 21:
		payout = _bet * 2.0
		message = "Dealer busts! You win %.2f$." % _bet
	elif player_total > dealer_total:
		payout = _bet * 2.0
		message = "%d beats %d. You win %.2f$." % [player_total, dealer_total, _bet]
	elif player_total < dealer_total:
		message = "%d loses to %d. You lose %.2f$." % [player_total, dealer_total, _bet]
	else:
		payout = _bet
		message = "Push at %d. Your bet comes back." % player_total

	if payout > 0:
		GameManager.player.money += payout

	var status_color := STATUS_COLOR_LOSE
	if payout > _bet:
		status_color = STATUS_COLOR_WIN
	elif payout == _bet:
		status_color = STATUS_COLOR_PUSH

	_round_active = false
	_set_status(message, status_color)
	_refresh()


# ------------------------------------------------------------------- helpers

enum _DrawBias {NONE, PLAYER, DEALER_WEAK, DEALER_RISKY}

func _draw_card(hand: Array[int], row: HBoxContainer, face_down: bool = false, bias: _DrawBias = _DrawBias.NONE) -> void:
	if _deck.is_empty():
		_deck = PlayingCard.new_shuffled_deck()

	var index := _deck.size() - 1
	if ultraluck and bias != _DrawBias.NONE:
		index = _rigged_index(hand, bias)
	var card: int = _deck[index]
	_deck.remove_at(index)
	hand.append(card)

	var rect := TextureRect.new()
	rect.custom_minimum_size = CARD_DISPLAY_SIZE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture = PlayingCard.back_texture(card_back_style) if face_down else PlayingCard.front_texture(card)
	rect.set_meta("card", card)
	rect.set_meta("face_down", face_down)
	rect.modulate.a = 0.0
	row.add_child(rect)

	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.15)
	SoundManager.play_button_click_sfx()


## Picks which deck index gets drawn next under ultraluck. Scans the whole
## remaining deck rather than the literal top card, since the deck is just an
## in-memory array and nothing else observes draw order.
func _rigged_index(hand: Array[int], bias: _DrawBias) -> int:
	match bias:
		_DrawBias.PLAYER:
			# Prefer landing in 17-21 (picked at random among ties so it's not
			# always a flat 21); otherwise take the highest total that doesn't bust.
			var strong_hits: Array[int] = []
			var best_index := -1
			var best_total := -1
			for i in _deck.size():
				var test_hand := hand.duplicate()
				test_hand.append(_deck[i])
				var total := PlayingCard.hand_value(test_hand)
				if total > 21:
					continue
				if total >= 17:
					strong_hits.append(i)
				if total > best_total:
					best_total = total
					best_index = i
			if not strong_hits.is_empty():
				return strong_hits[randi() % strong_hits.size()]
			return best_index if best_index != -1 else _deck.size() - 1

		_DrawBias.DEALER_WEAK:
			# Keep the dealer's total as low as possible, so the standard
			# "must hit below 17" rule forces more of these rigged draws.
			var low_index := _deck.size() - 1
			var low_total := 9999
			for i in _deck.size():
				var test_hand := hand.duplicate()
				test_hand.append(_deck[i])
				var total := PlayingCard.hand_value(test_hand)
				if total < low_total:
					low_total = total
					low_index = i
			return low_index

		_DrawBias.DEALER_RISKY:
			# Bust if at all possible; otherwise push as close to 21 as
			# possible so the next mandatory hit is even more likely to bust.
			var bust_hits: Array[int] = []
			var high_index := -1
			var high_total := -1
			for i in _deck.size():
				var test_hand := hand.duplicate()
				test_hand.append(_deck[i])
				var total := PlayingCard.hand_value(test_hand)
				if total > 21:
					bust_hits.append(i)
				elif total > high_total:
					high_total = total
					high_index = i
			if not bust_hits.is_empty():
				return bust_hits[randi() % bust_hits.size()]
			return high_index if high_index != -1 else _deck.size() - 1

		_:
			return _deck.size() - 1


func _reveal_hole_card() -> void:
	for child: TextureRect in _dealer_row.get_children():
		if child.get_meta("face_down", false):
			child.texture = PlayingCard.front_texture(child.get_meta("card"))
			child.set_meta("face_down", false)


func _clear_table() -> void:
	_player_hand.clear()
	_dealer_hand.clear()
	for row in [_player_row, _dealer_row]:
		for child in row.get_children():
			# Remove now rather than at frame end, so the row reads as empty
			# to _refresh() straight away.
			row.remove_child(child)
			child.queue_free()


func _pause() -> void:
	await get_tree().create_timer(DEAL_DELAY).timeout


func _set_status(text: String, status_color: Color = STATUS_COLOR_NEUTRAL) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", status_color)


func _has_hidden_card() -> bool:
	for child in _dealer_row.get_children():
		if child.get_meta("face_down", false):
			return true
	return false


func _refresh() -> void:
	var idle := not _round_active and not _busy

	_player_label.text = "You  —  %d" % PlayingCard.hand_value(_player_hand)
	if _has_hidden_card():
		_dealer_label.text = "Dealer  —  ?"
	else:
		_dealer_label.text = "Dealer  —  %d" % PlayingCard.hand_value(_dealer_hand)

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
	_deal_button.disabled = not idle or GameManager.player.money < _bet
	_leave_button.disabled = not idle
	_hit_button.disabled = not _round_active or _busy
	_stand_button.disabled = not _round_active or _busy


func _update_ultraluck() -> void:
	if (_bet >= ultraluck_bet_lower_threshold and GameManager.is_won) or force_ultraluck:
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
	root.add_theme_constant_override("separation", 12)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(root)

	_status_label = _make_label("", 28)
	root.add_child(_status_label)

	_dealer_label = _make_label("Dealer", 22)
	root.add_child(_dealer_label)
	_dealer_row = _make_card_row()
	root.add_child(_dealer_row)

	_player_label = _make_label("You", 22)
	root.add_child(_player_label)
	_player_row = _make_card_row()
	root.add_child(_player_row)

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
	_deal_button = _make_button("Deal", controls)
	_hit_button = _make_button("Hit", controls)
	_stand_button = _make_button("Stand", controls)
	_leave_button = _make_button("Leave table", controls)

	_bet_input.text_submitted.connect(_on_bet_input_committed)
	_bet_input.focus_exited.connect(func(): _on_bet_input_committed(_bet_input.text))
	_bet_down_button.pressed.connect(_change_bet.bind(-bet_step))
	_bet_up_button.pressed.connect(_change_bet.bind(bet_step))
	_deal_button.pressed.connect(_deal)
	_hit_button.pressed.connect(_hit)
	_stand_button.pressed.connect(_stand)
	_leave_button.pressed.connect(close_table)


func _make_rules_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 0)
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
	rules.text = "[b]Blackjack Rules[/b]\n\n" \
			+"Get closer to 21 than the dealer without going over.\n\n" \
			+"• Aces count as 11 or 1\n" \
			+"• Face cards count as 10\n" \
			+"• Blackjack (21 on 2 cards) pays 3:2\n" \
			+"• 21 on any hand, or 5 cards without busting (5-card Charlie), wins instantly\n" \
			+"• Dealer must hit below 17, and stand on 17+\n" \
			+"• Bust (over 21) loses your bet\n" \
			+"• A tied total is a push - your bet comes back\n" \
			+"• Every hand is dealt from a freshly shuffled single deck - no card counting here"
	margin.add_child(rules)

	return panel


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_card_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = CARD_DISPLAY_SIZE.y
	return row


func _make_button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 48)
	parent.add_child(button)
	return button
