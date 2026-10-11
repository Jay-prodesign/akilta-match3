class_name Match3WaxSeal
extends RefCounted

static func apply_damage(board, cleared_cells: Array[Vector2i]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var positions: Array[Vector2i] = []
	for raw_pos in board.blockers.keys():
		positions.append(raw_pos)
	positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)

	for blocker_pos in positions:
		var hit := false
		for cleared_pos in cleared_cells:
			var delta := (blocker_pos - cleared_pos).abs()
			if blocker_pos == cleared_pos or delta.x + delta.y == 1:
				hit = true
				break
		if not hit:
			continue

		var blocker: Dictionary = board.get_blocker(blocker_pos)
		if String(blocker.get("type", "")) != "wax_seal":
			continue
		var old_hp := int(blocker.get("hp", 1))
		var new_hp := old_hp - 1
		board.set_blocker_hp(blocker_pos, new_hp)
		events.append({
			"type": "blocker_cleared" if new_hp <= 0 else "blocker_damaged",
			"at": "%d,%d" % [blocker_pos.x, blocker_pos.y],
			"old_hp": old_hp,
			"new_hp": max(0, new_hp)
		})
	return events
