extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var project := ConfigFile.new()
	_expect(project.load("res://project.godot") == OK, "project.godot must parse")
	_expect(String(project.get_value("application", "config/name", "")) == "Cat & Coven", "native product identity must be Cat & Coven")
	_expect(String(project.get_value("application", "config/icon", "")) == "res://assets/ui/cat_coven_launch.png", "native project icon must use first-party Cat art")
	_expect(bool(project.get_value("application", "boot_splash/show_image", false)), "native launch artwork must be enabled")
	_expect(String(project.get_value("application", "boot_splash/image", "")) == "res://assets/mobile/black_cat_launch.png", "native launch must use the valid first-party Cat PNG")
	_expect(int(project.get_value("display", "window/handheld/orientation", 0)) == 1, "mobile release must remain portrait")
	_expect(String(project.get_value("rendering", "renderer/rendering_method.mobile", "")) == "gl_compatibility", "mobile renderer must be explicit")
	_expect(bool(project.get_value("rendering", "textures/vram_compression/import_etc2_astc", false)), "mobile texture compression import must be enabled for native export")

	var presets := ConfigFile.new()
	_expect(presets.load("res://export_presets.cfg") == OK, "export_presets.cfg must parse")
	_expect(_preset_contract(presets, 1, "Android Release APK", "Android"), "Android release APK preset missing")
	_expect(_preset_contract(presets, 2, "Android Play AAB", "Android"), "Android Play AAB preset missing")
	_expect(_preset_contract(presets, 3, "iOS Xcode Project", "iOS"), "iOS Xcode project preset missing")
	_expect(String(presets.get_value("preset.1.options", "package/unique_name", "")) == "com.akilta.catandcoven", "Android package identity mismatch")
	_expect(String(presets.get_value("preset.2.options", "package/unique_name", "")) == "com.akilta.catandcoven", "Android AAB package identity mismatch")
	_expect(bool(presets.get_value("preset.2.options", "gradle_build/use_gradle_build", false)), "AAB preset must use Gradle")
	_expect(int(presets.get_value("preset.2.options", "gradle_build/export_format", 0)) == 1, "AAB preset must export bundle format")
	_expect(String(presets.get_value("preset.2.options", "gradle_build/target_sdk", "")) == "36", "Play release must target Android API 36")
	_expect(String(presets.get_value("preset.3.options", "application/bundle_identifier", "")) == "com.akilta.catandcoven", "iOS bundle identity mismatch")
	_expect(bool(presets.get_value("preset.3.options", "application/export_project_only", false)), "CI iOS path must export an unsigned Xcode project")
	_expect(int(presets.get_value("preset.3.options", "application/targeted_device_family", -1)) == 0, "iOS V1 target must be iPhone")
	_expect(String(presets.get_value("preset.3.options", "application/app_store_team_id", "")) == "__IOS_TEAM_ID__", "committed iOS preset must retain a non-secret Team ID placeholder")

	var raw := FileAccess.get_file_as_string("res://export_presets.cfg")
	_expect(raw.contains('exclude_filter="build/*,tests/*,tools/*,docs/*"'), "production mobile exports must exclude tests/tools/docs")
	_expect(not raw.contains("keystore/release_password"), "release signing password must not be committed")
	_expect(not raw.contains("provisioning_profile_uuid_release=\"") or raw.contains("provisioning_profile_uuid_release=\"\""), "iOS provisioning profile must not be committed")

	if failures.is_empty():
		print("TEST_PASS: native mobile release configuration contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _preset_contract(config: ConfigFile, index: int, expected_name: String, expected_platform: String) -> bool:
	var section := "preset.%d" % index
	return String(config.get_value(section, "name", "")) == expected_name and String(config.get_value(section, "platform", "")) == expected_platform

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
