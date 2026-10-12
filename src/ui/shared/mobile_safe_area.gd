class_name Match3MobileSafeArea
extends RefCounted

static func insets_for_geometry(viewport_size: Vector2, display_size: Vector2i, safe_rect: Rect2i) -> Vector4:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or display_size.x <= 0 or display_size.y <= 0:
		return Vector4.ZERO
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_x := viewport_size.x / float(display_size.x)
	var scale_y := viewport_size.y / float(display_size.y)
	return Vector4(
		maxf(0.0, float(safe_rect.position.x) * scale_x),
		maxf(0.0, float(safe_rect.position.y) * scale_y),
		maxf(0.0, float(display_size.x - safe_rect.end.x) * scale_x),
		maxf(0.0, float(display_size.y - safe_rect.end.y) * scale_y)
	)

static func current_insets(screen: Control) -> Vector4:
	if screen == null or OS.get_name() not in ["Android", "iOS"]:
		return Vector4.ZERO
	return insets_for_geometry(screen.size, DisplayServer.window_get_size(), DisplayServer.get_display_safe_area())
