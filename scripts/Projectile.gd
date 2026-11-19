class_name Projectile
extends Area2D
## Düşman ve boss mermileri. Duvarlara çarpar, oyuncuya hasar verir.

var kind := "rock"
var dir := Vector2.DOWN
var speed := 130.0
var damage := 1
var life := 3.0

var sprite: Sprite2D
var _hit := false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 2
	monitoring = true
	monitorable = false
	z_index = 25

	sprite = Sprite2D.new()
	sprite.texture = Art.feather_shot() if kind == "feather" else Art.rock_shot()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.rotation = dir.angle()
	sprite.scale = Vector2(0.7, 0.7)
	add_child(sprite)

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	col.shape = circle
	add_child(col)

	body_entered.connect(_on_body_entered)

	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.12)


func _physics_process(delta: float) -> void:
	if Game.paused or _hit:
		return
	position += dir * speed * delta
	life -= delta
	if kind == "rock":
		sprite.rotation += 9.0 * delta
	else:
		sprite.rotation = dir.angle() + sin(Time.get_ticks_msec() / 90.0) * 0.18
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body is Player:
		_hit = true
		body.take_damage(damage, global_position)
		queue_free()
	elif body is StaticBody2D:
		_hit = true
		queue_free()
