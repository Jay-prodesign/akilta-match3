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

	if failures.is_empty():
		print("TEST_PASS: bootstrap contract")
		quit(0)
		return

	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)
