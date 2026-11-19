extends Node2D
## Dünyayı seçili boyuta göre kurar. Haritalar RealmGen tarafından üretilir;
## zemin tek bir Image'e pişirilir, nesneler ve düşmanlar işaretçilerden doğar.

const TILE := 16

var ui: UI
var player: Player
var realm_id := "valley"
var realm: Dictionary = {}
var rows: PackedStringArray = []

var _ground: Sprite2D
var _ysort: Node2D
var _props: StaticBody2D
var enemies: Array = []
var chests: Array = []


func _ready() -> void:
	randomize()
	Game.boss = null
	Game.player = null

	var args := OS.get_cmdline_user_args()
	var first_boot := not Game.booted
	if not Game.booted:
		Game.booted = true
		if args.has("--fresh") or args.has("--selftest") or args.has("--bosstest"):
			Game.reset_state()
		elif Game.has_save():
			Game.load_game()
	else:
		# Sahne yeniden yükleniyorsa (boyut geçişi / F9 / F10) durum bellekte.
		pass

	for a in args:
		if a.begins_with("--realm="):
			Game.realm = a.substr(8)
		elif a.begins_with("--step="):
			Game.step = int(a.substr(7))
		elif a == "--kara":
			Game.bosses["karabasan"] = true
			Game.damage = 15

	_build(str(Game.realm))

	var start := _spawn_world()
	if Game.saved_pos != Vector2.ZERO:
		start = Game.saved_pos
	player.position = start

	for a in args:
		if a.begins_with("--tp="):
			var parts := a.substr(5).split(",")
			if parts.size() == 2:
				player.position = Vector2(float(parts[0]) * TILE + TILE * 0.5, float(parts[1]) * TILE + TILE)

	Game.player = player
	Game.spawn_point = _spawn_world()
	Game.saved_pos = player.position

	# Boyut geçişi / F9 / F10 sonrası yeni sahne durumunu hemen kaydet.
	if not first_boot and not args.has("--shot") and not args.has("--selftest") and not args.has("--bosstest"):
		Game.save_game()

	if args.has("--shot"):
		_shot()
	if args.has("--selftest"):
		_selftest()
	if args.has("--bosstest"):
		_bosstest()


func _build(rid: String) -> void:
	realm_id = rid
	realm = RealmGen.build(rid)
	rows = realm["rows"]
	RenderingServer.set_default_clear_color(realm["bg"])
	_validate()

	_build_ground()

	_props = StaticBody2D.new()
	_props.name = "Props"
	_props.collision_layer = 1
	_props.collision_mask = 0
	add_child(_props)

	_build_walls()

	_ysort = Node2D.new()
	_ysort.name = "YSort"
	_ysort.y_sort_enabled = true
	add_child(_ysort)

	_build_objects()
	_spawn_player()
	_spawn_enemies()

	ui = UI.new()
	add_child(ui)


func _w() -> int:
	return rows[0].length()


func _h() -> int:
	return rows.size()


func _char_at(x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0:
		return "#"
	var row: String = rows[y]
	if x >= row.length():
		return "#"
	return row.substr(x, 1)


func _is_solid(ch: String) -> bool:
	return ch == "#" or ch == "~"


func _validate() -> void:
	var w := _w()
	for y in rows.size():
		if rows[y].length() != w:
			push_warning("Harita satiri %d uzunlugu %d (beklenen %d)" % [y, rows[y].length(), w])


# --------------------------------------------------------------------- zemin

func _ground_kind(ch: String) -> String:
	var table: Dictionary = realm["ground"]
	if table.has(ch):
		return str(table[ch])
	if ch == ",":
		return str(table.get(".", "grass"))
	return str(table.get(".", "grass"))


func _build_ground() -> void:
	var w := _w()
	var h := _h()
	var im := Image.create_empty(w * TILE, h * TILE, false, Image.FORMAT_RGBA8)
	im.fill(realm["bg"])
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(realm_id)) + 1337
	for y in h:
		for x in w:
			Art.draw_ground(im, x * TILE, y * TILE, _ground_kind(_char_at(x, y)), rng)

	_soften_edges(im, w, h)

	_ground = Sprite2D.new()
	_ground.name = "Ground"
	_ground.centered = false
	_ground.texture = ImageTexture.create_from_image(im)
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_ground)


