extends Node2D
class_name Weapon

# 子弹场景
@export var bullet_scene: PackedScene

# 射击冷却时间
@export var fire_rate = 0.1
var can_shoot = true

# 自动射击配置
@export var auto_shoot_enabled := true
@export var auto_shoot_range := 200.0
@export var auto_shoot_interval := 0.5

# 场景准备完成之后加载点位置，用于确定子弹生成位置
# 注意：Muzzle 现在是 Handle 的子节点，因此路径需要包含 Handle
@onready var muzzle := get_node_or_null("Handle/Muzzle") as Node2D
# 枪支的旋转中心（握把），用于先转向目标再发射
@onready var pivot := get_node_or_null("Handle") as Node2D

func _ready():
	# 确保子弹场景已设置
	if bullet_scene == null:
		print("错误：未设置子弹场景")
	# 如果启用自动射击，在运行时创建一个检测计时器
	if auto_shoot_enabled:
		auto_shoot_timer = Timer.new()
		auto_shoot_timer.one_shot = false
		auto_shoot_timer.wait_time = auto_shoot_interval
		add_child(auto_shoot_timer)
		auto_shoot_timer.connect("timeout", Callable(self, "_on_auto_shoot_timeout"))
		# 立即启动
		auto_shoot_timer.start()
	

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

	var bullet = bullet_scene.instantiate()

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

	bullet.global_position = spawn_pos
	var direction: Vector2 = Vector2(cos(spawn_rot), sin(spawn_rot)).normalized()
	bullet.direction = direction
	player.get_parent().add_child(bullet)

	# 启动冷却
	can_shoot = false
	if has_node("ShootTimer"):
		$ShootTimer.start()

	# 射击完成后将握把恢复到初始方向（只在有目标的情况下旋转过）
	# （已移除，避免立即重设覆盖旋转）

# 射击冷却计时器超时处理
func _on_shoot_timer_timeout():
	can_shoot = true


# 最小自动射击间隔，防止变为 0
@export var min_auto_shoot_interval := 0.01

# 运行时持有的自动射击计时器引用（可能为 null）
var auto_shoot_timer: Timer = null

# 将自动射击间隔减少 amount（正数），返回是否成功
func decrease_auto_shoot_interval(amount: float = 0.01) -> bool:
	if not auto_shoot_enabled:
		return false
	var new_interval = auto_shoot_interval - amount
	if new_interval < min_auto_shoot_interval:
		new_interval = min_auto_shoot_interval
	# 如果没有变化则返回 false
	if is_equal_approx(new_interval, auto_shoot_interval):
		return false
	auto_shoot_interval = new_interval
	# 更新计时器（如果存在）
	if auto_shoot_timer != null:
		auto_shoot_timer.wait_time = auto_shoot_interval
	return true


# 自动射击最大射程（上限），避免无限增长
@export var max_auto_shoot_range := 1000.0

# 增加自动射击范围，返回是否成功（true 表示实际增加）
func increase_auto_shoot_range(amount: float = 20.0) -> bool:
	if not auto_shoot_enabled:
		return false
	var new_range = auto_shoot_range + amount
	if new_range > max_auto_shoot_range:
		new_range = max_auto_shoot_range
	# 若没有实际变化则返回 false
	if is_equal_approx(new_range, auto_shoot_range):
		return false
	auto_shoot_range = new_range
	return true


# 返回当前自动射击射程（便于 UI 显示）
func get_auto_shoot_range() -> float:
	return auto_shoot_range


# 返回当前自动射击间隔（便于 UI 显示）
func get_auto_shoot_interval() -> float:
	return auto_shoot_interval

# ---------------------------------------------------------------------------
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
	if nearest != null and nearest_dist <= auto_shoot_range and can_shoot and player.visible:
		# 调用shoot会自动处理转向
		shoot(nearest)

func _on_auto_shoot_timeout() -> void:
	auto_shoot()
