class_name Boss
extends CharacterBody2D
## İki boyutun efendisi: Karabasan (taş yağmuru + hücum) ve Simurg (tüy
## yelpazesi + dalış). Can barı UI'da gösterilir.

var kind := "karabasan"
var boss_name := "Karabasan"
var max_hp := 160
var hp := 160
var speed := 48.0
var touch_damage := 2
var sprite_w := 32
var sprite_h := 40

var awake := false
var dead := false
var sprite: Sprite2D
var frame := 0
var anim_t := 0.0

var _flash := 0.0
var _cast_cd := 2.4
var _charge_cd := 4.5
var _charge_t := 0.0
var _charge_dir := Vector2.ZERO
var _dive_cd := 5.0
var _dive_t := 0.0
var _dive_dir := Vector2.ZERO


func _ready() -> void:
	_configure()
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")
	add_to_group("boss")
	Game.boss = self
	_cast_cd = randf_range(1.5, 2.5)

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-sprite_w * 0.5, -sprite_h)
	sprite.texture = _texture(0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	col.shape = circle
	col.position = Vector2(0, -14 if kind == "simurg" else -10)
	add_child(col)


func _configure() -> void:
	if kind == "simurg":
		boss_name = "Simurg"
		max_hp = 210
		speed = 74.0
		touch_damage = 2
		sprite_w = 44
		sprite_h = 36
	else:
		boss_name = "Karabasan"
		max_hp = 160
		speed = 48.0
		touch_damage = 2
		sprite_w = 32
		sprite_h = 40
	hp = max_hp


func _texture(f: int) -> Texture2D:
	if kind == "simurg":
		return Art.simurg(f % 2)
	return Art.karabasan(f % 2)


func wake_up() -> void:
	if awake or dead:
		return
	awake = true
	Sfx.play("boss", 0.9)
	Game.toast.emit("%s uyandı!" % boss_name)


func _physics_process(delta: float) -> void:
	if dead or Game.paused:
		return

	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		sprite.modulate = Color(2.0, 0.8, 0.8, 1.0) if _flash > 0.0 else Color.WHITE
	else:
		sprite.modulate = Color.WHITE

	var target_player := Game.player
	if target_player == null or not is_instance_valid(target_player):
		velocity = Vector2.ZERO
		_animate(delta)
		return

	var to_p: Vector2 = target_player.global_position - global_position
	var dist := to_p.length()
	if not awake:
		if dist < 175.0:
			wake_up()
		velocity = Vector2.ZERO
		_animate(delta)
		return

	if Game.dialog_active:
		velocity = Vector2.ZERO
		_animate(delta)
		return

	if kind == "simurg":
		_simurg(target_player, to_p, dist, delta)
	else:
		_karabasan(target_player, to_p, dist, delta)

	move_and_slide()
	_animate(delta)
	queue_redraw()

	if dist < 22.0 and target_player.has_method("take_damage"):
		target_player.take_damage(touch_damage, global_position)


func _karabasan(target_player: Node2D, to_p: Vector2, dist: float, delta: float) -> void:
	if _charge_t > 0.0:
		_charge_t -= delta
		velocity = _charge_dir * 215.0
		return

	_charge_cd -= delta
	if _charge_cd <= 0.0 and dist < 190.0:
		_charge_cd = 5.2
		_charge_t = 0.34
		_charge_dir = to_p.normalized()
		Sfx.play("roar", 0.85)
		velocity = Vector2.ZERO
		return

	velocity = to_p.normalized() * speed if dist > 34.0 else Vector2.ZERO

	_cast_cd -= delta
	if _cast_cd <= 0.0:
		_cast_cd = 2.5 if hp < max_hp / 2 else 3.5
		fire()


func _simurg(target_player: Node2D, to_p: Vector2, dist: float, delta: float) -> void:
	if _dive_t > 0.0:
		_dive_t -= delta
		velocity = _dive_dir * 238.0
		return

	_dive_cd -= delta
	if _dive_cd <= 0.0 and dist < 210.0:
		_dive_cd = 5.6
		_dive_t = 0.5
		_dive_dir = to_p.normalized()
		Sfx.play("roar", 1.15)
		return

	if dist > 118.0:
		velocity = to_p.normalized() * speed
	elif dist < 68.0:
		velocity = -to_p.normalized() * speed
	else:
		velocity = to_p.normalized().rotated(PI * 0.5) * speed * 0.7

	_cast_cd -= delta
	if _cast_cd <= 0.0:
		_cast_cd = 1.6 if hp < max_hp / 2 else 2.4
		fire()


func fire() -> void:
	if dead:
		return
	var target_player := Game.player
	if target_player == null or not is_instance_valid(target_player):
		return
	var base := (target_player.global_position - global_position).normalized()

	if kind == "simurg":
		var count := 7 if hp < max_hp / 2 else 5
		for i in count:
			var spread := (float(i) - float(count - 1) * 0.5) * 0.15
			_shoot(base.rotated(spread), "feather", 152.0, 1)
		Sfx.play("feather", 1.0)
	else:
		var count2 := 5 if hp < max_hp / 2 else 3
		for i in count2:
			var spread2 := (float(i) - float(count2 - 1) * 0.5) * 0.19
			_shoot(base.rotated(spread2), "rock", 138.0, 1)
		Sfx.play("rock", 0.7)


func _shoot(dir: Vector2, shot_kind: String, spd: float, dmg: int) -> void:
	var proj := Projectile.new()
	proj.kind = shot_kind
	proj.dir = dir.normalized()
	proj.speed = spd
	proj.damage = dmg
	proj.position = global_position + Vector2(0, -14) + dir.normalized() * 15.0
	get_tree().current_scene.add_child(proj)


func _animate(delta: float) -> void:
	anim_t += delta
	if anim_t >= 0.26:
		anim_t = 0.0
		frame = (frame + 1) % 2
		sprite.texture = _texture(frame)
	var bob := sin(Time.get_ticks_msec() / 260.0) * (2.0 if kind == "simurg" else 1.0)
	sprite.position = Vector2(0, bob)


func take_damage(amount: int, from: Vector2) -> void:
	if dead:
		return
	if not awake:
		wake_up()
	hp -= amount
	_flash = 0.12
	Sfx.play("hit", 0.85)
	_float_text("-%d" % amount, Color(1.0, 0.9, 0.6))
	var p = Game.player
	if p != null and is_instance_valid(p) and p.has_method("shake"):
		p.shake(3.0)

	var away := global_position - from
	if away.length() > 0.01:
		velocity += away.normalized() * 24.0

	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	remove_from_group("boss")
	Game.boss = null

	Sfx.play("death", 0.55)
	Game.coins += 40
	Game.potions += 2
	Game.hud_changed.emit()
	Game.on_boss_defeated(kind)
	var p = Game.player
	if p != null and is_instance_valid(p) and p.has_method("shake"):
		p.shake(11.0)
	_float_text("+40 altın", Color(0.98, 0.82, 0.35))

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.9, 0.15), 0.35)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(queue_free)


func _float_text(txt: String, col: Color) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.z_index = 60
	root.add_child(lbl)
	lbl.position = global_position + Vector2(-12, -sprite_h - 22)
	var y0 := lbl.position.y
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", y0 - 22.0, 0.9)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)


func _draw() -> void:
	if dead or hp >= max_hp:
		return
	var top := -float(sprite_h) - 8.0
	draw_rect(Rect2(-15, top, 30, 4), Color(0, 0, 0, 0.6))
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(-14, top + 1, 28.0 * ratio, 2.0), Color(0.9, 0.28, 0.3))