## Yol, su/lav ve bulut kenarlarını piksel piksel tırtıklı hale getirir.
func _soften_edges(im: Image, w: int, h: int) -> void:
	var spec := _edge_colors()
	if spec.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(realm_id)) + 90210

	for y in h:
		for x in w:
			var ch := _char_at(x, y)
			if not spec.has(ch):
				continue
			var cols: Array = spec[ch]
			var c0: Color = Art.P[str(cols[0])]
			var c1: Color = Art.P[str(cols[1])]
			var ox := x * TILE
			var oy := y * TILE
			for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				if _char_at(nx, ny) == ch:
					continue
				for i in TILE:
					var px := ox + (i if d.x == 0 else (0 if d.x < 0 else 15))
					var py := oy + (i if d.y == 0 else (0 if d.y < 0 else 15))
					var p0 := 0.28 if realm_id == "sky" and ch == "." else 0.45
					var p1 := 0.12 if realm_id == "sky" and ch == "." else 0.22
					if rng.randf() < p0:
						im.set_pixel(px, py, c0)
					elif rng.randf() < p1:
						im.set_pixel(px, py, c1)


func _edge_colors() -> Dictionary:
	match realm_id:
		"under":
			return {
				"p": ["cave_lt", "cave_dk"],
				"~": ["lava_hi", "lava_lt"],
			}
		"sky":
			return {
				".": ["cloud_dk", "void_lt"],
				"p": ["sky_stone_lt", "cloud_dk"],
			}
		_:
			return {
				"p": ["grass", "grass_dk"],
				"~": ["water_hi", "water"],
			}


# --------------------------------------------------------------------- duvar

func _build_walls() -> void:
	var w := _w()
	var h := _h()
	for y in h:
		var run_start := -1
		for x in w + 1:
			var solid := false
			if x < w:
				solid = _is_solid(_char_at(x, y))
			if solid and run_start < 0:
				run_start = x
			elif not solid and run_start >= 0:
				var run_w := x - run_start
				var col := CollisionShape2D.new()
				var box := RectangleShape2D.new()
				box.size = Vector2(run_w * TILE, TILE)
				col.shape = box
				col.position = Vector2(run_start * TILE + run_w * TILE * 0.5, y * TILE + TILE * 0.5)
				_props.add_child(col)
				run_start = -1


# -------------------------------------------------------------------- nesneler

func _build_objects() -> void:
	for y in _h():
		for x in _w():
			match _char_at(x, y):
				"T":
					_add_tree(x, y)
				"N":
					var n := Npc.new()
					n.position = _tile_pos(x, y)
					_ysort.add_child(n)
				"S":
					var s := Sign.new()
					s.position = _tile_pos(x, y)
					_ysort.add_child(s)
				"C", "X":
					_add_chest(x, y)
				"U":
					_add_shrine(x, y)
				"A", "B":
					_add_portal(x, y)


func _tile_pos(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, (y + 1) * TILE)


func _spawn_world() -> Vector2:
	var sp: Vector2i = realm.get("spawn", Vector2i(2, 2))
	return Vector2(sp.x * TILE + TILE * 0.5, (sp.y + 1) * TILE)


func _add_tree(x: int, y: int) -> void:
	var s := Sprite2D.new()
	s.texture = Art.tree()
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = Vector2(-8, -32)
	s.position = _tile_pos(x, y)
	_ysort.add_child(s)

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = _tile_pos(x, y) + Vector2(0, -3)
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(9, 6)
	col.shape = box
	body.add_child(col)
	_props.add_child(body)


func _add_chest(x: int, y: int) -> void:
	var c := Chest.new()
	c.id = "%s_chest_%d_%d" % [realm_id, x, y]
	match realm_id:
		"under":
			c.loot_coins = 25
			c.loot_potion = 1
		"sky":
			c.loot_coins = 30
			c.loot_potion = 1
		_:
			if x < 30:
				c.loot_coins = 12
				c.loot_potion = 0
			else:
				c.loot_coins = 20
				c.loot_potion = 1
	c.position = _tile_pos(x, y)
	_ysort.add_child(c)
	chests.append(c)


