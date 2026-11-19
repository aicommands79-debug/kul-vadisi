class_name Art
extends RefCounted
## Tüm görseller çalışma anında kodla üretilir. Projede tek bir resim dosyası yok.

static var P := {
	"grass": Color8(74, 122, 60),
	"grass_lt": Color8(96, 148, 75),
	"grass_dk": Color8(54, 96, 46),
	"flower_a": Color8(240, 214, 120),
	"flower_b": Color8(214, 120, 150),
	"dirt": Color8(138, 111, 74),
	"dirt_lt": Color8(160, 131, 92),
	"dirt_dk": Color8(110, 87, 57),
	"water": Color8(47, 93, 138),
	"water_lt": Color8(66, 120, 170),
	"water_hi": Color8(128, 182, 216),
	"rock": Color8(90, 90, 102),
	"rock_lt": Color8(120, 120, 132),
	"rock_dk": Color8(60, 60, 70),
	"trunk": Color8(92, 63, 38),
	"trunk_dk": Color8(68, 46, 27),
	"leaf": Color8(47, 90, 47),
	"leaf_lt": Color8(64, 114, 57),
	"leaf_hi": Color8(86, 140, 72),
	"skin": Color8(237, 190, 149),
	"hair": Color8(74, 48, 32),
	"grey": Color8(198, 200, 208),
	"tunic": Color8(42, 127, 111),
	"tunic_dk": Color8(30, 94, 82),
	"robe": Color8(140, 76, 58),
	"robe_dk": Color8(108, 56, 42),
	"leg": Color8(58, 62, 78),
	"belt": Color8(61, 43, 30),
	"boot": Color8(74, 53, 36),
	"steel": Color8(216, 222, 230),
	"ink": Color8(28, 24, 28),
	"slime": Color8(123, 201, 111),
	"slime_dk": Color8(79, 158, 70),
	"slime_hi": Color8(174, 228, 154),
	"wood": Color8(138, 90, 43),
	"wood_dk": Color8(104, 66, 31),
	"gold": Color8(242, 193, 78),
	"gold_dk": Color8(199, 152, 44),
	"glass": Color8(178, 218, 234),
	"potion": Color8(214, 72, 96),
	"heart": Color8(217, 69, 95),
	"heart_off": Color8(74, 66, 74),
	"white": Color(1, 1, 1, 1),
	"shadow": Color(0, 0, 0, 0.22),
	# --- yeraltı ---
	"cave_floor": Color8(58, 50, 58),
	"cave_lt": Color8(76, 66, 74),
	"cave_dk": Color8(42, 36, 44),
	"cave_wall": Color8(46, 38, 54),
	"cave_wall_lt": Color8(66, 55, 76),
	"lava": Color8(188, 74, 32),
	"lava_lt": Color8(240, 138, 50),
	"lava_hi": Color8(255, 216, 120),
	"moss": Color8(72, 100, 62),
	# --- gök ---
	"cloud": Color8(214, 226, 240),
	"cloud_dk": Color8(172, 192, 214),
	"cloud_lt": Color8(242, 247, 252),
	"sky_stone": Color8(182, 200, 222),
	"sky_stone_lt": Color8(210, 224, 240),
	"void": Color8(18, 20, 38),
	"void_lt": Color8(32, 36, 62),
	"star": Color8(225, 236, 255),
	# --- yaratıklar ---
	"imp": Color8(104, 78, 138),
	"imp_dk": Color8(68, 50, 94),
	"imp_eye": Color8(240, 210, 90),
	"surel": Color8(120, 118, 108),
	"surel_dk": Color8(84, 82, 74),
	"boss": Color8(56, 38, 64),
	"boss_lt": Color8(90, 62, 100),
	"boss_eye": Color8(240, 64, 64),
	"feather": Color8(238, 176, 88),
	"feather_dk": Color8(196, 128, 56),
	"portal_glow": Color8(120, 204, 255),
	"portal_dk": Color8(36, 66, 118),
	"ember": Color8(255, 150, 60),
}

static var _cache := {}


# ---------------------------------------------------------------- yardımcılar

static func _img(w: int, h: int) -> Image:
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
		return
	im.set_pixel(x, y, c)


static func _rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(im, xx, yy, c)


