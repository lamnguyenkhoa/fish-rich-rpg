extends ColorRect
class_name PlayingCardHandler
## Blackjack table for the casino. Stays hidden until `trigger_button` is
## pressed, then plays a normal round against the dealer using the player's money.

const CARD_DISPLAY_SIZE := Vector2(112, 156)
const DEAL_DELAY := 0.35
const RESHUFFLE_BELOW := 15

@export var trigger_button: Button
@export var card_back_style: int = 0
@export var bet_step: float = 100.0
@export var deck_count: int = 4
@export var time_cost_per_round: float = 5.0

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
	_deck = PlayingCard.new_shuffled_deck(deck_count)
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
	if _deck.size() < RESHUFFLE_BELOW:
		_deck = PlayingCard.new_shuffled_deck(deck_count)

	_clear_table()
	_round_active = true
	_busy = true
	_refresh()

	_draw_card(_player_hand, _player_row)
	await _pause()
	_draw_card(_dealer_hand, _dealer_row)
	await _pause()
	_draw_card(_player_hand, _player_row)
	await _pause()
	_draw_card(_dealer_hand, _dealer_row, true)
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
	_draw_card(_player_hand, _player_row)
	_refresh()

	var total := PlayingCard.hand_value(_player_hand)
	if total > 21:
		_round_active = false
		_reveal_hole_card()
		_resolve()
	elif total == 21:
		_stand()


func _stand() -> void:
	if not _round_active or _busy:
		return
	_round_active = false
	_busy = true
	_refresh()

	_reveal_hole_card()
	await _pause()
	while PlayingCard.hand_value(_dealer_hand) < 17:
		_draw_card(_dealer_hand, _dealer_row)
		_refresh()
		await _pause()

	_busy = false
	_resolve()


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

	_round_active = false
	_set_status(message)
	_refresh()


# ------------------------------------------------------------------- helpers

func _draw_card(hand: Array[int], row: HBoxContainer, face_down: bool = false) -> void:
	if _deck.is_empty():
		_deck = PlayingCard.new_shuffled_deck(deck_count)
	var card: int = _deck.pop_back()
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


func _set_status(text: String) -> void:
	_status_label.text = text


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
	_bet_label.text = "Bet: %.2f$" % _bet

	_bet_down_button.disabled = not idle or _bet <= bet_step
	_bet_up_button.disabled = not idle or _bet + bet_step > GameManager.player.money
	_deal_button.disabled = not idle or GameManager.player.money < _bet
	_leave_button.disabled = not idle
	_hit_button.disabled = not _round_active or _busy
	_stand_button.disabled = not _round_active or _busy


func _change_bet(delta: float) -> void:
	_bet += delta
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

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(root)

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
	_bet_up_button = _make_button("+ Bet", controls)
	_deal_button = _make_button("Deal", controls)
	_hit_button = _make_button("Hit", controls)
	_stand_button = _make_button("Stand", controls)
	_leave_button = _make_button("Leave table", controls)

	_bet_down_button.pressed.connect(_change_bet.bind(-bet_step))
	_bet_up_button.pressed.connect(_change_bet.bind(bet_step))
	_deal_button.pressed.connect(_deal)
	_hit_button.pressed.connect(_hit)
	_stand_button.pressed.connect(_stand)
	_leave_button.pressed.connect(close_table)


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