func _add_shrine(x: int, y: int) -> void:
	var s := Shrine.new()
	s.id = "%s_shrine_%d_%d" % [realm_id, x, y]
	s.position = _tile_pos(x, y)
	_ysort.add_child(s)


func _add_portal(x: int, y: int) -> void:
	var p := Portal.new()
	if realm_id == "valley":
		if _char_at(x, y) == "A":
			p.target = "under"
			p.display_name = "Yer Altı Kapısı"
		else:
			p.target = "sky"
			p.display_name = "Gök Kapısı"
	else:
		p.target = "valley"
		p.display_name = "Vadi Kapısı"
	p.position = _tile_pos(x, y)
	_ysort.add_child(p)


# --------------------------------------------------------------------- oyuncu

func _spawn_player() -> void:
	player = Player.new()
	player.position = _spawn_world()
	_ysort.add_child(player)

	var cam := player.cam
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = _w() * TILE
	cam.limit_bottom = _h() * TILE


# ------------------------------------------------------------------- düşmanlar

func _spawn_enemies() -> void:
	var kinds := {"1": "slime", "2": "imp", "3": "surel", "4": "tepegos"}
	for y in _h():
		for x in _w():
			var ch := _char_at(x, y)
			if kinds.has(ch):
				var e := Enemy.new()
				e.kind = str(kinds[ch])
				e.position = _tile_pos(x, y)
				_ysort.add_child(e)
				enemies.append(e)
			elif ch == "9":
				var boss_key := "karabasan" if realm_id == "under" else "simurg"
				if Game.bosses.has(boss_key):
					continue
				var b := Boss.new()
				b.kind = boss_key
				b.position = _tile_pos(x, y)
				_ysort.add_child(b)
				enemies.append(b)


# ---------------------------------------------------------------- boyut geçişi

func load_realm(id: String) -> void:
	if id == realm_id:
		return
	Game.realm = id
	Game.saved_pos = Vector2.ZERO
	Game.boss = null
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- test / görsel

func _save_backup() -> Dictionary:
	var had := FileAccess.file_exists(Game.SAVE_PATH)
	var txt := ""
	if had:
		txt = FileAccess.get_file_as_string(Game.SAVE_PATH)
	return {"had": had, "text": txt}