static func _ellipse(im: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for xx in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var dx := (float(xx) - cx) / rx
			var dy := (float(yy) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(im, xx, yy, c)


static func _from_rows(rows: Array, pal: Dictionary) -> Image:
	var h := rows.size()
	var w := (rows[0] as String).length()
	var im := _img(w, h)
	for y in h:
		var s: String = rows[y]
		for x in mini(w, s.length()):
			var ch := s.substr(x, 1)
			if pal.has(ch):
				_px(im, x, y, pal[ch])
	return im


static func _store(key: String, im: Image) -> Texture2D:
	var t := ImageTexture.create_from_image(im)
	_cache[key] = t
	return t


# -------------------------------------------------------------------- zemin

static func draw_ground(im: Image, ox: int, oy: int, kind: String, rng: RandomNumberGenerator) -> void:
	match kind:
		"rock":
			_rect(im, ox, oy, 16, 16, P.rock)
			_rect(im, ox, oy, 16, 2, P.rock_lt)
			_rect(im, ox, oy + 14, 16, 2, P.rock_dk)
			_rect(im, ox, oy + 2, 1, 12, P.rock_lt)
			for i in 12:
				var c: Color = P.rock_dk if rng.randf() < 0.6 else P.rock_lt
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(2, 13), c)
			for i in 3:
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(11, 15), P.leaf)
		"water":
			_rect(im, ox, oy, 16, 16, P.water)
			for i in 14:
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), P.water_lt)
			for i in 2:
				var wy := oy + rng.randi_range(1, 14)
				var wx := ox + rng.randi_range(1, 12)
				var wlen := rng.randi_range(2, 5)
				_rect(im, wx, wy, wlen, 1, P.water_hi)
				_px(im, wx + wlen, wy + (1 if rng.randf() < 0.5 else 0), P.water_hi)
		"dirt":
			_rect(im, ox, oy, 16, 16, P.dirt)
			for i in 24:
				var c: Color = P.dirt_lt if rng.randf() < 0.5 else P.dirt_dk
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), c)
			for i in 2:
				_px(im, ox + rng.randi_range(1, 14), oy + rng.randi_range(1, 14), P.dirt_dk)
		"flower":
			_grass(im, ox, oy, rng)
			for i in 2:
				var fx := ox + rng.randi_range(3, 11)
				var fy := oy + rng.randi_range(3, 11)
				var col: Color = P.flower_a if rng.randf() < 0.5 else P.flower_b
				_px(im, fx, fy, col)
				_px(im, fx + 1, fy, col)
				_px(im, fx, fy + 1, col)
				_px(im, fx + 1, fy + 1, col)
				_px(im, fx, fy + 2, P.grass_dk)
		"cave":
			_rect(im, ox, oy, 16, 16, P.cave_floor)
			for i in 20:
				var cc: Color = P.cave_lt if rng.randf() < 0.5 else P.cave_dk
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), cc)
			for i in 2:
				var cx := ox + rng.randi_range(2, 11)
				var cy := oy + rng.randi_range(2, 12)
				_rect(im, cx, cy, rng.randi_range(2, 4), 1, P.cave_dk)
		"cave_wall":
			_rect(im, ox, oy, 16, 16, P.cave_wall)
			_rect(im, ox, oy, 16, 2, P.cave_wall_lt)
			_rect(im, ox, oy + 14, 16, 2, P.cave_dk)
			_rect(im, ox, oy + 2, 1, 12, P.cave_wall_lt)
			for i in 14:
				var cw: Color = P.cave_wall_lt if rng.randf() < 0.4 else P.cave_dk
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(2, 13), cw)
		"moss":
			_rect(im, ox, oy, 16, 16, P.cave_floor)
			for i in 16:
				var mc: Color = P.moss if rng.randf() < 0.55 else P.cave_dk
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), mc)
			for i in 3:
				_rect(im, ox + rng.randi_range(1, 13), oy + rng.randi_range(1, 14), 2, 1, P.moss)
		"lava":
			_rect(im, ox, oy, 16, 16, P.lava)
			for i in 3:
				_ellipse(im, ox + rng.randi_range(2, 13), oy + rng.randi_range(2, 13), rng.randi_range(2, 4), rng.randi_range(1, 2), P.lava_lt)
			for i in 8:
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), P.lava_hi)
		"cloud":
			_rect(im, ox, oy, 16, 16, P.cloud)
			for i in 16:
				var cl: Color = P.cloud_lt if rng.randf() < 0.5 else P.cloud_dk
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), cl)
			for i in 2:
				_ellipse(im, ox + rng.randi_range(3, 12), oy + rng.randi_range(3, 12), 3.0, 1.6, P.cloud_lt)
		"sky_path":
			_rect(im, ox, oy, 16, 16, P.sky_stone)
			_rect(im, ox, oy, 16, 2, P.sky_stone_lt)
			_rect(im, ox, oy + 14, 16, 2, P.cloud_dk)
			for i in 12:
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(2, 13), P.cloud_dk if rng.randf() < 0.5 else P.sky_stone_lt)
		"void":
			_rect(im, ox, oy, 16, 16, P.void)
			for i in 4:
				_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), P.star if rng.randf() < 0.35 else P.void_lt)
		_:
			_grass(im, ox, oy, rng)


