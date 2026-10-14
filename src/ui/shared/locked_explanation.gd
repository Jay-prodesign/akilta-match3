extends RefCounted

## Shared sealed-destination explanation for visible-but-unavailable product
## surfaces. It must never invent unlock dates, prices, rewards or live-service
## availability.

const LockedExplanationScene = preload("res://src/ui/shared/locked_explanation.tscn")
const ProductionChrome = preload("res://src/ui/theme/production_chrome.gd")
const PieceAssetLoader = preload("res://src/match3/presentation/piece_asset_loader.gd")
const SEALED_BADGE_PATH := "res://assets/blockers/ch01_blocker_wax_seal_intact_v01.webp"

static func present(owner: Control, title_text: String, reason_text: String, requirement_text: String, close_text: String) -> Control:
	if owner == null:
		return null
	var existing := owner.get_node_or_null("LockedExplanation")
	if existing != null:
		# A new sealed destination can be inspected before the previous exit tween
		# has fully elapsed. Remove the old node synchronously so the authored
		# modal keeps its canonical name and the new truth is immediately queryable.
		owner.remove_child(existing)
		existing.queue_free()

	var overlay := LockedExplanationScene.instantiate() as Control
	if overlay == null:
		push_error("Authored LockedExplanation modal could not instantiate.")
		return null
	overlay.set_meta("sealed_truth", true)
	overlay.set_meta("no_fake_unlock", true)
	owner.add_child(overlay)
	ProductionChrome.apply_primary(overlay.get_node_or_null("LockedPanel") as Control)

	var panel := overlay.get_node_or_null("LockedPanel") as PanelContainer
	var seal := overlay.get_node_or_null("LockedPanel/Content/Seal") as TextureRect
	var title := overlay.get_node_or_null("LockedPanel/Content/Title") as Label
	var reason := overlay.get_node_or_null("LockedPanel/Content/Reason") as Label
	var requirement := overlay.get_node_or_null("LockedPanel/Content/Requirement") as Label
	var close := overlay.get_node_or_null("LockedPanel/Content/Close") as Button
	if seal != null:
		seal.texture = PieceAssetLoader.ornament(SEALED_BADGE_PATH)
	if title != null:
		title.text = title_text
	if reason != null:
		reason.text = reason_text
	if requirement != null:
		requirement.text = requirement_text
	if close != null:
		close.text = close_text
		close.pressed.connect(func():
			if not is_instance_valid(overlay):
				return
			close.disabled = true
			var exit_tween := overlay.create_tween()
			exit_tween.set_parallel(true)
			exit_tween.tween_property(overlay, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if panel != null:
				exit_tween.tween_property(panel, "position:y", panel.position.y + 18.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			exit_tween.finished.connect(func():
				if is_instance_valid(overlay):
					overlay.queue_free()
			)
		)
	overlay.modulate.a = 0.0
	if panel != null:
		panel.position.y += 26.0
	var entrance_tween := overlay.create_tween()
	entrance_tween.set_parallel(true)
	entrance_tween.tween_property(overlay, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if panel != null:
		entrance_tween.tween_property(panel, "position:y", panel.position.y - 26.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	overlay.set_meta("entrance_choreography", true)
	overlay.set_meta("exit_choreography", true)
	return overlay

static func contract(overlay: Control) -> Dictionary:
	if overlay == null:
		return {"open": false}
	var seal: TextureRect = overlay.get_node_or_null("LockedPanel/Content/Seal") as TextureRect
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
		"authored_scene": seal != null and seal.texture != null and title != null and reason != null and requirement != null and close != null,
		"touch_target_ok": close != null and close.custom_minimum_size.y >= 56.0,
		"entrance_choreography": bool(overlay.get_meta("entrance_choreography", false)),
		"exit_choreography": bool(overlay.get_meta("exit_choreography", false)),
		"runtime_ui_factory": false,
	}
