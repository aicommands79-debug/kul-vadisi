class_name Sign
extends StaticBody2D

var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	sprite.texture = Art.sign()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 8)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)


func interact() -> void:
	if Game.dialog_active:
		return
	Game.start_dialog([
		"Tabela: «Kül Vadisi»",
		"Hareket: WASD veya oklar. Saldırı: SPACE.",
		"Konuş / aç: E.  İksir: H.  Kaydet: F5.  Yükle: F9.",
	])