static func _grass(im: Image, ox: int, oy: int, rng: RandomNumberGenerator) -> void:
	_rect(im, ox, oy, 16, 16, P.grass)
	for i in 20:
		var c: Color = P.grass_lt if rng.randf() < 0.55 else P.grass_dk
		_px(im, ox + rng.randi_range(0, 15), oy + rng.randi_range(0, 15), c)
	for i in 2:
		var bx := ox + rng.randi_range(1, 13)
		var by := oy + rng.randi_range(2, 13)
		_px(im, bx, by, P.grass_dk)
		_px(im, bx, by - 1, P.grass_lt)
		_px(im, bx + 1, by - 1, P.grass_dk)


# ------------------------------------------------------------------- nesneler

static func tree() -> Texture2D:
	if _cache.has("tree"):
		return _cache["tree"]
	var im := _img(16, 32)
	_ellipse(im, 8, 30.4, 5.6, 1.6, P.shadow)
	_rect(im, 6, 20, 4, 11, P.trunk)
	_rect(im, 9, 20, 1, 11, P.trunk_dk)
	_rect(im, 6, 27, 4, 1, P.trunk_dk)
	_ellipse(im, 8, 11, 7.4, 6.8, P.leaf)
	_ellipse(im, 3.6, 14.5, 4.4, 3.8, P.leaf)
	_ellipse(im, 12.4, 14.5, 4.4, 3.8, P.leaf)
	_ellipse(im, 6.8, 8, 4.6, 3.4, P.leaf_lt)
	_ellipse(im, 10.5, 13, 2.4, 1.8, P.leaf_hi)
	for i in 8:
		_px(im, 2 + (i * 3) % 13, 6 + (i * 5) % 10, P.leaf_hi)
	return _store("tree", im)


static func sign() -> Texture2D:
	if _cache.has("sign"):
		return _cache["sign"]
	var im := _img(16, 16)
	_ellipse(im, 8, 15, 4, 1, P.shadow)
	_rect(im, 7, 9, 2, 7, P.trunk)
	_rect(im, 2, 3, 12, 7, P.wood)
	_rect(im, 2, 3, 12, 1, P.dirt_lt)
	_rect(im, 2, 9, 12, 1, P.wood_dk)
	_rect(im, 3, 3, 1, 7, P.wood_dk)
	_rect(im, 12, 3, 1, 7, P.wood_dk)
	_rect(im, 4, 5, 8, 1, P.wood_dk)
	_rect(im, 4, 7, 5, 1, P.wood_dk)
	return _store("sign", im)


static func chest(opened: bool) -> Texture2D:
	var key := "chest_%s" % str(opened)
	if _cache.has(key):
		return _cache[key]
	var im := _img(16, 16)
	_ellipse(im, 8, 15, 5.5, 1.2, P.shadow)
	_rect(im, 2, 8, 12, 6, P.wood)
	_rect(im, 2, 13, 12, 1, P.wood_dk)
	_rect(im, 7, 8, 2, 6, P.gold_dk)
	if opened:
		_ellipse(im, 8, 4, 6, 3, P.wood)
		_rect(im, 3, 7, 10, 2, Color8(38, 28, 22))
		_rect(im, 5, 7, 6, 1, P.gold)
		_px(im, 6, 8, P.gold)
		_px(im, 9, 8, P.gold)
	else:
		_ellipse(im, 8, 7, 6, 3.2, P.wood)
		_rect(im, 2, 7, 12, 1, P.wood_dk)
		_rect(im, 7, 4, 2, 5, P.gold_dk)
		_rect(im, 7, 8, 2, 2, P.gold)
		_px(im, 8, 9, P.gold_dk)
	return _store(key, im)


