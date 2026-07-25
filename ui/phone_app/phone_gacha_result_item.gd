extends TextureRect

@export var image_list: Array[CompressedTexture2D] = []
@export var drop_rate: Array[float] = [0.795, 0.18, 0.025]

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
			_fade_in()
			return
	texture = image_list.back()
	_fade_in()

func _fade_in() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
