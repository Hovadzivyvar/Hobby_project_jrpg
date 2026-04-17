extends Resource
class_name StatusEffect

enum Type {
	POISON,
	BLIND,
	SLEEP,
	SILENCE,
	PARALYZE,
	CONFUSE,
	PETRIFY,
	ZOMBIE
}

@export var type: Type = Type.POISON
@export var duration: int = 3
@export var potency: float = 1.0  # multiplier for effects like poison damage

var turns_remaining: int = 0

static func create(p_type: Type, p_duration: int, p_potency: float = 1.0) -> StatusEffect:
	var effect = StatusEffect.new()
	effect.type = p_type
	effect.duration = p_duration
	effect.potency = p_potency
	effect.turns_remaining = p_duration
	return effect

func get_type_string() -> String:
	match type:
		Type.POISON:    return "Poison"
		Type.BLIND:     return "Blind"
		Type.SLEEP:     return "Sleep"
		Type.SILENCE:   return "Silence"
		Type.PARALYZE:  return "Paralyze"
		Type.CONFUSE:   return "Confuse"
		Type.PETRIFY:   return "Petrify"
		Type.ZOMBIE:    return "Zombie"
		_:              return "Unknown"
