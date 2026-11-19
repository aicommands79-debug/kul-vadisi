class_name RealmGen
extends RefCounted
## Üç boyutun haritalarını deterministik olarak üretir.
## Haritalar prosedürel ama "landmark" tabanlı: her boyutun kendi mağarası,
## yolu, odaları ve işaretçileri var. Böylece 64x44 gibi büyük haritalar
## elle karakter saymadan güvenilir şekilde kuruluyor.

const TILE := 16
const SOLID_CHARS := "#~T"
const MARKERS := "ABCNSUX12349@"


static func build(id: String) -> Dictionary:
	match id:
		"under":
			return _under()
		"sky":
			return _sky()
		_:
			return _valley()


# ------------------------------------------------------------------- boyutlar

static func _valley() -> Dictionary:
	var w := 64
	var h := 44
	var g := _new(w, h, ".")
	_border(g, "#")
	var rng := _rng(20240401)

	# gölet
	_blob(g, 48, 12, 9, 5, "~")
	# yollar
	_rect(g, 4, 18, 42, 4, "p")
	_rect(g, 13, 8, 4, 28, "p")
	# köy evleri
	_house(g, 4, 7, 8, 6)
	_house(g, 20, 7, 8, 6)
	# harabe
	_ruin(g, 34, 28, 11, 8)
	# ormanlar
	_cluster(g, rng, 6, 32, 9, "T", 0.5)
	_cluster(g, rng, 28, 6, 9, "T", 0.45)
	_cluster(g, rng, 58, 34, 7, "T", 0.5)
	_cluster(g, rng, 56, 4, 6, "T", 0.45)
	_cluster(g, rng, 26, 36, 7, "T", 0.4)
	_scatter(g, rng, ",", 0.05, ".")

	# hikâye işaretçileri
	_blob(g, 36, 7, 3, 2, ".")      # yer altı kapısı açıklığı
	_blob(g, 58, 22, 2, 2, ".")
	_put(g, 16, 20, "@")
	_put(g, 12, 17, "N")
	_put(g, 18, 21, "S")
	_put(g, 28, 14, "U")
	_put(g, 8, 21, "X")
	_put(g, 40, 33, "X")
	_put(g, 36, 6, "A")
	_put(g, 58, 22, "B")
	_put(g, 30, 24, "1")
	_put(g, 36, 20, "1")
	_put(g, 26, 28, "1")
	_put(g, 40, 24, "2")
	_put(g, 56, 28, "2")
	_put(g, 42, 30, "2")

	return _pack("valley", "Kül Vadisi", g, Vector2i(16, 20), {
		"#": "rock", "~": "water", ".": "grass", ",": "flower", "p": "dirt", "T": "grass",
	}, Color(0.09, 0.12, 0.1))


static func _under() -> Dictionary:
	var w := 56
	var h := 40
	var g := _new(w, h, "#")
	var rng := _rng(77123)

	# başlangıç odası
	_rect(g, 4, 26, 14, 9, ".")
	# doğu koridoru
	_rect(g, 17, 30, 12, 4, ".")
	# merkez mağara
	_blob(g, 34, 28, 11, 8, ".")
	# kuzey koridoru
	_rect(g, 30, 12, 4, 13, ".")
	# boss mağarası
	_blob(g, 30, 7, 15, 6, ".")
	# yan oda (sunağa giden)
	_rect(g, 46, 32, 7, 6, ".")
	_rect(g, 41, 34, 6, 2, ".")

	# lav havuzları
	_blob(g, 10, 33, 2, 2, "~")
	_put(g, 8, 32, ".")
	_put(g, 12, 34, ".")
	_blob(g, 38, 27, 3, 2, "~")
	# sütunlar + yosun
	_cluster(g, rng, 34, 28, 9, "#", 0.10, ".")
	_cluster(g, rng, 30, 7, 12, "#", 0.07, ".")
	_scatter(g, rng, ",", 0.09, ".")

	_put(g, 7, 30, "@")
	_put(g, 6, 34, "A")
	_put(g, 5, 27, "C")
	_put(g, 15, 32, "X")
	_put(g, 32, 34, "X")
	_put(g, 49, 35, "U")
	_put(g, 24, 31, "3")
	_put(g, 40, 30, "3")
	_put(g, 27, 34, "4")
	_put(g, 40, 24, "4")
	_put(g, 31, 18, "2")
	_put(g, 20, 32, "2")
	_put(g, 36, 33, "2")
	_put(g, 24, 9, "2")
	_put(g, 36, 8, "2")
	_put(g, 30, 7, "9")

	return _pack("under", "Erlik'in Karanlığı", g, Vector2i(7, 30), {
		"#": "cave_wall", "~": "lava", ".": "cave", ",": "moss", "p": "cave", "T": "cave",
	}, Color(0.05, 0.04, 0.07))


