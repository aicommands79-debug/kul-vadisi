class_name UI
extends CanvasLayer

var hearts: HBoxContainer
var coin_lbl: Label
var potion_lbl: Label
var quest_lbl: Label
var hint_lbl: Label

var dialog_panel: PanelContainer
var speaker_lbl: Label
var text_lbl: Label
var more_lbl: Label

var toast_lbl: Label
var pause_panel: PanelContainer
var pause_lbl: Label

var realm_lbl: Label
var boss_panel: PanelContainer
var boss_name_lbl: Label
var boss_fill: ColorRect
var ending_panel: PanelContainer
var banner_title: Label
var banner_sub: Label

var _lines: Array[String] = []
var _idx := 0
var _typing := false
var _chars := 0.0
var _blip := 0.0
var _toast_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10

	_build_hud()
	_build_banner()
	_build_dialog()
	_build_toast()
	_build_pause()
	_build_boss_bar()
	_build_ending()

	Game.hud_changed.connect(_refresh_hud)
	Game.quest_changed.connect(_refresh_quest)
	Game.toast.connect(_on_toast)
	Game.dialog_started.connect(_on_dialog_started)
	Game.dialog_finished.connect(_on_dialog_finished)
	Game.ending_reached.connect(_on_ending)

	_refresh_hud()
	_refresh_quest()


# ---------------------------------------------------------------------- HUD

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	hearts = HBoxContainer.new()
	hearts.position = Vector2(16, 12)
	hearts.add_theme_constant_override("separation", 2)
	root.add_child(hearts)

	var coin_icon := TextureRect.new()
	coin_icon.texture = Art.coin()
	coin_icon.position = Vector2(18, 41)
	coin_icon.custom_minimum_size = Vector2(16, 16)
	coin_icon.size = Vector2(16, 16)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(coin_icon)

	coin_lbl = _label(root, Vector2(38, 38), 16, Color(0.98, 0.85, 0.45))
	potion_lbl = _label(root, Vector2(136, 38), 16, Color(0.9, 0.75, 0.85))

	var potion_icon := TextureRect.new()
	potion_icon.texture = Art.potion()
	potion_icon.position = Vector2(116, 38)
	potion_icon.custom_minimum_size = Vector2(16, 18)
	potion_icon.size = Vector2(16, 18)
	potion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	potion_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(potion_icon)

	quest_lbl = _label(root, Vector2(500, 14), 14, Color(0.95, 0.92, 0.8))
	quest_lbl.size = Vector2(444, 46)
	quest_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quest_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	realm_lbl = _label(root, Vector2(16, 64), 13, Color(0.86, 0.78, 0.6))
	realm_lbl.text = "◈  " + Game.realm_title(Game.realm)

	hint_lbl = _label(root, Vector2(16, 512), 12, Color(1, 1, 1, 0.5))
	hint_lbl.text = "WASD hareket · SPACE saldırı · E etkileşim · H iksir · F5 kaydet · ESC duraklat"


func _label(parent: Node, pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	return l


# ------------------------------------------------------------------- boyut adı

func _build_banner() -> void:
	banner_title = Label.new()
	banner_title.position = Vector2(0, 118)
	banner_title.size = Vector2(960, 40)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.add_theme_font_size_override("font_size", 30)
	banner_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.56))
	banner_title.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.04, 0.95))
	banner_title.add_theme_constant_override("outline_size", 7)
	banner_title.modulate.a = 0.0
	add_child(banner_title)

	banner_sub = Label.new()
	banner_sub.position = Vector2(0, 160)
	banner_sub.size = Vector2(960, 26)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.add_theme_font_size_override("font_size", 14)
	banner_sub.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	banner_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	banner_sub.add_theme_constant_override("outline_size", 4)
	banner_sub.modulate.a = 0.0
	add_child(banner_sub)

	var sub := {
		"valley": "kayıp vadi · kül ve sis",
		"under": "yer altı krallığı · Erlik'in gölgesi",
		"sky": "bulutların üstü · Ülgen'in yaylası",
	}
	banner_title.text = Game.realm_title(Game.realm)
	banner_sub.text = str(sub.get(Game.realm, ""))

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(banner_title, "modulate:a", 1.0, 0.6)
	tw.tween_property(banner_sub, "modulate:a", 1.0, 0.6)
	tw.set_parallel(false)
	tw.tween_interval(2.0)
	tw.set_parallel(true)
	tw.tween_property(banner_title, "modulate:a", 0.0, 0.9)
	tw.tween_property(banner_sub, "modulate:a", 0.0, 0.9)


