extends SceneTree

const Navigation = preload("res://src/app/navigation_controller.gd")
const Settings = preload("res://src/settings/user_settings.gd")
const BoardView = preload("res://src/match3/presentation/board_view.gd")
const PieceAssets = preload("res://src/match3/presentation/piece_asset_loader.gd")
const PieceVisuals = preload("res://src/match3/presentation/piece_visuals.gd")
const SplashScene = preload("res://src/ui/splash/splash_screen.tscn")
const TEST_SETTINGS := "user://match3_first_party_shell_settings.json"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var nav = Navigation.new()
	_expect(nav.route_name() == "BOOT", "navigation starts at BOOT")
	_expect(nav.go(Navigation.Route.HOUSE), "BOOT -> HOUSE must be legal")
	_expect(not nav.go(Navigation.Route.GAMEPLAY), "HOUSE cannot bypass map/prestart")
	_expect(nav.open_settings(), "settings must open from HOUSE")
	_expect(nav.back() == "close_settings", "back closes House settings first")
	_expect(nav.go(Navigation.Route.MAP), "HOUSE -> MAP must be legal")
	_expect(nav.go(Navigation.Route.PRESTART, {"level": 1}), "MAP -> PRESTART must be legal")
	_expect(nav.go(Navigation.Route.GAMEPLAY, {"level": 1}), "PRESTART -> GAMEPLAY must be legal")
	_expect(nav.open_settings(), "paused gameplay must support the shared settings overlay")
	_expect(nav.back() == "close_settings" and nav.route_name() == "GAMEPLAY", "closing gameplay settings must preserve gameplay route")
	_expect(nav.go(Navigation.Route.HOUSE, {"reason": "win"}), "GAMEPLAY -> HOUSE must be legal")

	_cleanup()
	var settings = Settings.new()
	var state: Dictionary = settings.load_settings(TEST_SETTINGS)
	_expect(bool(state.get("haptics_enabled", false)), "haptics default on")
	_expect(not bool(state.get("reduced_motion", true)), "reduced motion default off")
	_expect(settings.set_value("reduced_motion", true), "reduced motion must persist")
	_expect(settings.set_value("high_contrast", true), "high contrast must persist")
	var reloaded = Settings.new()
	reloaded.load_settings(TEST_SETTINGS)
	_expect(bool(reloaded.get_value("reduced_motion", false)), "reduced motion must survive reload")
	_expect(bool(reloaded.get_value("high_contrast", false)), "high contrast must survive reload")

	var board = BoardView.new()
	board.apply_presentation_settings(reloaded.get_presentation_state())
	var presentation: Dictionary = board.presentation_settings_contract()
	_expect(bool(presentation.get("reduced_motion", false)), "reduced motion must reach gameplay presentation")
	_expect(bool(presentation.get("high_contrast", false)), "high contrast must reach gameplay presentation")
	_expect(bool(board.motion_contract().get("reduced_motion_supported", false)), "board motion contract must declare reduced-motion support")
	board.free()
	var canonical_piece_paths := {
		"moon": "res://assets/pieces/moon_sigil.svg",
		"rose": "res://assets/pieces/thorn_rose.svg",
		"moth": "res://assets/pieces/luna_moth.svg",
		"key": "res://assets/pieces/curio_key.svg",
		"leaf": "res://assets/pieces/night_ivy.svg",
	}
	for family in canonical_piece_paths:
		_expect(String(PieceAssets.PATHS.get(family, "")) == String(canonical_piece_paths[family]), "piece family identity must stay invariant: %s" % family)
		for profile in PieceAssets.PROFILE_PATHS:
			var profile_paths: Dictionary = PieceAssets.PROFILE_PATHS[profile]
			_expect(String(profile_paths.get(family, "")) == String(canonical_piece_paths[family]), "piece family identity must stay invariant across level profiles: %s / %s" % [profile, family])
	var moth_visual: Dictionary = PieceVisuals.descriptor("moth")
	var key_visual: Dictionary = PieceVisuals.descriptor("key")
	var ivy_visual: Dictionary = PieceVisuals.descriptor("leaf")
	_expect(String(moth_visual.get("display_name", "")) == "Luna Moth" and String(moth_visual.get("silhouette", "")) == "luna_moth", "piece semantics must describe Luna Moth")
	_expect(String(key_visual.get("display_name", "")) == "Curio Key" and String(key_visual.get("silhouette", "")) == "antique_key", "piece semantics must describe Curio Key")
	_expect(String(ivy_visual.get("display_name", "")) == "Night Ivy" and String(ivy_visual.get("silhouette", "")) == "ivy_leaf", "piece semantics must describe Night Ivy")
	_expect(String(PieceAssets.RASTER_OVERRIDES.get(PieceAssets.PATHS["key"], "")).ends_with("curio_key.png"), "Curio Key must use the readable raster override while the material candidate is too dark")
	var splash = SplashScene.instantiate()
	root.add_child(splash)
	await process_frame
	var splash_art: TextureRect = splash.get_node_or_null("SplashWorldArt")
	_expect(splash_art != null and splash_art.texture != null, "splash must render authored raster House-world art")
	_expect(splash.get_node_or_null("Layout/Enter") != null, "splash must provide a working enter control")
	splash.queue_free()
	await process_frame
	_cleanup()
	_finish()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("TEST_PASS: AKILTA first-party shell contracts")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
