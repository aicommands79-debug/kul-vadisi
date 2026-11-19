class_name Npc
extends StaticBody2D

var sprite: Sprite2D
var name_lbl: Label


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -24)
	sprite.texture = Art.character("npc", "down", 0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(11, 8)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)

	name_lbl = Label.new()
	name_lbl.text = "Bekçi Duran"
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.position = Vector2(-33, -34)
	name_lbl.size = Vector2(200, 26)
	name_lbl.scale = Vector2(0.33, 0.33)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_lbl)


func interact() -> void:
	if Game.dialog_active:
		return

	match Game.step:
		0:
			Game.start_dialog([
				"Bekçi Duran: Hoş geldin yolcu. Kül Vadisi eskiden Ülgen'in koruduğu bereketli bir yerdi.",
				"Erlik'in gölgesi göletin altından sızdı. Önce balçıklar tarlaları bastı.",
				"Üç balçığı temizle; sana Yer Altı Kapısı'nın mührünü açayım.",
			], func() -> void:
				Game.step = 1
				Game.quest_changed.emit()
				Game.toast.emit("Görev alındı: 3 balçık temizle")
			)
		1:
			var left := maxi(0, Game.slimes_needed - Game.slime_kills)
			if left > 0:
				Game.start_dialog([
					"Bekçi Duran: Güneydoğuda, gölün altındaki çalılıklarda %d balçık daha var." % left,
					"Kılıç arkınla vur: SPACE. Canın azalırsa H ile iksir iç.",
				])
			else:
				Game.start_dialog([
					"Bekçi Duran: Üçü de düştü. Vadi bir nefes aldı.",
					"Al şu 25 altını, bir de iksir. Şimdi mühürü açıyorum.",
					"Kuzeydoğudaki Yer Altı Kapısı'ndan in. Orada Karabasan seni bekliyor.",
				], func() -> void:
					Game.step = 2
					Game.coins += 25
					Game.potions += 1
					Game.hud_changed.emit()
					Game.quest_changed.emit()
					Game.save_game()
					Game.toast.emit("Görev tamam: +25 altın, +1 iksir · Yer Altı Kapısı açıldı")
				)
		2:
			Game.start_dialog([
				"Bekçi Duran: Karabasan uykusunda bile korku salar. Kılıcın onun Kara Kor'unu alsın.",
				"Yer Altı Kapısı kuzeydoğuda, ağaçların arasında. Kara Kor kılıcını güçlendirir.",
			])
		3:
			Game.start_dialog([
				"Bekçi Duran: Karabasan düştü demek... Kara Kor avucunda, ışığı karanlığı kesiyor.",
				"Şimdi doğudaki Gök Kapısı açıldı. Simurg, Ülgen'in yaylasını koruyor.",
				"Kanatlarına dikkat et; tüyleri kılıç gibi yağar.",
			])
		_:
			Game.start_dialog([
				"Bekçi Duran: Simurg da düştü... Gök yaylası yeniden aydınlık.",
				"Vadi sana borçlu, yolcu. Adın şarkılara geçecek.",
				"Ama Erlik tam ölmedi. Sadece geri çekildi. Bir gün yine gelecek.",
			])
