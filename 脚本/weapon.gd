extends Node2D
class_name Weapon

# 子弹场景
@export var bullet_scene: PackedScene

# ==================== 武器基础属性（武器固有，不同武器类型不同）====================
# 基础伤害
@export var base_damage: int = 1
# 基础射击间隔（秒）
@export var base_fire_interval: float = 0.5
# 基础射程
@export var base_range: float = 200.0
# 子弹数量（霰弹枪用）
@export var bullet_count: int = 1
# 散射角度（度数，子弹之间的夹角）
@export var spread_angle: float = 0.0

# ==================== 玩家升级加成属性（通过商店升级）====================
# 伤害加成
var damage_bonus: int = 0
# 攻速加成（每秒攻击次数的增加值）
var fire_rate_bonus: float = 0.0
# 射程加成
var range_bonus: float = 0.0
# 爆炸范围加成（用于榴弹枪等爆炸武器）
var explosion_radius_bonus: float = 0.0

# ==================== 属性上限 ====================
@export var max_damage_bonus: int = 9  # 最大伤害加成（总伤害 = base_damage + damage_bonus，最高10）
@export var max_fire_rate: float = 100.0  # 最大攻速（每秒100次）
@export var max_range: float = 1000.0  # 最大射程
@export var max_explosion_radius_bonus: float = 200.0  # 最大爆炸范围加成

# ==================== 运行时变量 ====================
var can_shoot = true

# 自动射击配置
@export var auto_shoot_enabled := true

# 场景准备完成之后加载点位置，用于确定子弹生成位置
# 注意：Muzzle 现在是 Handle 的子节点，因此路径需要包含 Handle
@onready var muzzle := get_node_or_null("Handle/Muzzle") as Node2D
# 枪支的旋转中心（握把），用于先转向目标再发射
@onready var pivot := get_node_or_null("Handle") as Node2D

# 运行时持有的自动射击计时器引用（可能为 null）
var auto_shoot_timer: Timer = null

func _ready():
	# 确保子弹场景已设置
	if bullet_scene == null:
		print("错误：未设置子弹场景")
	# 如果启用自动射击，在运行时创建一个检测计时器
	if auto_shoot_enabled:
		auto_shoot_timer = Timer.new()
		auto_shoot_timer.one_shot = false
		auto_shoot_timer.wait_time = get_fire_interval()
		add_child(auto_shoot_timer)
		auto_shoot_timer.connect("timeout", Callable(self, "_on_auto_shoot_timeout"))
		# 立即启动
		auto_shoot_timer.start()


# ==================== 计算最终属性的方法 ====================
# 获取最终伤害（基础 + 加成）
func get_damage() -> int:
	return base_damage + damage_bonus

# 获取基础攻速（每秒攻击次数）
func get_base_fire_rate() -> float:
	return 1.0 / base_fire_interval

# 获取最终攻速（每秒攻击次数）
func get_fire_rate() -> float:
	var base_rate = get_base_fire_rate()
	var final_rate = base_rate + fire_rate_bonus
	if final_rate > max_fire_rate:
		final_rate = max_fire_rate
	if final_rate < 0.1:  # 最小攻速，防止除零
		final_rate = 0.1
	return final_rate

# 获取最终射击间隔（秒）
func get_fire_interval() -> float:
	return 1.0 / get_fire_rate()

# 获取最终射程（基础 + 加成）
func get_range() -> float:
	var final_range = base_range + range_bonus
	if final_range > max_range:
		final_range = max_range
	return final_range

# 射击：可选传入目标点（世界坐标）。如果未传入则从枪口朝当前朝向直线发射。
func shoot(target_pos: Variant = null) -> void:
	var player = get_parent()
	if player == null:
		return
	# respect cooldown
	if not can_shoot:
		return
	if bullet_scene == null:
		return

	# 如果传入了目标位置，并且存在旋转中心，则先转向目标
	if target_pos != null and target_pos is Vector2 and pivot != null:
		pivot.global_rotation = (target_pos - pivot.global_position).angle()

	# 位置与方向都由枪口决定，假设枪已对准目标
	var spawn_pos: Vector2
	if muzzle != null:
		spawn_pos = muzzle.global_position
	elif pivot != null:
		# 如果找不到枪口则退回到旋转中心
		spawn_pos = pivot.global_position
	else:
		spawn_pos = global_position
	var spawn_rot: float
	if muzzle != null:
		spawn_rot = muzzle.global_rotation
	elif pivot != null:
		spawn_rot = pivot.global_rotation
	else:
		spawn_rot = global_rotation

	# 散射发射多颗子弹
	var final_damage = get_damage()
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		
		# 计算散射角度
		var angle_offset = 0.0
		if bullet_count > 1:
			# 计算当前子弹的偏移角度（以中心为基准，左右对称分布）
			var half_count = (bullet_count - 1) / 2.0
			angle_offset = deg_to_rad((i - half_count) * spread_angle)
		
		var bullet_rot = spawn_rot + angle_offset
		var direction: Vector2 = Vector2(cos(bullet_rot), sin(bullet_rot)).normalized()
		
		bullet.global_position = spawn_pos
		bullet.direction = direction
		# 传递武器伤害给子弹
		bullet.damage = final_damage
		# 传递爆炸范围加成给子弹（如果子弹支持）
		if bullet.has_method("set_explosion_radius_bonus") or "explosion_radius_bonus" in bullet:
			bullet.explosion_radius_bonus = explosion_radius_bonus
		player.get_parent().add_child(bullet)

	# 启动冷却
	can_shoot = false
	if has_node("ShootTimer"):
		$ShootTimer.start()

