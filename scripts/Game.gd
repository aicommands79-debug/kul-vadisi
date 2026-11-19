extends Node
## Oyun durumu: boyut, hikâye adımı, kayıt/yükleme, diyalog akışı.

signal hud_changed
signal quest_changed
signal toast(text: String)
signal dialog_started(lines: Array)
signal dialog_finished
signal realm_entered(id: String)
signal ending_reached

const SAVE_PATH := "user://save.json"

const REALM_NAMES := {
	"valley": "Kül Vadisi",
	"under": "Erlik'in Karanlığı",
	"sky": "Ülgen'in Gök Yaylası",
}

var realm := "valley"
var step := 0                  # 0 konuş · 1 balçık · 2 yeraltı · 3 gök · 4 bitti
var slimes_needed := 3
var slime_kills := 0

var max_hp := 6
var hp := 6
var coins := 0
var potions := 1
var damage := 10

var chests_opened := {}
var shrines_used := {}
var bosses := {}

var dialog_active := false
var paused := false
var booted := false
var player: Node2D = null
var boss = null
var spawn_point := Vector2.ZERO
var saved_pos := Vector2.ZERO

var _on_dialog_done := Callable()


func _ready() -> void:
	_setup_input()


func _setup_input() -> void:
	_bind(&"move_left", [KEY_A, KEY_LEFT])
	_bind(&"move_right", [KEY_D, KEY_RIGHT])
	_bind(&"move_up", [KEY_W, KEY_UP])
	_bind(&"move_down", [KEY_S, KEY_DOWN])
	_bind(&"attack", [KEY_SPACE, KEY_J])
	_bind(&"interact", [KEY_E, KEY_ENTER])
	_bind(&"potion", [KEY_H])
	_bind(&"save", [KEY_F5])
	_bind(&"load", [KEY_F9])
	_bind(&"new_game", [KEY_F10])
	_bind(&"pause", [KEY_ESCAPE])


func _bind(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


# ------------------------------------------------------------------- hikâye

func realm_title(id: String) -> String:
	return REALM_NAMES.get(id, id)


func quest_text() -> String:
	match step:
		0:
			return "Bekçi Duran ile konuş"
		1:
			if slime_kills < slimes_needed:
				return "Balçıkları temizle  %d/%d" % [mini(slime_kills, slimes_needed), slimes_needed]
			return "Bekçi Duran'a dön"
		2:
			return "Yer Altı Kapısı'ndan geç · Karabasan'ı bul"
		3:
			return "Gök Kapısı'ndan geç · Simurg'u bul"
		_:
			return "Vadi kurtuldu ✓"


func can_enter(realm_id: String) -> bool:
	match realm_id:
		"under":
			return step >= 2
		"sky":
			return bosses.has("karabasan")
		_:
			return true


func gate_hint(realm_id: String) -> String:
	match realm_id:
		"under":
			return "Kapı mühürlü. Önce Bekçi Duran ile konuş."
		"sky":
			return "Gök Kapısı mühürlü. Yer Altı'nın efendisini yen."
		_:
			return ""


func on_slime_killed() -> void:
	slime_kills += 1
	quest_changed.emit()
	if step == 1 and slime_kills == slimes_needed:
		toast.emit("Balçıklar temizlendi. Bekçiye dön.")
		save_game()


func on_boss_defeated(kind: String) -> void:
	if bosses.has(kind):
		return
	bosses[kind] = true
	if kind == "karabasan":
		step = 3
		damage += 5
		toast.emit("Kara Kor elde edildi! Kılıcın güçlendi (+5).")
	elif kind == "simurg":
		step = 4
		max_hp += 2
		hp = max_hp
		toast.emit("Simurg'un tüyü: +2 can. Gök yaylası aydınlandı.")
	boss = null
	quest_changed.emit()
	hud_changed.emit()
	save_game()
	if kind == "simurg":
		ending_reached.emit()


func bless(amount: int) -> void:
	max_hp += amount
	hp = max_hp
	hud_changed.emit()
	toast.emit("Umay'ın kutsaması: +%d can" % amount)


# ------------------------------------------------------------------- diyalog

func start_dialog(lines: Array, on_done: Callable = Callable()) -> void:
	_on_dialog_done = on_done
	dialog_active = true
	dialog_started.emit(lines)


func end_dialog() -> void:
	dialog_active = false
	dialog_finished.emit()
	var cb := _on_dialog_done
	_on_dialog_done = Callable()
	if cb.is_valid():
		cb.call()


# -------------------------------------------------------------------- durum

func reset_state() -> void:
	realm = "valley"
	step = 0
	slime_kills = 0
	max_hp = 6
	hp = 6
	coins = 0
	potions = 1
	damage = 10
	chests_opened = {}
	shrines_used = {}
	bosses = {}
	dialog_active = false
	paused = false
	boss = null
	saved_pos = Vector2.ZERO
	_on_dialog_done = Callable()
	hud_changed.emit()
	quest_changed.emit()


# ------------------------------------------------------------ kayıt / yükleme

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func save_game() -> bool:
	var px := spawn_point.x
	var py := spawn_point.y
	if player != null:
		px = player.position.x
		py = player.position.y
	var data := {
		"version": 2,
		"realm": realm,
		"pos": [px, py],
		"step": step,
		"slime_kills": slime_kills,
		"max_hp": max_hp,
		"hp": hp,
		"coins": coins,
		"potions": potions,
		"damage": damage,
		"chests": chests_opened,
		"shrines": shrines_used,
		"bosses": bosses,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Kayit dosyasi acilamadi.")
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	toast.emit("Oyun kaydedildi.")
	return true


func load_game() -> bool:
	if not has_save():
		toast.emit("Kayit bulunamadi.")
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		toast.emit("Kayit bozuk.")
		return false

	var d: Dictionary = parsed
	if int(d.get("version", 0)) < 2:
		toast.emit("Eski kayıt sürümü; yeni oyun başlatılıyor.")
		return false
	realm = str(d.get("realm", "valley"))
	step = int(d.get("step", 0))
	slime_kills = int(d.get("slime_kills", 0))
	max_hp = int(d.get("max_hp", 6))
	hp = int(d.get("hp", max_hp))
	coins = int(d.get("coins", 0))
	potions = int(d.get("potions", 1))
	damage = int(d.get("damage", 10))

	var ps: Variant = d.get("pos", [0.0, 0.0])
	if typeof(ps) == TYPE_ARRAY and (ps as Array).size() == 2:
		saved_pos = Vector2(float(ps[0]), float(ps[1]))
	else:
		saved_pos = Vector2.ZERO

	var ch: Variant = d.get("chests", {})
	chests_opened = ch if typeof(ch) == TYPE_DICTIONARY else {}
	var sh: Variant = d.get("shrines", {})
	shrines_used = sh if typeof(sh) == TYPE_DICTIONARY else {}
	var bo: Variant = d.get("bosses", {})
	bosses = bo if typeof(bo) == TYPE_DICTIONARY else {}

	hud_changed.emit()
	quest_changed.emit()
	return true
