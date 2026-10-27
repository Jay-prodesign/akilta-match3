extends SceneTree

const HEX := "0123456789abcdef"
const POPCOUNT := [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4]
const SAMPLE_COLUMNS := 16
const SAMPLE_ROWS := 16
const EXPECTED_SIZE := Vector2i(540, 960)

# Coarse composition fingerprints captured from the latest visually reviewed
# product-board baseline. These do not replace human visual review: they stop
# accidental screen-family drift (missing bars, changed proportions, collapsed
# cards, oversized overlays) from passing merely because a PNG exists.
const BASELINES := {
	"golden-00-splash.png": {"hash": "a10d511d85171b4da54624db50f548e2c1f545c5a4072a8dc5ab3546228c340c", "max_distance": 8},
	"golden-01-house-dormant.png": {"hash": "08012cd333596a254a769a9aa336da13a72452b554697192b581808592b51480", "max_distance": 8},
	"golden-02-chapter-route.png": {"hash": "08010000b555455a67356555cb37192a564af1d5a6d76caf8c8f0092ab3504c1", "max_distance": 8},
	"golden-03-prestart.png": {"hash": "6aab3494569449952d64ad2b6182908565138005d0f9752d2ee78a3ba48a5365", "max_distance": 8},
	"golden-04-gameplay.png": {"hash": "8c255159c59800012aad2b2b4a956ab36ea10281aa092aad0434248be83565b9", "max_distance": 10},
	"golden-05-win-reward.png": {"hash": "88255119c0080299400509a7100510c3014502050005600500c4293be8356538", "max_distance": 10},
	"golden-06-restoration.png": {"hash": "6d561db92b2bcc889554cb12a72ecb4a1439cbd2c658513b753a25d9b951995d", "max_distance": 28},
	"progression-final-reliquary.png": {"hash": "08014a2d551a4f37ab0d256b154e4141252035155501251141033544270c0681", "max_distance": 16},
	"progression-final-weekly-missions.png": {"hash": "0801091d551b85448d463550144a50894124000300010140800100000000070b", "max_distance": 8},
	"progression-final-events.png": {"hash": "08011a0d2b4d527249d936515ca65e335c6b4a4bd485249756833544270c048d", "max_distance": 10},
	"progression-final-shop.png": {"hash": "88015ea7142132a00932ac735e432819b12e5471d51aaba1890690c327ab0481", "max_distance": 8},
	"progression-final-profile.png": {"hash": "8801480000010a2930030c21000140016829000121098140890690c327ab0481", "max_distance": 8},
	"progression-final-settings.png": {"hash": "39e7800180808002900880008000800c80200001551aaba1890690c327ab62aa", "max_distance": 8},
	"chapters-00-first-wing.png": {"hash": "0901ca8d2b09542dad667551b44a54ad40245d148003640456833544270c04c1", "max_distance": 8},
}

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for filename in BASELINES:
		var path := "res://artifacts/%s" % filename
		var image := Image.new()
		var error := image.load(path)
		if error != OK:
			failures.append("%s is missing or unreadable" % filename)
			continue
		var size := Vector2i(image.get_width(), image.get_height())
		if size != EXPECTED_SIZE:
			failures.append("%s changed render size from %s to %s" % [filename, EXPECTED_SIZE, size])
			continue
		var actual := _sample_hash(image)
		var expected := String(BASELINES[filename]["hash"])
		var max_distance := int(BASELINES[filename]["max_distance"])
		var distance := _hamming_hex(actual, expected)
		if distance > max_distance:
			failures.append("%s composition drifted: distance %d > %d" % [filename, distance, max_distance])

	if failures.is_empty():
		print("VISUAL_PARITY_PASS: product-board composition regression gate")
		quit(0)
		return
	for failure in failures:
		printerr("VISUAL_PARITY_FAIL: %s" % failure)
	quit(1)

func _sample_hash(image: Image) -> String:
	var bits: Array[int] = []
	var width := image.get_width()
	var height := image.get_height()
	for row in range(SAMPLE_ROWS):
		var y := mini(height - 1, int((float(row) + 0.5) * float(height) / float(SAMPLE_ROWS)))
		var values: Array[int] = []
		for sample in range(SAMPLE_COLUMNS + 1):
			var x := mini(width - 1, int((float(sample) + 0.5) * float(width) / float(SAMPLE_COLUMNS + 1)))
			var color := image.get_pixel(x, y)
			var red := int(round(color.r * 255.0))
			var green := int(round(color.g * 255.0))
			var blue := int(round(color.b * 255.0))
			values.append(int((299 * red + 587 * green + 114 * blue) / 1000))
		for column in range(SAMPLE_COLUMNS):
			bits.append(1 if values[column] > values[column + 1] else 0)

	var result := ""
	for offset in range(0, bits.size(), 4):
		var nibble := 0
		for bit_index in range(4):
			nibble = (nibble << 1) | bits[offset + bit_index]
		result += HEX.substr(nibble, 1)
	return result

func _hamming_hex(actual: String, expected: String) -> int:
	if actual.length() != expected.length():
		return 9999
	var distance := 0
	for index in range(actual.length()):
		var left := HEX.find(actual.substr(index, 1))
		var right := HEX.find(expected.substr(index, 1))
		if left < 0 or right < 0:
			return 9999
		distance += POPCOUNT[left ^ right]
	return distance