static func coin() -> Texture2D:
	if _cache.has("coin"):
		return _cache["coin"]
	var im := _img(8, 8)
	_ellipse(im, 4, 4, 3.4, 3.4, P.gold_dk)
	_ellipse(im, 4, 3.6, 2.8, 2.8, P.gold)
	_px(im, 3, 2, Color(1, 1, 1, 0.85))
	_px(im, 2, 3, Color(1, 1, 1, 0.5))
	return _store("coin", im)


static func potion() -> Texture2D:
	if _cache.has("potion"):
		return _cache["potion"]
	var im := _img(8, 10)
	_rect(im, 3, 2, 2, 1, P.wood)
	_rect(im, 3, 3, 2, 2, P.glass)
	_ellipse(im, 4, 7, 3, 3.2, P.glass)
	_ellipse(im, 4, 7.8, 2.4, 2.2, P.potion)
	_px(im, 3, 5, Color(1, 1, 1, 0.9))
	return _store("potion", im)


static func heart(full: bool) -> Texture2D:
	var key := "heart_%s" % str(full)
	if _cache.has(key):
		return _cache[key]
	var rows := [
		".XX.XX.",
		"XXXXXXX",
		"XXXXXXX",
		".XXXXX.",
		"..XXX..",
		"...X...",
	]
	var pal := {"X": P.heart if full else P.heart_off}
	var im := _from_rows(rows, pal)
	im.resize(14, 12, Image.INTERPOLATE_NEAREST)
	return _store(key, im)


# ---------------------------------------------------------------- karakterler

static func character(kind: String, dir: String, frame: int) -> Texture2D:
	var key := "ch_%s_%s_%d" % [kind, dir, frame]
	if _cache.has(key):
		return _cache[key]

	var tunic: Color = P.tunic
	var tunic_dk: Color = P.tunic_dk
	var hair: Color = P.hair
	if kind == "npc":
		tunic = P.robe
		tunic_dk = P.robe_dk
		hair = P.grey

	var im := _img(16, 24)
	_ellipse(im, 8, 22.6, 5.0, 1.4, P.shadow)

	var stride := 0
	if frame == 1:
		stride = 1
	elif frame == 2:
		stride = -1

	var lx := 5 + stride
	var rx := 8 - stride
	_rect(im, lx, 18, 3, 5, P.leg)
	_rect(im, lx, 21, 3, 2, P.boot)
	_rect(im, rx, 18, 3, 5, P.leg)
	_rect(im, rx, 21, 3, 2, P.boot)

	# gövde
	_rect(im, 4, 11, 8, 7, tunic)
	_rect(im, 10, 11, 2, 7, tunic_dk)
	_rect(im, 4, 16, 8, 1, P.belt)

	# kollar
	var arm_off := stride * 1
	_rect(im, 2, 12 + arm_off, 2, 5, tunic_dk)
	_rect(im, 12, 12 - arm_off, 2, 5, tunic_dk)
	_px(im, 2, 16 + arm_off, P.skin)
	_px(im, 13, 16 - arm_off, P.skin)

	# kafa
	_ellipse(im, 8.0, 7.5, 4.6, 4.6, P.skin)
	if dir == "up":
		_ellipse(im, 8.0, 7.0, 4.8, 4.8, hair)
		_ellipse(im, 8.0, 9.8, 4.1, 2.6, hair)
	else:
		_ellipse(im, 8.0, 5.4, 4.9, 3.4, hair)
		_rect(im, 3, 5, 2, 5, hair)
		_rect(im, 11, 5, 2, 5, hair)
		if dir == "down":
			_rect(im, 6, 8, 1, 2, P.ink)
			_rect(im, 9, 8, 1, 2, P.ink)
			_px(im, 8, 10, P.ink)
		elif dir == "left":
			_rect(im, 5, 8, 1, 2, P.ink)
			_rect(im, 7, 8, 1, 2, P.ink)
		else:
			_rect(im, 8, 8, 1, 2, P.ink)
			_rect(im, 10, 8, 1, 2, P.ink)

	return _store(key, im)


