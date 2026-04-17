extends Resource
class_name ItemData

enum ItemType { HEALING_HP, HEALING_MP, OFFENSIVE, BUFF, REVIVE }
enum TargetType { SINGLE_ALLY, SINGLE_ENEMY, ALL_ALLIES, ALL_ENEMIES }

@export var item_name: String = "Item"
@export var quantity: int = 1
@export var power: int = 0
@export var item_type: ItemType = ItemType.HEALING_HP
@export var target_type: TargetType = TargetType.SINGLE_ALLY
@export var description: String = ""
# For healing items: flat amount or percentage
@export var heal_amount: int = 0
@export var heal_percent: float = 0.0