func _refresh_hud() -> void:
	for c in hearts.get_children():
		c.queue_free()
	for i in Game.max_hp:
		var tr := TextureRect.new()
		tr.texture = Art.heart(i < Game.hp)
		tr.custom_minimum_size = Vector2(18, 16)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hearts.add_child(tr)
	coin_lbl.text = "x %d" % Game.coins
	potion_lbl.text = "x %d" % Game.potions
	realm_lbl.text = "◈  " + Game.realm_title(Game.realm)


func _refresh_quest() -> void:
	quest_lbl.text = "Görev: " + Game.quest_text()


# ------------------------------------------------------------------- boss bar

func _build_boss_bar() -> void:
	boss_panel = PanelContainer.new()
	boss_panel.add_theme_stylebox_override("panel", _box(Color(0.05, 0.03, 0.06, 0.92), Color(0.74, 0.3, 0.34)))
	boss_panel.position = Vector2(300, 450)
	boss_panel.size = Vector2(360, 58)
	boss_panel.custom_minimum_size = Vector2(360, 58)
	boss_panel.visible = false
	add_child(boss_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	boss_panel.add_child(vb)

	boss_name_lbl = Label.new()
	boss_name_lbl.add_theme_font_size_override("font_size", 14)
	boss_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.78))
	boss_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(boss_name_lbl)

	var bg := ColorRect.new()
	bg.color = Color(0.14, 0.06, 0.08, 0.95)
	bg.custom_minimum_size = Vector2(326, 10)
	vb.add_child(bg)

	boss_fill = ColorRect.new()
	boss_fill.color = Color(0.75, 0.2, 0.24)
	boss_fill.position = Vector2(2, 2)
	boss_fill.size = Vector2(322, 6)
	bg.add_child(boss_fill)


func _refresh_boss() -> void:
	var b = Game.boss
	var show: bool = b != null and is_instance_valid(b) and not b.dead and b.awake and b.hp > 0
	if boss_panel == null:
		return
	boss_panel.visible = show
	if not show:
		return
	boss_name_lbl.text = str(b.boss_name)
	var ratio := clampf(float(b.hp) / float(maxi(1, b.max_hp)), 0.0, 1.0)
	boss_fill.size = Vector2(322.0 * ratio, 6.0)


# -------------------------------------------------------------------- final

func _build_ending() -> void:
	ending_panel = PanelContainer.new()
	ending_panel.add_theme_stylebox_override("panel", _box(Color(0.03, 0.04, 0.06, 0.95), Color(0.95, 0.82, 0.5)))
	ending_panel.position = Vector2(200, 130)
	ending_panel.size = Vector2(560, 280)
	ending_panel.custom_minimum_size = Vector2(560, 280)
	ending_panel.visible = false
	ending_panel.modulate.a = 0.0
	add_child(ending_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	ending_panel.add_child(vb)

	var title := Label.new()
	title.text = "GÖK YAYLASI KURTULDU"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var body := Label.new()
	body.text = "Simurg düştü. Erlik'in gölgesi gökten ve yer altından çekildi.\nKül Vadisi ile Gök Yaylası yeniden aydınlık.\n\nAdın şarkılara geçti, yolcu."
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520, 160)
	vb.add_child(body)

	var hint2 := Label.new()
	hint2.text = "Keşfe devam edebilirsin · F5 kaydet"
	hint2.add_theme_font_size_override("font_size", 12)
	hint2.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	hint2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint2)


func _on_ending() -> void:
	banner_title.modulate.a = 0.0
	banner_sub.modulate.a = 0.0
	ending_panel.visible = true
	ending_panel.modulate.a = 0.0
	ending_panel.position = Vector2(200, 150)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ending_panel, "modulate:a", 1.0, 0.7)
	tw.tween_property(ending_panel, "position:y", 130.0, 0.7)
	tw.chain().tween_interval(4.5)
	tw.chain().tween_property(ending_panel, "modulate:a", 0.0, 1.0)
	tw.chain().tween_callback(func() -> void:
		ending_panel.visible = false
	)


# ------------------------------------------------------------------- diyalog

