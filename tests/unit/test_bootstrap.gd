extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var version := Engine.get_version_info()

	if int(version.get("major", -1)) != 4 or int(version.get("minor", -1)) != 7 or int(version.get("patch", -1)) != 2:
		failures.append("Expected Godot 4.7.2, got %s" % str(version))

	var bootstrap_path := "res://src/app/app_bootstrap.gd"
	if not ResourceLoader.exists(bootstrap_path):
		failures.append("AppBootstrap production script is missing")
	else:
		var bootstrap_script := load(bootstrap_path)
		if bootstrap_script == null:
			failures.append("AppBootstrap production script could not be loaded")
		else:
			var bootstrap = bootstrap_script.new()
			if str(bootstrap.get("environment")) != "development":
				failures.append("AppBootstrap must default to development environment")
			var gameplay_args := PackedStringArray(["--cat-coven-native-review-route=gameplay"])
			if bootstrap.native_runtime_review_route_from_args(gameplay_args) != "gameplay":
				failures.append("Native review route parser must accept the workflow-only gameplay route")
			var house_args := PackedStringArray(["--other-flag", "--cat-coven-native-review-route=HOUSE"])
			if bootstrap.native_runtime_review_route_from_args(house_args) != "house":
				failures.append("Native review route parser must normalize the workflow-only House route")
			var unsupported_args := PackedStringArray(["--cat-coven-native-review-route=shop"])
			if bootstrap.native_runtime_review_route_from_args(unsupported_args) != "":
				failures.append("Native review route parser must reject unsupported deep routes")
			var normal_args := PackedStringArray(["--some-player-argument"])
			if bootstrap.native_runtime_review_route_from_args(normal_args) != "":
				failures.append("Normal launches must not opt into native review routing")
			bootstrap.free()

	if failures.is_empty():
		print("TEST_PASS: bootstrap contract")
		quit(0)
		return

	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
