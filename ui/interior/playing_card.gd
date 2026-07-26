extends RefCounted
class_name PlayingCard
## Slices the 13x4 playing card spritesheet into per-card textures, so the 52
## fronts never have to be exported as individual files.
##
## A card is an int in 0..51: suit = card / 13, rank = card % 13.
## Rank 0 is the Ace, ranks 1..9 are 2..10, ranks 10..12 are J/Q/K.

enum Suit {CLUBS, HEARTS, SPADES, DIAMONDS}

const WIDTH := 128
const HEIGHT := 178
const RANKS_PER_SUIT := 13
const DECK_SIZE := 52

const FRONT_SHEET: Texture2D = preload("res://asset/sprite/ui/playing_card/PlayingCards128x178.png")
const BACK_SHEET: Texture2D = preload("res://asset/sprite/ui/playing_card/CardBacks128x178.png")

const RANK_NAMES := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const SUIT_NAMES := ["Clubs", "Hearts", "Spades", "Diamonds"]


static func suit_of(card: int) -> int:
	return card / RANKS_PER_SUIT


static func rank_of(card: int) -> int:
	return card % RANKS_PER_SUIT


static func name_of(card: int) -> String:
	return "%s of %s" % [RANK_NAMES[rank_of(card)], SUIT_NAMES[suit_of(card)]]


## Front face of a card, carved out of the shared sheet at draw time.
static func front_texture(card: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = FRONT_SHEET
	tex.region = Rect2(rank_of(card) * WIDTH, suit_of(card) * HEIGHT, WIDTH, HEIGHT)
	return tex


## Back face. The back sheet is 4x1, so `style` picks one of the four designs.
static func back_texture(style: int = 0) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = BACK_SHEET
	tex.region = Rect2(style * WIDTH, 0, WIDTH, HEIGHT)
	return tex


static func new_shuffled_deck(deck_count: int = 1) -> Array[int]:
	var deck: Array[int] = []
	for _d in deck_count:
		for card in DECK_SIZE:
			deck.append(card)
	deck.shuffle()
	return deck


## Aces count as 11 here; hand_value() demotes them when the hand would bust.
static func blackjack_value(card: int) -> int:
	var rank := rank_of(card)
	if rank == 0:
		return 11
	return min(rank + 1, 10)


static func hand_value(hand: Array[int]) -> int:
	var total := 0
	var aces := 0
	for card in hand:
		total += blackjack_value(card)
		if rank_of(card) == 0:
			aces += 1
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total


static func is_natural_blackjack(hand: Array[int]) -> bool:
	return hand.size() == 2 and hand_value(hand) == 21
