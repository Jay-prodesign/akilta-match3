extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("TEST_RUNNER: missing test script argument")
		quit(2)
		return

	var test_path := String(args[0])
	if not ResourceLoader.exists(test_path):
		push_error("TEST_RUNNER: test script not found: %s" % test_path)
		quit(2)
		return

	var test_script := load(test_path)
	if test_script == null:
		push_error("TEST_RUNNER: could not load: %s" % test_path)
		quit(2)
		return

	var test_case = test_script.new()
	if not test_case.has_method("run"):
		push_error("TEST_RUNNER: test script must implement run() -> Array[String]")
		quit(2)
		return

	var failures: Array = test_case.run()
	if failures.is_empty():
		print("TEST_PASS: %s" % test_path)
		quit(0)
		return

	for failure in failures:
		push_error("TEST_FAIL: %s" % String(failure))
	quit(1)
