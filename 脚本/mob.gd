extends RigidBody2D

# 武器场景引用
@export var weapon_scene: PackedScene

# 掉落物品场景引用
@export var drop_item_scene: PackedScene
@export var drop_magnet_scene: PackedScene

# 怪物视觉节点组（仅动画）
var mob_visuals: Array[AnimatedSprite2D] = []

# 对应的碰撞形状（顺序需与mob_visuals一一对应）
var mob_collisions: Array[CollisionShape2D] = []

# 怪物类型对应的武器配置（类型索引 -> 武器参数字典）
var mob_weapon_configs := {
	2: {"min_fire_rate": 4.0, "max_fire_rate": 8.0},  # 只有 mob3 Spookmoth 可以射击
}

# 玩家引用
var player: Node2D
# 当前怪物类型索引
var mob_type_index: int = 0

# 血量系统
var max_health: int = 1
var current_health: int = 1
var health_bar: Control
var health_bar_fill: ColorRect
var health_bar_bg: ColorRect

var is_dead: bool = false

func _ready():
	mob_visuals = [
		get_node("mob1/AnimatedSprite2D_1"),
		get_node("mob2/AnimatedSprite2D_2"),
		get_node("mob3/AnimatedSprite2D_3"),
		get_node("mob4/AnimatedSprite2D_4"),
		get_node("mob5/AnimatedSprite2D_5"),
	]
	mob_collisions = [
		get_node("CollisionShape2D_1"),
		get_node("CollisionShape2D_2"),
		get_node("CollisionShape2D_3"),
		get_node("CollisionShape2D_4"),
		get_node("CollisionShape2D_5"),
	]
	
	# 获取玩家引用
	player = get_tree().get_first_node_in_group("player")
	
	# 如果场景中没有设置掉落物品场景，直接加载
	if drop_item_scene == null:
		drop_item_scene = load("res://子弹/drop_item.tscn")
	if drop_magnet_scene == null:
		drop_magnet_scene = load("res://子弹/drop_magnet.tscn")
	
	# 从 main.gd 传递的 mob_type 参数中获取怪物类型索引
	# 如果没有传递，则随机选择（向后兼容）
	if has_meta("mob_type"):
		mob_type_index = get_meta("mob_type")
	else:
		var random_index = randi() % mob_visuals.size()
		mob_type_index = random_index
	
	# 隐藏所有视觉节点和碰撞形状
	for visual in mob_visuals:
		visual.visible = false
	for collision in mob_collisions:
		collision.disabled = true  # 禁用碰撞（而非隐藏）
	
	# 激活选中的怪物视觉和碰撞
	mob_visuals[mob_type_index].visible = true
	mob_collisions[mob_type_index].disabled = false
	
	var mob_types = Array(mob_visuals[mob_type_index].sprite_frames.get_animation_names())
	mob_visuals[mob_type_index].animation = mob_types.pick_random()
	mob_visuals[mob_type_index].play()

	# 为当前怪物类型实例化并配置武器
	_setup_weapon(mob_type_index)

	# 根据怪物类型设置血量
	_setup_health(mob_type_index)

	# 设置初始速度
	var initial_speed = 100.0
	var initial_direction = randf_range(0, TAU)
	linear_velocity = Vector2(initial_speed, 0).rotated(initial_direction)
	rotation = initial_direction

	$ChangeTimer.start()

# 为指定的怪物类型设置武器
func _setup_weapon(mob_type_index: int) -> void:
	# 只有 mob3（索引 2）可以射击，其他怪物跳过武器实例化
	if mob_type_index != 2:
		# print("mob%d 无法射击" % (mob_type_index + 1))
		return
	
	if weapon_scene == null:
		print("错误：未设置武器场景")
		return
	
	# 实例化武器
	var weapon = weapon_scene.instantiate()
	
	# 将武器添加到对应的怪物节点下（例如 mob1、mob2 等）
	var mob_parent_node = get_node("mob%d" % (mob_type_index + 1))
	mob_parent_node.add_child(weapon)
	
	# 从配置中获取该怪物类型的攻击参数
	if mob_weapon_configs.has(mob_type_index):
		var config = mob_weapon_configs[mob_type_index]
		weapon.min_fire_rate = config["min_fire_rate"]
		weapon.max_fire_rate = config["max_fire_rate"]

