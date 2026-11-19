class_name Portal
extends StaticBody2D

var target := "under"
var display_name := "Kapı"
var sprite: Sprite2D
var hint: Label


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactable")

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-11, -30)
	sprite.texture = Art.portal(Game.can_enter(target))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(16, 10)
	col.shape = box
	col.position = Vector2(0, -5)
	add_child(col)

	hint = Label.new()
	hint.text = display_name
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	hint.add_theme_constant_override("outline_size", 4)
	hint.position = Vector2(-45, -50)
	hint.size = Vector2(200, 26)
	hint.scale = Vector2(0.34, 0.34)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.visible = false
	add_child(hint)


func _process(_delta: float) -> void:
	if Game.player == null or hint == null:
		return
	hint.visible = global_position.distance_to(Game.player.global_position) < 70.0


func refresh() -> void:
	if sprite != null:
		sprite.texture = Art.portal(Game.can_enter(target))


func interact() -> void:
	if Game.dialog_active:
		return
	if not Game.can_enter(target):
		Game.toast.emit(Game.gate_hint(target))
		Sfx.play("hurt", 0.6)
		return
	Sfx.play("portal", 1.0)
	var main := get_tree().current_scene
	if main != null and main.has_method("load_realm"):
		main.call("load_realm", target)