static func slime(frame: int) -> Texture2D:
	var key := "slime_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var im := _img(16, 16)
	_ellipse(im, 8, 14.4, 5.4, 1.3, P.shadow)
	if frame == 0:
		_ellipse(im, 8, 10.4, 6.0, 4.2, P.slime_dk)
		_ellipse(im, 8, 9.6, 5.6, 4.0, P.slime)
		_ellipse(im, 6.0, 7.4, 2.0, 1.4, P.slime_hi)
		_rect(im, 5, 9, 1, 2, P.ink)
		_rect(im, 10, 9, 1, 2, P.ink)
		_px(im, 5, 9, P.white)
		_px(im, 10, 9, P.white)
	else:
		_ellipse(im, 8, 11.8, 6.6, 3.2, P.slime_dk)
		_ellipse(im, 8, 11.0, 6.2, 3.0, P.slime)
		_ellipse(im, 5.6, 9.2, 1.8, 1.1, P.slime_hi)
		_rect(im, 5, 10, 1, 2, P.ink)
		_rect(im, 10, 10, 1, 2, P.ink)
		_px(im, 5, 10, P.white)
		_px(im, 10, 10, P.white)
	return _store(key, im)


static func slash() -> Texture2D:
	if _cache.has("slash"):
		return _cache["slash"]
	var im := _img(24, 24)
	for i in 26:
		var a := deg_to_rad(-64.0 + i * (128.0 / 25.0))
		for r in range(7, 12):
			var x := int(round(12.0 + cos(a) * float(r)))
			var y := int(round(12.0 + sin(a) * float(r)))
			var t := float(r - 7) / 4.0
			_px(im, x, y, Color(1.0, 1.0, 1.0, 0.95 - t * 0.6))
	# keskin iç kenar
	for i in 18:
		var a2 := deg_to_rad(-56.0 + i * (112.0 / 17.0))
		_px(im, int(round(12.0 + cos(a2) * 7.0)), int(round(12.0 + sin(a2) * 7.0)), Color(0.85, 0.97, 1.0, 1.0))
	return _store("slash", im)


static func spark() -> Texture2D:
	if _cache.has("spark"):
		return _cache["spark"]
	var im := _img(7, 7)
	_px(im, 3, 0, Color(1, 1, 1, 1))
	_px(im, 3, 1, Color(1, 1, 1, 1))
	_px(im, 1, 3, Color(1, 1, 1, 1))
	_px(im, 2, 3, Color(1, 1, 1, 1))
	_px(im, 4, 3, Color(1, 1, 1, 1))
	_px(im, 5, 3, Color(1, 1, 1, 1))
	_px(im, 3, 5, Color(1, 1, 1, 1))
	_px(im, 3, 6, Color(1, 1, 1, 1))
	_px(im, 3, 3, Color(1, 0.95, 0.6, 1))
	return _store("spark", im)


# --------------------------------------------------------------- yeni yaratıklar

static func imp(frame: int) -> Texture2D:
	var key := "imp_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var im := _img(14, 14)
	var flap := 1 if frame == 0 else -1
	_ellipse(im, 2.4, 6.0 - flap, 2.6, 1.3, P.imp_dk)
	_ellipse(im, 11.6, 6.0 - flap, 2.6, 1.3, P.imp_dk)
	_ellipse(im, 7.0, 8.6, 3.6, 4.2, P.imp)
	_ellipse(im, 7.0, 5.0, 2.9, 2.6, P.imp)
	_px(im, 5, 2, P.imp_dk)
	_px(im, 9, 2, P.imp_dk)
	_px(im, 6, 5, P.imp_eye)
	_px(im, 8, 5, P.imp_eye)
	_px(im, 10, 11, P.imp_dk)
	_px(im, 11, 12, P.imp_dk)
	return _store(key, im)


