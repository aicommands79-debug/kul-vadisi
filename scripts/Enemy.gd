class_name Enemy
extends CharacterBody2D
## Dört düşman tipi: balçık (yakın), kor (hızlı), sürel (taş atar),
## tepegöz (ağır, çevresine taş saçar). Boyutlar arasında aynı betik kullanılır.

var kind := "slime"

var max_hp := 20
var hp := 20
var speed := 46.0
var aggro_range := 116.0
var touch_damage := 1
var coin_min := 1
var coin_max := 3
var sprite_w := 16
var sprite_h := 16

var home := Vector2.ZERO
var wander_target := Vector2.ZERO
var wander_t := 0.0

var frame := 0
var anim_t := 0.0
var dead := false
var sprite: Sprite2D

var cast_kind := ""
var cast_cd := 0.0
var cast_interval := 2.0
var cast_range := 0.0

var _flash := 0.0
var _flash_col := Color(1.9, 0.65, 0.65, 1.0)


func _ready() -> void:
	_configure()
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")
	home = global_position
	wander_target = global_position
	cast_cd = randf_range(0.6, 1.6)

	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-sprite_w * 0.5, -sprite_h)
	sprite.texture = _texture(0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0 if kind != "tepegos" else 8.0
	col.shape = circle
	col.position = Vector2(0, -7)
	add_child(col)


func _configure() -> void:
	match kind:
		"imp":
			max_hp = 24
			speed = 64.0
			aggro_range = 150.0
			touch_damage = 1
			coin_min = 2
			coin_max = 4
			sprite_w = 14
			sprite_h = 14
		"surel":
			max_hp = 46
			speed = 28.0
			aggro_range = 140.0
			touch_damage = 1
			coin_min = 3
			coin_max = 6
			sprite_w = 16
			sprite_h = 20
			cast_kind = "rock"
			cast_interval = 1.9
			cast_range = 155.0
		"tepegos":
			max_hp = 72
			speed = 32.0
			aggro_range = 145.0
			touch_damage = 2
			coin_min = 5
			coin_max = 8
			sprite_w = 18
			sprite_h = 22
			cast_kind = "slam"
			cast_interval = 3.1
			cast_range = 120.0
		_:
			max_hp = 20
			speed = 46.0
			aggro_range = 112.0
			touch_damage = 1
			coin_min = 1
			coin_max = 3
			sprite_w = 16
			sprite_h = 16
	hp = max_hp


func _texture(f: int) -> Texture2D:
	match kind:
		"imp":
			return Art.imp(f)
		"surel":
			return Art.surel(f)
		"tepegos":
			return Art.tepegos(f)
		_:
			return Art.slime(f % 2)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if Game.paused:
		return

	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		sprite.modulate = _flash_col if _flash > 0.0 else Color.WHITE
	else:
		sprite.modulate = Color.WHITE

	if Game.dialog_active:
		velocity = Vector2.ZERO
		_animate(delta)
		return

	var target_player := Game.player
	if target_player != null and is_instance_valid(target_player):
		var to_p: Vector2 = target_player.global_position - global_position
		var dist := to_p.length()
		if dist < aggro_range:
			_track(target_player, to_p, dist, delta)
			if dist < 16.0 and target_player.has_method("take_damage"):
				target_player.take_damage(touch_damage, global_position)
		else:
			_wander(delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_animate(delta)
	queue_redraw()


func _track(target_player: Node2D, to_p: Vector2, dist: float, delta: float) -> void:
	match kind:
		"surel":
			if dist < 66.0:
				velocity = -to_p.normalized() * speed
			elif dist > 112.0:
				velocity = to_p.normalized() * speed
			else:
				velocity = to_p.normalized().rotated(PI * 0.5) * speed * 0.6
			_try_cast(target_player, dist, delta)
		"tepegos":
			velocity = to_p.normalized() * speed if dist > 26.0 else Vector2.ZERO
			_try_cast(target_player, dist, delta)
		"imp":
			var wobble := sin(Time.get_ticks_msec() / 180.0) * 0.45
			velocity = to_p.normalized().rotated(wobble) * speed
		_:
			velocity = to_p.normalized() * speed


func _try_cast(target_player: Node2D, dist: float, delta: float) -> void:
	if cast_kind == "" or cast_range <= 0.0:
		return
	if dist > cast_range:
		return
	cast_cd -= delta
	if cast_cd > 0.0:
		return
	cast_cd = cast_interval * randf_range(0.85, 1.2)

	if cast_kind == "rock":
		var dir := (target_player.global_position - global_position).normalized()
		dir = dir.rotated(randf_range(-0.09, 0.09))
		_spawn_shot(dir, "rock", 128.0, 1)
		Sfx.play("rock", 1.25)
	elif cast_kind == "slam":
		for i in 6:
			_spawn_shot(Vector2.RIGHT.rotated(TAU * float(i) / 6.0), "rock", 96.0, 1)
		Sfx.play("rock", 0.75)
		sprite.modulate = Color(1.6, 1.2, 0.9, 1.0)


func _spawn_shot(dir: Vector2, shot_kind: String, spd: float, dmg: int) -> void:
	var proj := Projectile.new()
	proj.kind = shot_kind
	proj.dir = dir.normalized()
	proj.speed = spd
	proj.damage = dmg
	proj.position = global_position + Vector2(0, -8) + dir.normalized() * 8.0
	get_tree().current_scene.add_child(proj)


func _wander(delta: float) -> void:
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(1.8, 3.4)
		var a := randf() * TAU
		wander_target = home + Vector2(cos(a), sin(a)) * randf_range(6.0, 42.0)
	var d := wander_target - global_position
	if d.length() > 4.0:
		velocity = d.normalized() * speed * 0.4
	else:
		velocity = Vector2.ZERO


func _animate(delta: float) -> void:
	anim_t += delta
	var step := 0.32 if kind == "tepegos" else 0.22
	if anim_t >= step:
		anim_t = 0.0
		frame = (frame + 1) % 3
		sprite.texture = _texture(frame)


func take_damage(amount: int, from: Vector2) -> void:
	if dead:
		return
	hp -= amount
	_flash = 0.14
	Sfx.play("hit")
	_float_text("-%d" % amount, Color(1.0, 0.92, 0.65))

	var away := global_position - from
	if away.length() < 0.01:
		away = Vector2(0, -1)
	velocity = away.normalized() * 180.0
	move_and_slide()

	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	Sfx.play("death", 0.9)
	if kind == "slime":
		Game.on_slime_killed()

	var drop := randi_range(coin_min, coin_max)
	Game.coins += drop
	var got_potion := randf() < 0.12
	if got_potion:
		Game.potions += 1
	Game.hud_changed.emit()
	_float_text("+%d altın" % drop, Color(0.98, 0.82, 0.35))

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(1.5, 0.2), 0.2)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)


func _float_text(txt: String, col: Color) -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.z_index = 60
	root.add_child(lbl)
	lbl.position = global_position + Vector2(-9, -sprite_h - 16)
	var y0 := lbl.position.y
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", y0 - 18.0, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tw.chain().tween_callback(lbl.queue_free)


func _draw() -> void:
	if dead or hp >= max_hp:
		return
	var top := -float(sprite_h) - 6.0
	draw_rect(Rect2(-8, top, 16, 3), Color(0, 0, 0, 0.55))
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(-7, top + 1, 14.0 * ratio, 1.5), Color(0.86, 0.32, 0.36))
