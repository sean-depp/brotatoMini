extends Node2D
class_name Weapon

# 武器基类：所有武器都继承此类
# 通过配置 weapon_type 可以快速创建不同类型的武器

# ==================== 武器类型枚举 ====================
enum WeaponType {
	SMG,            # 冲锋枪（默认）
	SHOTGUN,        # 霰弹枪（多发子弹，散射）
	GRENADE_LAUNCHER, # 榴弹枪（爆炸伤害）
	RIFLE,          # 步枪（高伤害，中等射速）
	SNIPER,         # 狙击枪（高伤害，慢射速，远射程）
	PISTOL,         # 手枪（低伤害，快射速）
}

# ==================== 武器类型配置 ====================
# 不同武器类型的默认属性配置
const WEAPON_CONFIGS := {
	WeaponType.SMG: {
		"base_damage": 1,
		"base_fire_interval": 0.5,
		"base_range": 200.0,
		"bullet_count": 1,
		"spread_angle": 0.0,
		"bullet_scene_path": "res://子弹/bullet.tscn",
	},
	WeaponType.SHOTGUN: {
		"base_damage": 2,
		"base_fire_interval": 1.0,
		"base_range": 150.0,
		"bullet_count": 5,
		"spread_angle": 15.0,
		"bullet_scene_path": "res://子弹/bullet.tscn",
	},
	WeaponType.GRENADE_LAUNCHER: {
		"base_damage": 1,
		"base_fire_interval": 1.5,
		"base_range": 300.0,
		"bullet_count": 1,
		"spread_angle": 0.0,
		"bullet_scene_path": "res://子弹/grenade_bullet.tscn",
	},
	WeaponType.RIFLE: {
		"base_damage": 2,
		"base_fire_interval": 0.3,
		"base_range": 300.0,
		"bullet_count": 1,
		"spread_angle": 0.0,
		"bullet_scene_path": "res://子弹/bullet.tscn",
	},
	WeaponType.SNIPER: {
		"base_damage": 5,
		"base_fire_interval": 2.0,
		"base_range": 500.0,
		"bullet_count": 1,
		"spread_angle": 0.0,
		"bullet_scene_path": "res://子弹/bullet.tscn",
	},
	WeaponType.PISTOL: {
		"base_damage": 1,
		"base_fire_interval": 0.25,
		"base_range": 180.0,
		"bullet_count": 1,
		"spread_angle": 0.0,
		"bullet_scene_path": "res://子弹/bullet.tscn",
	},
}

# ==================== 武器配置 ====================
# 武器类型（决定默认属性）
@export var weapon_type: WeaponType = WeaponType.SMG

# 子弹场景（可覆盖默认配置）
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
@onready var muzzle := get_node_or_null("Handle/Muzzle") as Node2D
# 枪支的旋转中心（握把），用于先转向目标再发射
@onready var pivot := get_node_or_null("Handle") as Node2D

# 运行时持有的自动射击计时器引用
var auto_shoot_timer: Timer = null

func _ready():
	# 根据武器类型加载默认配置
	_apply_weapon_config()
	
	# 确保子弹场景已设置
	if bullet_scene == null:
		print("错误：未设置子弹场景")
	
	# 如果启用自动射击，创建检测计时器
	if auto_shoot_enabled:
		auto_shoot_timer = Timer.new()
		auto_shoot_timer.one_shot = false
		auto_shoot_timer.wait_time = get_fire_interval()
		add_child(auto_shoot_timer)
		auto_shoot_timer.connect("timeout", Callable(self, "_on_auto_shoot_timeout"))
		auto_shoot_timer.start()

# 根据武器类型应用默认配置
func _apply_weapon_config() -> void:
	var config = WEAPON_CONFIGS.get(weapon_type)
	if config == null:
		return
	
	# 应用配置（如果未手动设置则使用默认值）
	if base_damage == 1:  # 默认值，说明未手动设置
		base_damage = config.get("base_damage", 1)
	if base_fire_interval == 0.5:  # 默认值
		base_fire_interval = config.get("base_fire_interval", 0.5)
	if base_range == 200.0:  # 默认值
		base_range = config.get("base_range", 200.0)
	if bullet_count == 1:  # 默认值
		bullet_count = config.get("bullet_count", 1)
	if spread_angle == 0.0:  # 默认值
		spread_angle = config.get("spread_angle", 0.0)
	
	# 加载子弹场景
	if bullet_scene == null:
		var bullet_path = config.get("bullet_scene_path", "")
		if bullet_path != "":
			bullet_scene = load(bullet_path)

# ==================== 计算最终属性的方法 ====================
# 获取最终伤害（基础 * 伤害倍率，每点伤害加成增加10%，再加上宝物百分比加成）
func get_damage() -> float:
	var damage_multiplier = 1.0 + (damage_bonus * 0.1)  # 每点伤害加成增加10%伤害
	
	# 获取玩家的宝物伤害百分比加成
	var player = get_parent()
	if player and player.has_method("get_treasure_damage_bonus_percent"):
		var treasure_bonus_percent = player.get_treasure_damage_bonus_percent()
		damage_multiplier += treasure_bonus_percent  # 宝物百分比加成
	
	var final_damage = base_damage * damage_multiplier
	return final_damage

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

