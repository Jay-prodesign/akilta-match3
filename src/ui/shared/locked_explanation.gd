extends RefCounted

## Shared sealed-destination explanation for visible-but-unavailable product
## surfaces. It must never invent unlock dates, prices, rewards or live-service
## availability.

static func present(owner: Control, title_text: String, reason_text: String, requirement_text: String, close_text: String) -> Control:
	if owner == null:
		return null
	var existing := owner.get_node_or_null("LockedExplanation")
	if existing != null:
		existing.queue_free()

	var overlay := Control.new()
	overlay.name = "LockedExplanation"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 180
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_meta("sealed_truth", true)
	overlay.set_meta("no_fake_unlock", true)
	owner.add_child(overlay)

	var veil := ColorRect.new()
	veil.name = "Dim"
	veil.color = Color(0.015, 0.01, 0.025, 0.74)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)

	var panel := PanelContainer.new()
	panel.name = "LockedPanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.30
	panel.anchor_bottom = 0.66
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("#0D0912", 0.985)
	shell.border_color = Color("#A68CAB", 0.82)
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(18)
	shell.content_margin_left = 24
	shell.content_margin_right = 24
	shell.content_margin_top = 20
	shell.content_margin_bottom = 20
	shell.shadow_color = Color(0, 0, 0, 0.68)
	shell.shadow_size = 18
	panel.add_theme_stylebox_override("panel", shell)
	overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var state := Label.new()
	state.name = "State"
	state.text = "SEALED"
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_color_override("font_color", Color("#D5AD70"))
	state.add_theme_font_size_override("font_size", 20)
	content.add_child(state)

	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color("#FFF0D8"))
	title.add_theme_font_size_override("font_size", 34)
	content.add_child(title)

	var reason := Label.new()
	reason.name = "Reason"
	reason.text = reason_text
	reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason.add_theme_color_override("font_color", Color("#E0D1D8"))
	reason.add_theme_font_size_override("font_size", 21)
	content.add_child(reason)

	var requirement := Label.new()
	requirement.name = "Requirement"
	requirement.text = requirement_text
	requirement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement.add_theme_color_override("font_color", Color("#BFA5D8"))
	requirement.add_theme_font_size_override("font_size", 19)
	content.add_child(requirement)

	var close := Button.new()
	close.name = "Close"
	close.text = close_text
	close.custom_minimum_size = Vector2(0, 62)
	close.add_theme_font_size_override("font_size", 21)
	var close_box := StyleBoxFlat.new()
	close_box.bg_color = Color("#35213B")
	close_box.border_color = Color("#D5AD70")
	close_box.set_border_width_all(2)
	close_box.set_corner_radius_all(10)
	var close_hover := close_box.duplicate() as StyleBoxFlat
	close_hover.bg_color = Color("#56305A")
	close.add_theme_stylebox_override("normal", close_box)
	close.add_theme_stylebox_override("hover", close_hover)
	close.add_theme_stylebox_override("pressed", close_hover)
	close.add_theme_stylebox_override("focus", close_hover)
	close.add_theme_color_override("font_color", Color("#FFF0D8"))
	content.add_child(close)
	close.pressed.connect(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	return overlay

static func contract(overlay: Control) -> Dictionary:
	if overlay == null:
		return {"open": false}
	var title: Label = overlay.get_node_or_null("LockedPanel/Content/Title") as Label
	var reason: Label = overlay.get_node_or_null("LockedPanel/Content/Reason") as Label
	var requirement: Label = overlay.get_node_or_null("LockedPanel/Content/Requirement") as Label
	return {
		"open": true,
		"sealed_truth": bool(overlay.get_meta("sealed_truth", false)),
		"no_fake_unlock": bool(overlay.get_meta("no_fake_unlock", false)),
		"title": title.text if title != null else "",
		"reason": reason.text if reason != null else "",
		"requirement": requirement.text if requirement != null else "",
	}
