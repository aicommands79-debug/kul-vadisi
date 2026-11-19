class_name Shrine
extends StaticBody2D
## Umay Sunağı: her boyutta bir kez +2 kalıcı can verir.

var id := "shrine"
var used := false
var sprite: Sprite2D
var name_lbl: Label
var _t := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")

	used = Game.shrines_used.has(id)

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -24)
	sprite.texture = Art.shrine(used)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 8)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)

	name_lbl = Label.new()
	name_lbl.text = "Umay Sunağı"
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.62))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.position = Vector2(-36, -38)
	name_lbl.size = Vector2(200, 26)
	name_lbl.scale = Vector2(0.33, 0.33)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.visible = false
	add_child(name_lbl)


func _process(delta: float) -> void:
	_t += delta
	if not used:
		var s := 1.0 + 0.1 * (0.5 + 0.5 * sin(_t * 3.4))
		sprite.modulate = Color(s, s, s * 0.95, 1.0)
	if Game.player != null and is_instance_valid(Game.player):
		name_lbl.visible = global_position.distance_to(Game.player.global_position) < 62.0


func interact() -> void:
	if Game.dialog_active:
		return
	if used:
		Game.start_dialog([
			"Umay Sunağı: Alev çoktan söndü. Kutsama bir kez verilir.",
		])
		return

	Game.start_dialog([
		"Umay Sunağı: Gök Tanrıça'nın ateşi hâlâ yanıyor.",
		"Sıcak ışık yaralarını sarıyor, yüreğine dayanıklılık veriyor.",
	], func() -> void:
		used = true
		Game.shrines_used[id] = true
		sprite.texture = Art.shrine(true)
		Sfx.play("shrine")
		Game.bless(2)
		Game.save_game()
	)