# 射击：可选传入目标点（世界坐标）
func shoot(target_pos: Variant = null) -> void:
	var player = get_parent()
	if player == null:
		return
	if not can_shoot:
		return
	if bullet_scene == null:
		return

	# 如果传入了目标位置，并且存在旋转中心，则先转向目标
	if target_pos != null and target_pos is Vector2 and pivot != null:
		pivot.global_rotation = (target_pos - pivot.global_position).angle()

	# 确定生成位置和旋转
	var spawn_pos: Vector2
	var spawn_rot: float
	
	if muzzle != null:
		spawn_pos = muzzle.global_position
		spawn_rot = muzzle.global_rotation
	elif pivot != null:
		spawn_pos = pivot.global_position
		spawn_rot = pivot.global_rotation
	else:
		spawn_pos = global_position
		spawn_rot = global_rotation

	# 散射发射多颗子弹
	var final_damage = get_damage()
	for i in range(bullet_count):
		var bullet = bullet_scene.instantiate()
		
		# 计算散射角度
		var angle_offset = 0.0
		if bullet_count > 1:
			var half_count = (bullet_count - 1) / 2.0
			angle_offset = deg_to_rad((i - half_count) * spread_angle)
		
		var bullet_rot = spawn_rot + angle_offset
		var direction: Vector2 = Vector2(cos(bullet_rot), sin(bullet_rot)).normalized()
		
		bullet.global_position = spawn_pos
		bullet.direction = direction
		bullet.damage = final_damage
		
		# 传递爆炸范围加成给子弹（如果子弹支持）
		if "explosion_radius_bonus" in bullet:
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
# 增加伤害加成，返回是否成功
func increase_damage(amount: int = 1) -> bool:
	var new_bonus = damage_bonus + amount
	if new_bonus > max_damage_bonus:
		new_bonus = max_damage_bonus
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
	if is_equal_approx(new_bonus, fire_rate_bonus):
		return false
	fire_rate_bonus = new_bonus
	if auto_shoot_timer != null:
		auto_shoot_timer.wait_time = get_fire_interval()
	return true

# 增加射程，返回是否成功
func increase_range(amount: float = 20.0) -> bool:
	var new_bonus = range_bonus + amount
	var final_range = base_range + new_bonus
	if final_range > max_range:
		new_bonus = max_range - base_range
	if is_equal_approx(new_bonus, range_bonus):
		return false
	range_bonus = new_bonus
	return true

# 增加爆炸范围，返回是否成功
func increase_explosion_radius(amount: float = 10.0) -> bool:
	var new_bonus = explosion_radius_bonus + amount
	if new_bonus > max_explosion_radius_bonus:
		new_bonus = max_explosion_radius_bonus
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
	if auto_shoot_timer != null:
		auto_shoot_timer.wait_time = get_fire_interval()

# ==================== 获取加成值的方法（用于UI显示）====================
func get_damage_bonus() -> int:
	# 返回武器伤害加成 + 宝物伤害加成
	var total_bonus = damage_bonus
	var player = get_parent()
	if player and player.has_method("get_treasure_damage_bonus"):
		total_bonus += player.get_treasure_damage_bonus()
	return total_bonus

func get_fire_rate_bonus() -> float:
	return fire_rate_bonus

func get_range_bonus() -> float:
	return range_bonus

func get_explosion_radius_bonus() -> float:
	return explosion_radius_bonus

# ==================== 兼容旧API的方法 ====================
func get_auto_shoot_range() -> float:
	return get_range()

func get_auto_shoot_interval() -> float:
	return get_fire_interval()

func decrease_auto_shoot_interval(amount: float = 0.01) -> bool:
	return increase_fire_rate(0.5)

func increase_auto_shoot_range(amount: float = 20.0) -> bool:
	return increase_range(amount)

func reset_damage() -> void:
	reset_bonuses()

# ==================== 自动射击逻辑 ====================
func aim_at(target_pos: Vector2) -> void:
	if pivot != null:
		pivot.global_rotation = (target_pos - pivot.global_position).angle()

func auto_shoot() -> void:
	if not auto_shoot_enabled:
		return
	var player = get_parent()
	if player == null:
		return
	
	var mobs = get_tree().get_nodes_in_group("mobs")
	var nearest = null
	var nearest_dist = INF
	
	for m in mobs:
		if not (m is Node2D):
			continue
		if not m.is_inside_tree():
			continue
		var mob_pos = m.global_position
		var d = player.global_position.distance_to(mob_pos)
		if d < nearest_dist:
			nearest_dist = d
			nearest = mob_pos

	if nearest != null and nearest_dist <= get_range() and can_shoot and player.visible:
		shoot(nearest)

func _on_auto_shoot_timeout() -> void:
	auto_shoot()