# 为指定的怪物类型设置血量
func _setup_health(mob_type_index: int) -> void:
	# 根据怪物类型设置血量
	# mob1（索引0）和 mob2（索引1）：3血
	# mob3（索引2）：1血
	if mob_type_index == 0 or mob_type_index == 1:
		max_health = 3
	elif mob_type_index == 2:
		max_health = 1
	else:
		max_health = 1  # 其他怪物默认1血
	
	current_health = max_health
	
	# 创建血条容器（Control节点）
	health_bar = Control.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(-20, -30)  # 血条位置（怪物上方）
	health_bar.custom_minimum_size = Vector2(40, 3)  # 血条容器大小
	
	# 创建血条背景（红色）
	health_bar_bg = ColorRect.new()
	health_bar_bg.name = "Background"
	health_bar_bg.color = Color(0.8, 0.2, 0.2, 0.8)
	health_bar_bg.size = Vector2(40, 3)  # 背景大小
	health_bar_bg.position = Vector2(0, 0)
	health_bar.add_child(health_bar_bg)
	
	# 创建血条前景（绿色）
	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "Fill"
	health_bar_fill.color = Color(0.2, 0.8, 0.2, 0.8)
	health_bar_fill.size = Vector2(40, 4)  # 前景大小（初始为满血）
	health_bar_fill.position = Vector2(0, 0)
	health_bar.add_child(health_bar_fill)
	
	# 将血条添加到怪物节点
	add_child(health_bar)

func change_direction():
	# 计算随机的方向变化增量（-90° 到 90° 之间）
	var direction_delta = randf_range(-PI/2, PI/2)
	
	# 1. 更新旋转角度（累加增量）
	rotation += direction_delta
	
	# 2. 用相同的增量旋转速度向量（关键：使用增量而非绝对角度）
	linear_velocity = linear_velocity.rotated(direction_delta)

# 怪物受伤函数
func take_damage(amount: int) -> void:
	current_health -= amount
	
	# 更新血条显示
	if health_bar_fill != null and is_instance_valid(health_bar_fill):
		# 计算血条宽度比例
		var health_ratio = float(current_health) / float(max_health)
		# 更新血条前景宽度
		health_bar_fill.size.x = 40.0 * health_ratio
	
	# 检查是否死亡
	if current_health <= 0:
		die()

# 怪物死亡函数
func die() -> void:
	if is_dead:
		return  # 防止重复调用
	is_dead = true
	
	# 使用 call_deferred 禁用碰撞，防止在物理查询刷新期间修改状态
	for collision in mob_collisions:
		collision.call_deferred("set_disabled", true)
	
	# 停止移动
	linear_velocity = Vector2.ZERO
	
	# 掉落物品
	_spawn_drop_item()

	var sprite_anim = mob_visuals[mob_type_index]
	if sprite_anim.sprite_frames.has_animation("death"):
		sprite_anim.animation = "death"
		sprite_anim.play()
		# 等待动画完成再删除怪物
		await sprite_anim.animation_finished
		queue_free()
	else:
		# 没有动画直接删除
		queue_free()
		
# 掉落物品函数
func _spawn_drop_item() -> void:
	# 10% 概率掉落吸磁道具
	var should_spawn_magnet = randf() < 0.1
	
	if should_spawn_magnet and drop_magnet_scene != null:
		# 掉落吸磁道具
		var magnet = drop_magnet_scene.instantiate()
		magnet.global_position = global_position
		magnet.add_to_group("magnets")
		get_tree().get_root().call_deferred("add_child", magnet)
	elif drop_item_scene != null:
		# 掉落金币
		var drop_item = drop_item_scene.instantiate()
		drop_item.global_position = global_position
		if not drop_item.is_in_group("drops"):
			drop_item.add_to_group("drops")
		get_tree().get_root().call_deferred("add_child", drop_item)
	
func _physics_process(_delta: float) -> void:
	# 持续检查地图边界（2560x1440）
	const MAP_WIDTH = 2560.0
	const MAP_HEIGHT = 1440.0
	const MARGIN = 50.0  # 边界边距，避免怪物完全贴边
	
	# 如果怪物超出地图边界，强制改变方向并夹回范围内
	if global_position.x < MARGIN:
		linear_velocity.x = abs(linear_velocity.x)  # 向右移动
		global_position.x = MARGIN
	elif global_position.x > MAP_WIDTH - MARGIN:
		linear_velocity.x = -abs(linear_velocity.x)  # 向左移动
		global_position.x = MAP_WIDTH - MARGIN
	
	if global_position.y < MARGIN:
		linear_velocity.y = abs(linear_velocity.y)  # 向下移动
		global_position.y = MARGIN
	elif global_position.y > MAP_HEIGHT - MARGIN:
		linear_velocity.y = -abs(linear_velocity.y)  # 向上移动
		global_position.y = MAP_HEIGHT - MARGIN
	
	# 如果不是 mob3（索引2），则朝向玩家移动
	if mob_type_index != 2 and player != null and is_instance_valid(player):
		# 计算朝向玩家的方向
		var direction_to_player = (player.global_position - global_position).normalized()
		
		# 获取当前速度大小
		var current_speed = linear_velocity.length()
		
		# 如果速度为0，设置一个初始速度
		if current_speed == 0:
			current_speed = 100.0
		
		# 直接设置速度方向朝向玩家（不使用插值，避免原地旋转）
		linear_velocity = direction_to_player * current_speed
		
		# 更新旋转角度以匹配移动方向
		rotation = linear_velocity.angle()


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	# 此函数已由 _physics_process() 中的边界检查代替，但保留以防向后兼容
	pass


func _on_change_timer_timeout() -> void:
	change_direction()