static func surel(frame: int) -> Texture2D:
	var key := "surel_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var im := _img(16, 20)
	var sw := 1 if frame == 1 else (-1 if frame == 2 else 0)
	_ellipse(im, 8, 19.2, 4.6, 1.2, P.shadow)
	_rect(im, 5 + sw, 15, 3, 4, P.surel_dk)
	_rect(im, 9 - sw, 15, 3, 4, P.surel_dk)
	_ellipse(im, 8, 11.0, 4.3, 5.0, P.surel)
	_rect(im, 3, 9 + sw, 2, 7, P.surel_dk)
	_rect(im, 11, 9 - sw, 2, 7, P.surel_dk)
	_ellipse(im, 8.0, 5.4, 3.5, 3.1, P.surel)
	_rect(im, 6, 5, 1, 2, P.imp_eye)
	_rect(im, 9, 5, 1, 2, P.imp_eye)
	_rect(im, 7, 8, 2, 1, P.ink)
	return _store(key, im)


static func tepegos(frame: int) -> Texture2D:
	var key := "tepegos_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var im := _img(18, 22)
	var arm := 1 if frame == 1 else 0
	_ellipse(im, 9, 21.2, 5.6, 1.3, P.shadow)
	_rect(im, 5, 14, 8, 7, P.surel_dk)
	_ellipse(im, 9, 12.5, 5.6, 4.6, P.surel)
	_ellipse(im, 9.0, 6.0, 5.1, 4.7, P.surel)
	_ellipse(im, 9.0, 6.2, 3.0, 2.7, P.white)
	_ellipse(im, 9.0, 6.2, 1.5, 1.4, P.ink)
	_px(im, 9, 5, Color(1, 1, 1, 0.9))
	_rect(im, 5, 1, 8, 1, P.surel_dk)
	_rect(im, 2, 12 + arm, 3, 7, P.surel)
	_rect(im, 13, 12 - arm, 3, 7, P.surel)
	return _store(key, im)


static func karabasan(frame: int) -> Texture2D:
	var key := "karabasan_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var im := _img(32, 40)
	var sway := 1 if frame == 1 else 0
	_ellipse(im, 16, 38.5, 10.0, 1.6, P.shadow)
	# pelerin
	_ellipse(im, 16, 27, 9.5, 12.0, P.boss)
	_rect(im, 7, 26, 18, 11, P.boss)
	for i in 6:
		_px(im, 7 + i * 3 + sway, 37, P.boss)
		_px(im, 8 + i * 3, 36, P.boss)
	# gövde
	_ellipse(im, 16.0, 20.0, 8.2, 7.0, P.boss_lt)
	# kollar
	_ellipse(im, 6.0, 22.0 + sway, 3.4, 5.0, P.boss)
	_ellipse(im, 26.0, 22.0 - sway, 3.4, 5.0, P.boss)
	# kafa
	_ellipse(im, 16.0, 11.0, 5.8, 6.2, P.boss)
	# boynuzlar
	_px(im, 11, 5, P.boss_lt)
	_px(im, 11, 4, P.boss_lt)
	_px(im, 10, 3, P.boss_lt)
	_px(im, 21, 5, P.boss_lt)
	_px(im, 21, 4, P.boss_lt)
	_px(im, 22, 3, P.boss_lt)
	# gözler
	_rect(im, 13, 10, 2, 2, P.boss_eye)
	_rect(im, 18, 10, 2, 2, P.boss_eye)
	# sis
	for i in 10:
		_px(im, 6 + (i * 7) % 21, 30 + (i * 3) % 8, Color(0.45, 0.3, 0.55, 0.5))
	return _store(key, im)


static func simurg(frame: int) -> Texture2D:
	var key := "simurg_%d" % frame
	if _cache.has(key):
		return _cache[key]
	var im := _img(44, 36)
	var flap := 1 if frame == 0 else -1
	# kanatlar
	_ellipse(im, 10.0, 16.0 - flap * 5.0, 9.0, 6.0, P.feather_dk)
	_ellipse(im, 34.0, 16.0 - flap * 5.0, 9.0, 6.0, P.feather_dk)
	_ellipse(im, 9.0, 15.0 - flap * 5.0, 6.0, 3.6, P.feather)
	_ellipse(im, 35.0, 15.0 - flap * 5.0, 6.0, 3.6, P.feather)
	# gövde
	_ellipse(im, 22.0, 20.0, 8.0, 9.0, P.feather)
	_ellipse(im, 22.0, 21.0, 5.4, 6.4, P.gold)
	# kuyruk
	_rect(im, 20, 28, 4, 7, P.feather_dk)
	_rect(im, 18, 33, 3, 3, P.feather)
	_rect(im, 23, 33, 3, 3, P.feather)
	# kafa
	_ellipse(im, 22.0, 10.0, 5.2, 5.2, P.feather)
	_rect(im, 26, 10, 4, 2, P.gold)
	_px(im, 27, 12, P.feather_dk)
	_px(im, 24, 9, P.ink)
	# taç tüyleri
	_px(im, 20, 3, P.gold)
	_px(im, 21, 2, P.gold)
	_px(im, 23, 3, P.gold)
	return _store(key, im)


