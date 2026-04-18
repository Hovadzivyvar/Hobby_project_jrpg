extends Node
class_name StatusManager

signal status_applied(target: CharacterData, status: StatusEffect)
signal status_expired(target: CharacterData, status: StatusEffect)
signal poison_damage(block: CharacterBlock, damage: int)
signal party_fully_petrified
signal confuse_action(block: CharacterBlock)
signal block_status_changed(block: CharacterBlock)

var blocks: Array[CharacterBlock] = []

func setup(p_blocks: Array[CharacterBlock]) -> void:
	blocks = p_blocks

func try_apply_status(
		target: CharacterData,
		status_type: StatusEffect.Type,
		duration: int,
		potency: float = 1.0) -> bool:
	# Check resistance
	var resistance = target.get_status_resistance(status_type)
	var roll = randf()
	print("APPLYING: ", StatusEffect.Type.keys()[status_type], 
			  " to ", target.char_name,
					  " current statuses: ", target.active_statuses.size())
					
	if roll < resistance:
		print(target.char_name, " resisted ", StatusEffect.Type.keys()[status_type])
		return false

	# Petrified units immune to new statuses
	if has_status(target, StatusEffect.Type.PETRIFY) and \
			status_type != StatusEffect.Type.PETRIFY:
		return false

	# Remove existing same type
	remove_status(target, status_type)

	# Apply new status
	var effect = StatusEffect.create(status_type, duration, potency)
	target.active_statuses.append(effect)
	for block in blocks:
		if block.character_data == target:
			block_status_changed.emit(block)
			break

	print(target.char_name, " is now ", effect.get_type_string())
	status_applied.emit(target, effect)
	return true

func remove_status(target: CharacterData, status_type: StatusEffect.Type) -> void:
	for i in range(target.active_statuses.size() - 1, -1, -1):
		if target.active_statuses[i].type == status_type:
			target.active_statuses.remove_at(i)

func has_status(target: CharacterData, status_type: StatusEffect.Type) -> bool:
	for status in target.active_statuses:
		if status.type == status_type:
			return true
	return false

func tick_all_statuses() -> void:
	for block in blocks:
		if not block.character_data.is_alive:
			continue
		_tick_character_statuses(block)
	_check_full_petrify()

func _tick_character_statuses(block: CharacterBlock) -> void:
	var to_remove: Array[StatusEffect] = []
	print("TICKING statuses for: ", block.character_data.char_name,
			  " count: ", block.character_data.active_statuses.size())
			
	for status in block.character_data.active_statuses:
		# Apply status effect
		match status.type:
			StatusEffect.Type.POISON:
				var damage = int(block.character_data.max_hp * 0.1 * status.potency)
				block.character_data.current_hp -= damage
				block.character_data.current_hp = max(1, block.character_data.current_hp)
				poison_damage.emit(block, damage)
				print(block.character_data.char_name, " takes ", damage, " poison damage")
			StatusEffect.Type.CONFUSE:
				confuse_action.emit(block)
		# Tick duration
		print("TICKING: ", status.get_type_string(), "
			 current: ", status.turns_remaining)
		status.turns_remaining -= 1
		print("RESULT: ", status.turns_remaining) 
		if status.turns_remaining <= 0:
			to_remove.append(status)
			block_status_changed.emit(block)
			print(block.character_data.char_name, " recovered from ", status.get_type_string())
			status_expired.emit(block.character_data, status)
	for status in to_remove:
		block.character_data.active_statuses.erase(status)

func _check_full_petrify() -> void:
	var all_petrified = true
	for block in blocks:
		if block.character_data.is_alive and \
				not has_status(block.character_data, StatusEffect.Type.PETRIFY):
			all_petrified = false
			break
	if all_petrified:
		party_fully_petrified.emit()

func can_act(target: CharacterData) -> bool:
	return not has_status(target, StatusEffect.Type.SLEEP) and \
		   not has_status(target, StatusEffect.Type.PARALYZE) and \
		   not has_status(target, StatusEffect.Type.PETRIFY) and \
		   not has_status(target, StatusEffect.Type.CONFUSE)

func can_use_magic(target: CharacterData) -> bool:
	return not has_status(target, StatusEffect.Type.SILENCE)

func is_petrified(target: CharacterData) -> bool:
	return has_status(target, StatusEffect.Type.PETRIFY)

func wake_from_sleep(target: CharacterData) -> void:
	if has_status(target, StatusEffect.Type.SLEEP):
		print("WAKE TRIGGERED FOR: ", target.char_name)
		print(get_stack())
		remove_status(target, StatusEffect.Type.SLEEP)
		print(target.char_name, " woke up!")

func apply_zombie_to_heal(heal: int, target: CharacterData) -> int:
	if has_status(target, StatusEffect.Type.ZOMBIE):
		return -heal  # healing becomes damage
	return heal

func apply_zombie_to_revive(target: CharacterData) -> bool:
	if has_status(target, StatusEffect.Type.ZOMBIE):
		target.current_hp = 0
		target.is_alive = false
		print(target.char_name, " zombie revive killed them!")
		return true
	return false

func remove_specific_statuses(
		target: CharacterData,
		status_types: Array) -> void:
	for status_type in status_types:
		if has_status(target, status_type):
			remove_status(target, status_type)
			print(target.char_name, " cured of ",
				StatusEffect.Type.keys()[status_type])
	# Notify block status changed
	for block in blocks:
		if block.character_data == target:
			block_status_changed.emit(block)
			break