func _build_dialog() -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.add_theme_stylebox_override("panel", _box(Color(0.04, 0.05, 0.07, 0.95), Color(0.86, 0.74, 0.42)))
	dialog_panel.position = Vector2(48, 366)
	dialog_panel.size = Vector2(864, 148)
	dialog_panel.custom_minimum_size = Vector2(864, 148)
	dialog_panel.visible = false
	add_child(dialog_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	dialog_panel.add_child(vb)

	speaker_lbl = Label.new()
	speaker_lbl.add_theme_font_size_override("font_size", 15)
	speaker_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	vb.add_child(speaker_lbl)

	text_lbl = Label.new()
	text_lbl.add_theme_font_size_override("font_size", 18)
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.custom_minimum_size = Vector2(820, 58)
	text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(text_lbl)

	more_lbl = Label.new()
	more_lbl.add_theme_font_size_override("font_size", 12)
	more_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	more_lbl.text = "▼  E / SPACE"
	more_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	more_lbl.visible = false
	vb.add_child(more_lbl)


func _on_dialog_started(lines: Array) -> void:
	_lines.clear()
	for l in lines:
		_lines.append(str(l))
	_idx = 0
	dialog_panel.visible = true
	hint_lbl.visible = false
	_show_line()


func _show_line() -> void:
	if _lines.is_empty():
		return
	var raw := _lines[_idx]
	var speaker := ""
	var body := raw
	var pos := raw.find(": ")
	if pos > 0 and pos < 30:
		speaker = raw.substr(0, pos)
		body = raw.substr(pos + 2)
	speaker_lbl.text = speaker
	speaker_lbl.visible = speaker != ""
	text_lbl.text = body
	text_lbl.visible_characters = 0
	_chars = 0.0
	_typing = true
	more_lbl.visible = false


func _advance() -> void:
	if _typing:
		_typing = false
		text_lbl.visible_characters = -1
		more_lbl.visible = true
		return
	_idx += 1
	if _idx >= _lines.size():
		dialog_panel.visible = false
		Game.end_dialog()
	else:
		_show_line()


func _on_dialog_finished() -> void:
	dialog_panel.visible = false
	hint_lbl.visible = true


func _process(delta: float) -> void:
	_refresh_boss()
	if not _typing:
		return
	_chars += delta * 44.0
	text_lbl.visible_characters = int(_chars)
	_blip += delta
	if _blip >= 0.055:
		_blip = 0.0
		Sfx.play("talk", 1.2)
	if int(_chars) >= text_lbl.text.length():
		_typing = false
		text_lbl.visible_characters = -1
		more_lbl.visible = true


# --------------------------------------------------------------------- toast

func _build_toast() -> void:
	toast_lbl = Label.new()
	toast_lbl.position = Vector2(200, 292)
	toast_lbl.size = Vector2(560, 30)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.add_theme_font_size_override("font_size", 16)
	toast_lbl.add_theme_color_override("font_color", Color(1, 0.96, 0.86))
	toast_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	toast_lbl.add_theme_constant_override("outline_size", 5)
	toast_lbl.modulate.a = 0.0
	add_child(toast_lbl)


func _on_toast(text: String) -> void:
	toast_lbl.text = text
	toast_lbl.position = Vector2(200, 292)
	toast_lbl.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast_lbl, "modulate:a", 0.0, 0.6)
	_toast_tween.parallel().tween_property(toast_lbl, "position:y", 284.0, 0.6)


# -------------------------------------------------------------------- duraklat

func _build_pause() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.add_theme_stylebox_override("panel", _box(Color(0.03, 0.04, 0.06, 0.96), Color(0.7, 0.62, 0.4)))
	pause_panel.position = Vector2(280, 100)
	pause_panel.size = Vector2(400, 330)
	pause_panel.custom_minimum_size = Vector2(400, 330)
	pause_panel.visible = false
	add_child(pause_panel)

	var l := Label.new()
	l.add_theme_font_size_override("font_size", 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(368, 290)
	l.text = "DURAKLATILDI"
	pause_panel.add_child(l)
	pause_lbl = l


func _toggle_pause() -> void:
	if Game.dialog_active:
		return
	Game.paused = not Game.paused
	get_tree().paused = Game.paused
	pause_panel.visible = Game.paused
	if Game.paused:
		pause_lbl.text = "DURAKLATILDI\n\nBoyut: %s\nHedef: %s\n\nWASD hareket · SPACE saldırı\nE etkileşim · H iksir\nF5 kaydet · F9 yükle · F10 yeni oyun\nESC devam" % [
			Game.realm_title(Game.realm), Game.quest_text()
		]


# ---------------------------------------------------------------------- giriş

func _unhandled_input(event: InputEvent) -> void:
	if Game.dialog_active:
		if event.is_action_pressed(&"interact") or event.is_action_pressed(&"attack"):
			_advance()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"save"):
		Game.save_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"load"):
		if Game.load_game():
			Game.paused = false
			get_tree().paused = false
			get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"new_game"):
		Game.delete_save()
		Game.reset_state()
		Game.paused = false
		get_tree().paused = false
		get_tree().reload_current_scene()
		get_viewport().set_input_as_handled()


# --------------------------------------------------------------------- stil

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb
