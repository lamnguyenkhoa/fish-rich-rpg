extends Node2D
class_name MapManager

@export var player_apartment: CompanyBuilding
@export var prison: CompanyBuilding
@export var work_ui: Control
@export var endgame_ui: EndgameUI

func _ready():
	GameManager.map_manager = self
