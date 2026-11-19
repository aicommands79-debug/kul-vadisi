class_name Player
extends CharacterBody2D

const SPEED := 96.0

var facing := "down"
var anim_frame := 0
var anim_t := 0.0
var moving := false
var invuln := 0.0
var attack_cd := 0.0

var sprite: Sprite2D
var slash: Sprite2D
var cam: Camera2D

var _shake := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -24)
	sprite.texture = Art.character("player", facing, 0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(10, 8)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)

	slash = Sprite2D.new()
	slash.texture = Art.slash()
	slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slash.visible = false
	slash.z_index = 30
	add_child(slash)

	cam = Camera2D.new()
	cam.zoom = Vector2(3, 3)
	cam.position = Vector2(0, -10)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	add_child(cam)
	cam.make_current()


func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
	invuln = maxf(0.0, invuln - delta)

	if Game.dialog_active or Game.paused:
		velocity = Vector2.ZERO
		moving = false
		_update_anim(delta)
		return

	var input := Vector2(
		Input.get_action_strength(&"move_right") - Input.get_action_strength(&"move_left"),
		Input.get_action_strength(&"move_down") - Input.get_action_strength(&"move_up")
	)
	moving = input.length() > 0.15
	if moving:
		input = input.normalized()
		velocity = input * SPEED
		_set_facing(input)
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	_update_anim(delta)

	if Input.is_action_just_pressed(&"attack"):
		_attack()
	if Input.is_action_just_pressed(&"interact"):
		_interact()
	if Input.is_action_just_pressed(&"potion"):
		_use_potion()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 24.0)
		cam.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		cam.offset = Vector2.ZERO

	if invuln > 0.0:
		sprite.modulate.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() / 55.0))
	else:
		sprite.modulate.a = 1.0


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func facing_vector() -> Vector2:
	match facing:
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
		"left":
			return Vector2.LEFT
		_:
			return Vector2.RIGHT


func _set_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0.0 else "left"
	else:
		facing = "down" if dir.y > 0.0 else "up"


func _update_anim(delta: float) -> void:
	if moving:
		anim_t += delta
		if anim_t >= 0.15:
			anim_t = 0.0
			anim_frame = 1 if anim_frame != 1 else 2
	else:
		anim_frame = 0
		anim_t = 0.0
	sprite.texture = Art.character("player", facing, anim_frame)


func _attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.34
	Sfx.play("swing")

	var dir := facing_vector()
	var kara_kor := Game.bosses.has("karabasan")
	slash.visible = true
	slash.position = dir * 10.0 + Vector2(0, -10)
	slash.rotation = dir.angle()
	slash.scale = Vector2(0.8, 0.8)
	slash.modulate = Color(1.0, 0.88, 0.52, 1.0) if kara_kor else Color.WHITE
	slash.modulate.a = 1.0

	var tw := create_tween()
	tw.tween_property(slash, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func() -> void:
		slash.visible = false
		slash.modulate.a = 1.0
	)

	var origin := global_position + Vector2(0, -8)
	var dmg := Game.damage
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - origin
		if to_e.length() <= 29.0 and to_e.normalized().dot(dir) > 0.22:
			if e.has_method("take_damage"):
				e.take_damage(dmg, global_position)


func _interact() -> void:
	var best: Node = null
	var best_d := 36.0
	for n in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(n):
			continue
		var d: float = n.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = n
	if best != null and best.has_method("interact"):
		best.interact()


func _use_potion() -> void:
	if Game.potions <= 0:
		Game.toast.emit("İksirin kalmadı.")
		return
	if Game.hp >= Game.max_hp:
		Game.toast.emit("Canın zaten dolu.")
		return
	Game.potions -= 1
	Game.hp = mini(Game.max_hp, Game.hp + 3)
	Sfx.play("heal")
	Game.hud_changed.emit()
	Game.toast.emit("İksir içtin (+3 can)")


func take_damage(amount: int, from: Vector2) -> void:
	if invuln > 0.0 or Game.hp <= 0:
		return
	Game.hp = maxi(0, Game.hp - amount)
	Game.hud_changed.emit()
	invuln = 0.9
	shake(5.0)
	Sfx.play("hurt")

	var away := global_position - from
	if away.length() < 0.01:
		away = Vector2(0, 1)
	velocity = away.normalized() * 170.0
	move_and_slide()

	if Game.hp <= 0:
		_die()


func _die() -> void:
	Sfx.play("death", 0.7)
	Game.toast.emit("Yenildin... bu boyutun girişinde uyandın.")
	Game.hp = Game.max_hp
	Game.coins = maxi(0, Game.coins - 5)
	Game.hud_changed.emit()
	global_position = Game.spawn_point
	Game.saved_pos = Game.spawn_point
	invuln = 1.6
