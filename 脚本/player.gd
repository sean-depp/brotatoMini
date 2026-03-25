extends Area2D

signal hit

@export var speed = 300 # How fast the player will move (pixels/sec).
@export var max_speed = 1000 # 最大速度限制
var screen_size # Size of the game window.

# 血量系统（数值型血条）
var max_health: int = 1
var current_health: int = 1
var is_dead: bool = false

# 无敌状态闪烁
var is_invincible: bool = false

# 武器系统：同时挂载多把枪（最多 `max_weapons`）
@export var max_weapons: int = 6
# 左右各三点，依次从上到下右侧再左侧
@export var weapon_offsets := [
	Vector2(40, -16),
	Vector2(40, 0),
	Vector2(40, 16),
	Vector2(-40, -16),
	Vector2(-40, 0),
	Vector2(-40, 16)
]
var weapons: Array = []
var weapon_scene = preload("res://武器/weapon.tscn")
var shotgun_scene = preload("res://武器/shotgun.tscn")  # 霰弹枪场景

func _ready() -> void:
	# 地图大小 2560x1440（2K）
	screen_size = Vector2(2560, 1440)
	add_weapon()
	
	# 将玩家添加到 "player" 组，方便怪物找到玩家
	add_to_group("player")
	
	hide()

func _physics_process(delta: float) -> void:
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("up"):
		velocity.y -= 1

	# 面向鼠标方向
	# look_at(get_global_mouse_position())

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	# 确保玩家不会离开屏幕边界（地图边界），考虑玩家角色大小避免半个身子超出边界
	# 假设玩家角色大小约为32x32像素，留出16像素的边距
	var margin = 16.0
	var min_pos = Vector2(margin, margin)
	var max_pos = Vector2(screen_size.x - margin, screen_size.y - margin)
	position = position.clamp(min_pos, max_pos)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
	
	# 无敌状态闪烁效果（使用透明度，不影响碰撞检测）
	if is_invincible:
		# 使用时间来实现闪烁，每0.1秒切换一次透明度
		var flash_visible = int(Time.get_ticks_msec() / 100.0) % 2 == 0
		if flash_visible:
			$AnimatedSprite2D.modulate.a = 1.0  # 完全不透明
		else:
			$AnimatedSprite2D.modulate.a = 0.3  # 半透明
	else:
		$AnimatedSprite2D.modulate.a = 1.0  # 确保正常状态下不透明

func under_hurt() -> void:
	# 如果已经无敌，不再受伤
	if is_invincible:
		return
	
	# 使用数值型血条系统
	take_damage(1)
	
	# 更新HUD血条显示
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("update_health_bar"):
		hud.update_health_bar(current_health, max_health)
	
	#hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	# 如果在引擎的碰撞处理过程中禁用区域的碰撞形状可能会导致错误。
	# 使用 set_deferred() 告诉 Godot 等待可以安全地禁用形状时再这样做。
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 启动无敌状态和闪烁效果
	is_invincible = true

	$InvincibilityTimer.wait_time = 1
	$InvincibilityTimer.start()

func _on_body_entered(_body: Node2D) -> void:
	under_hurt()

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	
	# 重置生命值状态
	is_dead = false
	current_health = max_health

func _on_invincibility_timer_timeout() -> void:
	$CollisionShape2D.set_deferred("disabled", false)
	# 结束无敌状态，恢复精灵透明度
	is_invincible = false
	$AnimatedSprite2D.modulate.a = 1.0


# 在玩家身上添加一把武器实例（冲锋枪，不会检查货币）
func add_weapon() -> bool:
	if weapons.size() >= max_weapons:
		return false
	var w = weapon_scene.instantiate()
	add_child(w)
	w.name = "Weapon%d" % (weapons.size() + 1)
	# 放置到预设偏移位置（如果有）
	if weapon_offsets.size() > weapons.size():
		w.position = weapon_offsets[weapons.size()]
	weapons.append(w)
	return true

# 在玩家身上添加一把霰弹枪实例（不会检查货币）
func add_shotgun() -> bool:
	if weapons.size() >= max_weapons:
		return false
	var w = shotgun_scene.instantiate()
	add_child(w)
	w.name = "Shotgun%d" % (weapons.size() + 1)
	# 放置到预设偏移位置（如果有）
	if weapon_offsets.size() > weapons.size():
		w.position = weapon_offsets[weapons.size()]
	weapons.append(w)
	return true

# 重置武器系统：删除所有武器并重新添加初始武器
func reset_weapons() -> void:
	# 删除所有现有武器
	for weapon in weapons:
		if is_instance_valid(weapon):
			weapon.queue_free()
	weapons.clear()
	
	# 重新添加初始武器
	add_weapon()
	
	# 重置所有武器的加成属性到初始值
	for weapon in weapons:
		if weapon.has_method("reset_bonuses"):
			weapon.reset_bonuses()
		elif weapon.has_method("reset_damage"):
			# 兼容旧方法
			weapon.reset_damage()

# 设置最大生命值
func set_max_health(new_max: int) -> void:
	max_health = new_max
	if current_health > max_health:
		current_health = max_health

# 设置当前生命值
func set_health(health: int) -> void:
	if health < 0:
		health = 0
	if health > max_health:
		health = max_health
	current_health = health

# 增加生命值
func add_health(amount: int) -> void:
	set_health(current_health + amount)

# 减少生命值
func subtract_health(amount: int) -> void:
	set_health(current_health - amount)

# 获取当前生命值
func get_health() -> int:
	return current_health

# 获取最大生命值
func get_max_health() -> int:
	return max_health

# 玩家受伤函数
func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	current_health -= amount
	
	# 检查是否死亡
	if current_health <= 0:
		die()

# 玩家死亡函数
func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	# 禁用碰撞
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 停止移动
	hide()
	
	# 发出死亡信号
	hit.emit()

# 增加移动速度
func increase_speed(amount: float) -> bool:
	if speed < max_speed:
		speed += amount
		return true
	return false

# 获取当前速度
func get_speed() -> float:
	return speed

# 重置速度到初始值
func reset_speed() -> void:
	speed = 300
