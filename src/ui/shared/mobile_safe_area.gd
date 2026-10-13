class_name Match3MobileSafeArea
extends RefCounted

const PRODUCT_NAV_CONTENT_RESERVE := 152.0

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

static func apply_content(screen: Control, content_path: NodePath = NodePath("Layout")) -> void:
	if screen == null:
		return
	var content := screen.get_node_or_null(content_path) as Control
	if content == null:
		return
	if not content.has_meta("mobile_safe_base_offsets"):
		content.set_meta("mobile_safe_base_offsets", Vector4(content.offset_left, content.offset_top, content.offset_right, content.offset_bottom))
	var base: Vector4 = content.get_meta("mobile_safe_base_offsets")
	var safe := current_insets(screen)
	var bottom_reserve := PRODUCT_NAV_CONTENT_RESERVE if bool(content.get_meta("product_nav_inset_applied", false)) else 0.0
	content.offset_left = base.x + safe.x
	content.offset_top = base.y + safe.y
	content.offset_right = base.z - safe.z
	content.offset_bottom = base.w - safe.w - bottom_reserve