# 射击冷却计时器超时处理
func _on_shoot_timer_timeout():
	can_shoot = true


# ==================== 升级方法（操作加成属性）====================
# 增加伤害加成，返回是否成功（true 表示实际增加）
func increase_damage(amount: int = 1) -> bool:
	var new_bonus = damage_bonus + amount
	if new_bonus > max_damage_bonus:
		new_bonus = max_damage_bonus
	# 若没有实际变化则返回 false
	if new_bonus == damage_bonus:
		return false
	damage_bonus = new_bonus
	return true

# 增加攻速（每秒攻击次数），返回是否成功
func increase_fire_rate(amount: float = 1.0) -> bool:
	var new_bonus = fire_rate_bonus + amount
	var final_rate = get_base_fire_rate() + new_bonus
	if final_rate > max_fire_rate:
		new_bonus = max_fire_rate - get_base_fire_rate()
	# 若没有实际变化则返回 false
	if is_equal_approx(new_bonus, fire_rate_bonus):
		return false
	fire_rate_bonus = new_bonus
	# 更新计时器（如果存在）
	if auto_shoot_timer != null:
		auto_shoot_timer.wait_time = get_fire_interval()
	return true

# 增加射程，返回是否成功（true 表示实际增加）
func increase_range(amount: float = 20.0) -> bool:
	var new_bonus = range_bonus + amount
	var final_range = base_range + new_bonus
	if final_range > max_range:
		new_bonus = max_range - base_range
	# 若没有实际变化则返回 false
	if is_equal_approx(new_bonus, range_bonus):
		return false
	range_bonus = new_bonus
	return true

# 增加爆炸范围，返回是否成功（true 表示实际增加）
func increase_explosion_radius(amount: float = 10.0) -> bool:
	var new_bonus = explosion_radius_bonus + amount
	if new_bonus > max_explosion_radius_bonus:
		new_bonus = max_explosion_radius_bonus
	# 若没有实际变化则返回 false
	if is_equal_approx(new_bonus, explosion_radius_bonus):
		return false
	explosion_radius_bonus = new_bonus
	return true

# 重置所有加成属性到初始值
func reset_bonuses() -> void:
	damage_bonus = 0
	fire_rate_bonus = 0.0
	range_bonus = 0.0
	explosion_radius_bonus = 0.0
	# 更新计时器
	if auto_shoot_timer != null:
		auto_shoot_timer.wait_time = get_fire_interval()


# ==================== 获取加成值的方法（用于UI显示）====================
# 获取伤害加成
func get_damage_bonus() -> int:
	return damage_bonus

# 获取攻速加成（每秒攻击次数的增加值）
func get_fire_rate_bonus() -> float:
	return fire_rate_bonus

# 获取射程加成
func get_range_bonus() -> float:
	return range_bonus

# 获取爆炸范围加成
func get_explosion_radius_bonus() -> float:
	return explosion_radius_bonus

# ==================== 兼容旧API的方法 ====================
# 返回当前自动射击射程（便于 UI 显示）
func get_auto_shoot_range() -> float:
	return get_range()

# 返回当前自动射击间隔（便于 UI 显示）
func get_auto_shoot_interval() -> float:
	return get_fire_interval()

# 兼容旧方法名 - 增加攻速（现在使用 fire_rate）
func decrease_auto_shoot_interval(amount: float = 0.01) -> bool:
	# 旧方法：减少间隔 -> 新方法：增加攻速
	# 0.01秒间隔减少 ≈ 增加攻速，需要转换
	# 简化处理：每次调用增加 0.5 攻速
	return increase_fire_rate(0.5)

func increase_auto_shoot_range(amount: float = 20.0) -> bool:
	return increase_range(amount)

# 重置武器伤害到初始值（兼容旧方法）
func reset_damage() -> void:
	reset_bonuses()


# ==================== 自动射击逻辑 ====================
# 面向目标的辅助功能
# 将武器的旋转中心朝向指定世界坐标点
func aim_at(target_pos: Vector2) -> void:
	if pivot != null:
		pivot.global_rotation = (target_pos - pivot.global_position).angle()

# 自动检测并对最近的敌人射击（如果在范围内），并在射击前转向
func auto_shoot() -> void:
	if not auto_shoot_enabled:
		return
	var player = get_parent()
	if player == null:
		return
	# 获取在组 "mobs" 中的所有敌人
	var mobs = get_tree().get_nodes_in_group("mobs")
	var nearest = null
	var nearest_dist = INF
	for m in mobs:
		# 只处理 Node2D（包括 RigidBody2D）节点，直接使用 global_position
		if not (m is Node2D):
			continue
		if not m.is_inside_tree():
			continue
		var mob_pos = m.global_position
		var d = player.global_position.distance_to(mob_pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest = mob_pos

	# 找到目标并且在射程内，则先转向再发射
	if nearest != null and nearest_dist <= get_range() and can_shoot and player.visible:
		# 调用shoot会自动处理转向
		shoot(nearest)

func _on_auto_shoot_timeout() -> void:
	auto_shoot()
