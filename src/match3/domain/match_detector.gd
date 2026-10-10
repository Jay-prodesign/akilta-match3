class_name Match3MatchDetector
extends RefCounted

static func find_match_cells(board) -> Array[Vector2i]:
	var matched: Dictionary = {}

	for y in range(board.height):
		var run_value := ""
		var run_start := 0
		var run_length := 0
		for x in range(board.width + 1):
			var value := ""
			if x < board.width:
				value = board.get_cell(Vector2i(x, y))
			if value != "" and value == run_value:
				run_length += 1
			else:
				if run_value != "" and run_length >= 3:
					for rx in range(run_start, run_start + run_length):
						matched[Vector2i(rx, y)] = true
				run_value = value
				run_start = x
				run_length = 1 if value != "" else 0

	for x in range(board.width):
		var run_value := ""
		var run_start := 0
		var run_length := 0
		for y in range(board.height + 1):
			var value := ""
			if y < board.height:
				value = board.get_cell(Vector2i(x, y))
			if value != "" and value == run_value:
				run_length += 1
			else:
				if run_value != "" and run_length >= 3:
					for ry in range(run_start, run_start + run_length):
						matched[Vector2i(x, ry)] = true
				run_value = value
				run_start = y
				run_length = 1 if value != "" else 0

	var result: Array[Vector2i] = []
	for pos in matched.keys():
		result.append(pos)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return result
