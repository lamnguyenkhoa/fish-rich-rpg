extends TextureRect

@export var image_list: Array[CompressedTexture2D] = []
@export var drop_rate: Array[float] = [0.795, 0.18, 0.025]

var rarity_index = 0

func _ready() -> void:
	var total: float = 0.0
	for rate in drop_rate:
		total += rate
	var roll: float = randf() * total
	var cumulative := 0.0
	for i in drop_rate.size():
		cumulative += drop_rate[i]
		if roll < cumulative:
			texture = image_list[i]
			rarity_index = i
			_fade_in()
			_play_rarity_effect()
			return
	texture = image_list.back()
	_fade_in()

func _fade_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _play_rarity_effect() -> void:
	if rarity_index == 1:
		_flash(2)
	elif rarity_index == 2:
		_flash(3)
		_grow_and_shrink()

func _flash(times: int) -> void:
	var tween := create_tween()
	tween.set_loops(times)
	tween.tween_method(_set_flash_brightness, 1.0, 2.5, 0.12)
	tween.tween_method(_set_flash_brightness, 2.5, 1.0, 0.12)

func _set_flash_brightness(brightness: float) -> void:
	modulate.r = brightness
	modulate.g = brightness
	modulate.b = brightness

func _grow_and_shrink() -> void:
	pivot_offset = size / 2.0
	var original_scale := scale
	var tween := create_tween()
	tween.tween_property(self, "scale", original_scale * 1.4, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