static func _sky() -> Dictionary:
	var w := 48
	var h := 36
	var g := _new(w, h, "~")
	var rng := _rng(998877)

	_blob(g, 10, 30, 8, 6, ".")
	_blob(g, 26, 24, 6, 5, ".")
	_blob(g, 36, 16, 6, 5, ".")
	_blob(g, 40, 7, 8, 6, ".")

	_rect(g, 14, 27, 10, 3, "p")
	_rect(g, 29, 19, 3, 8, "p")
	_rect(g, 39, 11, 3, 8, "p")

	_scatter(g, rng, ",", 0.04, ".")

	_put(g, 10, 30, "@")
	_put(g, 6, 32, "A")
	_put(g, 5, 26, "C")
	_put(g, 15, 33, "U")
	_put(g, 26, 25, "X")
	_put(g, 34, 16, "X")
	_put(g, 22, 26, "2")
	_put(g, 28, 22, "2")
	_put(g, 33, 18, "2")
	_put(g, 36, 13, "2")
	_put(g, 13, 28, "2")
	_put(g, 36, 10, "4")
	_put(g, 40, 7, "9")

	return _pack("sky", "Ülgen'in Gök Yaylası", g, Vector2i(10, 30), {
		"#": "sky_stone", "~": "void", ".": "cloud", ",": "cloud", "p": "sky_path", "T": "cloud",
	}, Color(0.04, 0.06, 0.12))


# -------------------------------------------------------------------- yardımcı

static func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


static func _new(w: int, h: int, fill: String) -> Array:
	var g: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		row.fill(fill)
		g.append(row)
	return g


static func _pack(id: String, name: String, g: Array, spawn: Vector2i, ground: Dictionary, bg: Color) -> Dictionary:
	var rows := PackedStringArray()
	for row in g:
		rows.append("".join(row))
	return {
		"id": id,
		"name": name,
		"w": g[0].size(),
		"h": g.size(),
		"rows": rows,
		"spawn": spawn,
		"ground": ground,
		"bg": bg,
	}


static func _put(g: Array, x: int, y: int, ch: String) -> void:
	if y < 0 or y >= g.size():
		return
	var row: Array = g[y]
	if x < 0 or x >= row.size():
		return
	row[x] = ch


static func _rect(g: Array, x: int, y: int, w: int, h: int, ch: String) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_put(g, xx, yy, ch)


static func _border(g: Array, ch: String) -> void:
	var h: int = g.size()
	var w: int = g[0].size()
	for x in w:
		_put(g, x, 0, ch)
		_put(g, x, h - 1, ch)
	for y in h:
		_put(g, 0, y, ch)
		_put(g, w - 1, y, ch)


static func _blob(g: Array, cx: int, cy: int, rx: int, ry: int, ch: String) -> void:
	for yy in range(cy - ry, cy + ry + 1):
		for xx in range(cx - rx, cx + rx + 1):
			var dx := float(xx - cx) / float(rx)
			var dy := float(yy - cy) / float(ry)
			if dx * dx + dy * dy <= 1.0:
				_put(g, xx, yy, ch)


static func _house(g: Array, x: int, y: int, w: int, h: int) -> void:
	_rect(g, x, y, w, h, "#")
	_rect(g, x + 1, y + 1, w - 2, h - 2, ".")
	_put(g, x + int(w * 0.5), y + h - 1, ".")


static func _ruin(g: Array, x: int, y: int, w: int, h: int) -> void:
	_rect(g, x, y, w, h, ".")
	for i in w:
		if i % 3 != 2:
			_put(g, x + i, y, "#")
			_put(g, x + i, y + h - 1, "#")
	for i in h:
		if i % 3 != 1:
			_put(g, x, y + i, "#")
			_put(g, x + w - 1, y + i, "#")
	_put(g, x + 4, y + 3, "#")
	_put(g, x + 5, y + 3, "#")


static func _cluster(g: Array, rng: RandomNumberGenerator, cx: int, cy: int, r: int, ch: String, density: float, only_on: String = ".") -> void:
	for yy in range(cy - r, cy + r + 1):
		for xx in range(cx - r, cx + r + 1):
			if yy < 0 or yy >= g.size():
				continue
			var row: Array = g[yy]
			if xx < 0 or xx >= row.size():
				continue
			var dx := float(xx - cx) / float(maxi(1, r))
			var dy := float(yy - cy) / float(maxi(1, r))
			if dx * dx + dy * dy > 1.0:
				continue
			if row[xx] in only_on and rng.randf() < density:
				row[xx] = ch


static func _scatter(g: Array, rng: RandomNumberGenerator, ch: String, density: float, only_on: String) -> void:
	for yy in g.size():
		var row: Array = g[yy]
		for xx in row.size():
			if row[xx] in only_on and rng.randf() < density:
				row[xx] = ch


# ------------------------------------------------------------------- doğrulama

## Doğma noktasından yürüyerek ulaşılamayan işaretçileri döndürür.
static func unreachable_markers(rows: PackedStringArray, spawn: Vector2i) -> Array:
	var h := rows.size()
	var w := rows[0].length()
	var seen := {}
	var q: Array[Vector2i] = [spawn]
	seen[spawn] = true
	while not q.is_empty():
		var p: Vector2i = q.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + d
			if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
				continue
			if seen.has(n):
				continue
			var ch := rows[n.y].substr(n.x, 1)
			if ch in SOLID_CHARS:
				continue
			seen[n] = true
			q.append(n)

	var bad: Array = []
	for y in h:
		for x in w:
			var ch := rows[y].substr(x, 1)
			if ch in MARKERS and not seen.has(Vector2i(x, y)):
				bad.append("%s@%d,%d" % [ch, x, y])
	return bad
