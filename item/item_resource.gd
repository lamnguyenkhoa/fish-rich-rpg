extends Resource
class_name ItemResource

@export var item_id: EnumAutoload.ItemId
@export var name: String
@export_multiline var description: String
@export var type: EnumAutoload.ItemType

@export var recover_hp: int = 0
@export var recover_sp: int = 0
@export var recover_hp_percentage: int = 0
@export var recover_sp_percentage: int = 0
@export var gain_stat: Array[int] = [0, 0, 0, 0, 0]
@export var special_case: String = ""