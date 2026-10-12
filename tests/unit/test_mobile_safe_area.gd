extends SceneTree

const SafeArea = preload("res://src/ui/shared/mobile_safe_area.gd")
var failures: Array[String] = []

func _init() -> void:
	var iphone := SafeArea.insets_for_geometry(Vector2(1080, 1920), Vector2i(1179, 2556), Rect2i(0, 177, 1179, 2268))
	_expect(is_equal_approx(iphone.x, 0.0), "portrait safe area left inset")
	_expect(iphone.y > 120.0, "portrait top cutout must become a design-space inset")
	_expect(iphone.w > 70.0, "home indicator must become a design-space bottom inset")

	var full := SafeArea.insets_for_geometry(Vector2(1080, 1920), Vector2i(1080, 1920), Rect2i(0, 0, 1080, 1920))
	_expect(full == Vector4.ZERO, "full safe rect must produce zero insets")

	var invalid := SafeArea.insets_for_geometry(Vector2(1080, 1920), Vector2i.ZERO, Rect2i())
	_expect(invalid == Vector4.ZERO, "invalid display geometry must fail safe")

	if failures.is_empty():
		print("TEST_PASS: mobile safe-area geometry contract")
		quit(0)
		return
	for failure in failures:
		printerr("TEST_FAIL: %s" % failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