func _save_restore(backup: Dictionary) -> void:
	if bool(backup.get("had", false)):
		var f := FileAccess.open(Game.SAVE_PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(str(backup.get("text", "")))
			f.close()
	else:
		Game.delete_save()


func _shot() -> void:
	await get_tree().create_timer(1.0).timeout
	var args := OS.get_cmdline_user_args()
	if args.has("--demo-dialog"):
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is Npc:
				n.interact()
				break
		await get_tree().create_timer(2.1).timeout
	if args.has("--demo-shrine"):
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is Shrine:
				n.interact()
				break
		await get_tree().create_timer(0.7).timeout
	if args.has("--demo-boss"):
		if Game.boss != null and is_instance_valid(Game.boss):
			Game.boss.wake_up()
			Game.boss.fire()
		await get_tree().create_timer(0.35).timeout
	if args.has("--demo-attack"):
		player._attack()
		await get_tree().create_timer(0.05).timeout
	if args.has("--demo-portal") and realm_id == "valley":
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is Portal and n.target == "under":
				player.position = n.global_position + Vector2(0, 18)
				await get_tree().create_timer(0.25).timeout
				n.interact()
				return
	if args.has("--demo-pause"):
		ui._toggle_pause()
	if args.has("--demo-ending"):
		Game.ending_reached.emit()
		await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shot.png")
	var err := img.save_png(path)
	print("SHOT ", path, " err=", err)
	get_tree().quit()


func _bosstest() -> void:
	var backup := _save_backup()
	await get_tree().create_timer(0.8).timeout
	var fails: Array[String] = []
	var b = Game.boss
	if b == null or not is_instance_valid(b):
		fails.append("boss sahnede yok")
	else:
		var dmg0: int = Game.damage
		var coins0: int = Game.coins
		b.take_damage(9999, player.global_position)
		await get_tree().create_timer(0.6).timeout
		var want_step := 3 if realm_id == "under" else 4
		var key := "karabasan" if realm_id == "under" else "simurg"
		if Game.step != want_step:
			fails.append("hikaye adimi %d (beklenen %d)" % [Game.step, want_step])
		if not Game.bosses.has(key):
			fails.append("boss kaydi tutulmadi")
		if Game.boss != null and is_instance_valid(Game.boss):
			fails.append("boss referansi temizlenmedi")
		if Game.coins <= coins0:
			fails.append("boss altin vermedi")
		if realm_id == "under" and Game.damage != dmg0 + 5:
			fails.append("kara kor kilici guc vermedi")

	_save_restore(backup)

	if fails.is_empty():
		print("BOSSTEST PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			print("BOSSTEST FAIL: ", f)
		get_tree().quit(1)


func _selftest() -> void:
	var backup := _save_backup()
	await get_tree().create_timer(0.5).timeout
	var fails: Array[String] = []

	for rid in ["valley", "under", "sky"]:
		var r := RealmGen.build(rid)
		var bad := RealmGen.unreachable_markers(r["rows"], r["spawn"])
		if not bad.is_empty():
			fails.append("%s: ulasilamayan isaret %s" % [rid, str(bad)])

	var slime: Enemy = null
	for e in enemies:
		if e is Enemy and e.kind == "slime":
			slime = e
			break
	if slime == null:
		fails.append("balcik bulunamadi")
	else:
		var before := Game.slime_kills
		slime.take_damage(999, player.global_position)
		await get_tree().create_timer(0.25).timeout
		if Game.slime_kills != before + 1:
			fails.append("balcik olumu goreve islemedi")

	if not chests.is_empty():
		var coins_before := Game.coins
		chests[0].interact()
		if Game.coins <= coins_before:
			fails.append("sandik altin vermedi")
		if not Game.chests_opened.has(chests[0].id):
			fails.append("sandik kaydi tutulmadi")

	var done := [false]
	Game.start_dialog(["test satiri"], func() -> void:
		done[0] = true
	)
	if not Game.dialog_active:
		fails.append("diyalog acilmadi")
	Game.end_dialog()
	if not done[0]:
		fails.append("diyalog geri cagrisi calismadi")
	ui.dialog_panel.visible = false

	var mh := Game.max_hp
	var sh := Shrine.new()
	sh.id = "selftest_shrine"
	sh.position = player.position + Vector2(0, 8)
	_ysort.add_child(sh)
	await get_tree().create_timer(0.1).timeout
	sh.interact()
	if not Game.dialog_active:
		fails.append("sunak diyalogu acilmadi")
	Game.end_dialog()
	ui.dialog_panel.visible = false
	if Game.max_hp != mh + 2:
		fails.append("sunak +2 can vermedi")
	if not Game.shrines_used.has("selftest_shrine"):
		fails.append("sunak kaydi tutulmadi")
	sh.queue_free()

	Game.hp = 4
	Game.save_game()
	Game.hp = 1
	if not Game.load_game():
		fails.append("kayit yuklenemedi")
	elif Game.hp != 4:
		fails.append("kayit/yukleme can degerini korumadi")

	Game.step = 0
	Game.bosses = {}
	if Game.can_enter("under"):
		fails.append("yer alti kapisi erken acildi")
	Game.step = 2
	if not Game.can_enter("under"):
		fails.append("yer alti kapisi acilmadi")
	if Game.can_enter("sky"):
		fails.append("gok kapisi erken acildi")
	Game.on_boss_defeated("karabasan")
	if not Game.can_enter("sky"):
		fails.append("gok kapisi karabasan sonrasi acilmadi")
	if Game.step != 3:
		fails.append("hikaye adimi karabasan sonrasi 3 olmadi")

	Game.reset_state()
	_save_restore(backup)

	if fails.is_empty():
		print("SELFTEST PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			print("SELFTEST FAIL: ", f)
		get_tree().quit(1)
