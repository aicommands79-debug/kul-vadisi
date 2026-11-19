class_name Chest
extends StaticBody2D

var id := "chest"
var loot_coins := 10
var loot_potion := 0
var opened := false

var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")
	add_to_group("chests")

	opened = Game.chests_opened.has(id)

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	sprite.texture = Art.chest(opened)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(13, 9)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)


func refresh() -> void:
	opened = Game.chests_opened.has(id)
	if sprite != null:
		sprite.texture = Art.chest(opened)


func interact() -> void:
	if Game.dialog_active:
		return
	if opened:
		Game.toast.emit("Sandık boş.")
		return

	opened = true
	Game.chests_opened[id] = true
	sprite.texture = Art.chest(true)
	Sfx.play("chest")

	Game.coins += loot_coins
	if loot_potion > 0:
		Game.potions += loot_potion
	Game.hud_changed.emit()

	if loot_potion > 0:
		Game.toast.emit("+%d altın, +%d iksir" % [loot_coins, loot_potion])
	else:
		Game.toast.emit("+%d altın" % loot_coins)

	Game.save_game()