static func portal(open_: bool) -> Texture2D:
	var key := "portal_%s" % str(open_)
	if _cache.has(key):
		return _cache[key]
	var im := _img(22, 30)
	_ellipse(im, 11, 29.0, 7.0, 1.3, P.shadow)
	# taş kemer
	_ellipse(im, 11.0, 15.0, 9.5, 13.0, P.rock_dk)
	_ellipse(im, 11.0, 15.0, 7.6, 11.2, P.rock)
	# iç yüzey
	if open_:
		_ellipse(im, 11.0, 15.0, 6.2, 9.6, P.portal_dk)
		_ellipse(im, 11.0, 16.0, 4.6, 7.8, P.portal_glow)
		_ellipse(im, 11.0, 17.0, 2.6, 5.0, Color(0.85, 0.96, 1.0, 0.9))
		for i in 5:
			_px(im, 7 + (i * 3) % 9, 9 + (i * 5) % 13, Color(1, 1, 1, 0.8))
	else:
		_ellipse(im, 11.0, 15.0, 6.2, 9.6, P.ink)
		_ellipse(im, 11.0, 15.0, 4.6, 7.8, P.rock_dk)
		_rect(im, 9, 12, 4, 1, P.rock_lt)
		_rect(im, 9, 18, 4, 1, P.rock_lt)
	# taban
	_rect(im, 1, 27, 20, 2, P.rock_dk)
	return _store(key, im)


static func shrine(used: bool) -> Texture2D:
	var key := "shrine_%s" % str(used)
	if _cache.has(key):
		return _cache[key]
	var im := _img(16, 24)
	_ellipse(im, 8, 23.0, 5.6, 1.4, P.shadow)
	_rect(im, 3, 20, 10, 4, P.sky_stone)
	_rect(im, 3, 20, 10, 1, P.sky_stone_lt)
	_rect(im, 5, 12, 6, 9, P.sky_stone)
	_rect(im, 5, 12, 1, 9, P.sky_stone_lt)
	# kase
	_rect(im, 4, 10, 8, 3, P.sky_stone)
	_rect(im, 4, 10, 8, 1, P.sky_stone_lt)
	if used:
		_px(im, 8, 9, P.rock_dk)
		_px(im, 7, 8, P.rock_dk)
		_px(im, 9, 8, P.rock_dk)
	else:
		_ellipse(im, 8.0, 6.5, 2.6, 3.4, P.ember)
		_ellipse(im, 8.0, 7.0, 1.5, 2.2, P.lava_hi)
		_ellipse(im, 8.0, 8.0, 0.9, 1.4, Color(1, 1, 0.85, 1))
		_px(im, 8, 1, Color(1, 0.9, 0.6, 0.6))
		_px(im, 6, 3, Color(1, 0.9, 0.6, 0.4))
	return _store(key, im)


static func rock_shot() -> Texture2D:
	if _cache.has("rock_shot"):
		return _cache["rock_shot"]
	var im := _img(8, 8)
	_ellipse(im, 4.0, 4.0, 3.9, 3.8, P.rock_lt)
	_ellipse(im, 4.0, 4.0, 3.1, 3.0, P.rock_dk)
	_ellipse(im, 3.6, 3.4, 2.1, 2.0, P.rock)
	_px(im, 3, 2, P.sky_stone_lt)
	_px(im, 2, 3, P.sky_stone_lt)
	return _store("rock_shot", im)


static func feather_shot() -> Texture2D:
	if _cache.has("feather_shot"):
		return _cache["feather_shot"]
	var im := _img(10, 6)
	_rect(im, 0, 2, 7, 1, P.feather)
	_rect(im, 2, 1, 4, 1, P.gold)
	_rect(im, 2, 3, 4, 1, P.feather_dk)
	_px(im, 8, 2, P.gold)
	_px(im, 9, 3, P.gold)
	return _store("feather_shot", im)
