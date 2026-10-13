extends RefCounted

## Shared sealed-destination explanation for visible-but-unavailable product
## surfaces. It must never invent unlock dates, prices, rewards or live-service
## availability.

const LockedExplanationScene = preload("res://src/ui/shared/locked_explanation.tscn")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")

static func present(owner: Control, title_text: String, reason_text: String, requirement_text: String, close_text: String) -> Control:
	if owner == null:
		return null
	var existing := owner.get_node_or_null("LockedExplanation")
	if existing != null:
		existing.queue_free()

	var overlay := LockedExplanationScene.instantiate() as Control
	if overlay == null:
		push_error("Authored LockedExplanation modal could not instantiate.")
		return null
	overlay.set_meta("sealed_truth", true)
	overlay.set_meta("no_fake_unlock", true)
	owner.add_child(overlay)
	ProductionChrome.apply_primary(overlay.get_node_or_null("LockedPanel") as Control)

	var title := overlay.get_node_or_null("LockedPanel/Content/Title") as Label
	var reason := overlay.get_node_or_null("LockedPanel/Content/Reason") as Label
	var requirement := overlay.get_node_or_null("LockedPanel/Content/Requirement") as Label
	var close := overlay.get_node_or_null("LockedPanel/Content/Close") as Button
	if title != null:
		title.text = title_text
	if reason != null:
		reason.text = reason_text
	if requirement != null:
		requirement.text = requirement_text
	if close != null:
		close.text = close_text
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
	var close: Button = overlay.get_node_or_null("LockedPanel/Content/Close") as Button
	return {
		"open": true,
		"sealed_truth": bool(overlay.get_meta("sealed_truth", false)),
		"no_fake_unlock": bool(overlay.get_meta("no_fake_unlock", false)),
		"title": title.text if title != null else "",
		"reason": reason.text if reason != null else "",
		"requirement": requirement.text if requirement != null else "",
		"authored_scene": title != null and reason != null and requirement != null and close != null,
		"touch_target_ok": close != null and close.custom_minimum_size.y >= 56.0,
		"runtime_ui_factory": false,
	}
