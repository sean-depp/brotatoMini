extends RigidBody2D

# 武器场景引用
@export var weapon_scene: PackedScene

# 怪物视觉节点组（仅动画）
var mob_visuals: Array[AnimatedSprite2D] = []

# 对应的碰撞形状（顺序需与mob_visuals一一对应）
var mob_collisions: Array[CollisionShape2D] = []

# 怪物类型对应的武器配置（类型索引 -> 武器参数字典）
var mob_weapon_configs := {
	2: {"min_fire_rate": 4.0, "max_fire_rate": 8.0},  # 只有 mob3 Spookmoth 可以射击
}

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
	
	# 随机选择一个怪物类型索引
	var random_index = randi() % mob_visuals.size()
	
	# 隐藏所有视觉节点和碰撞形状
	for visual in mob_visuals:
		visual.visible = false
	for collision in mob_collisions:
		collision.disabled = true  # 禁用碰撞（而非隐藏）
	
	# 激活选中的怪物视觉和碰撞
	mob_visuals[random_index].visible = true
	mob_collisions[random_index].disabled = false
	
	var mob_types = Array(mob_visuals[random_index].sprite_frames.get_animation_names())
	mob_visuals[random_index].animation = mob_types.pick_random()
	mob_visuals[random_index].play()

	# 为当前怪物类型实例化并配置武器
	_setup_weapon(random_index)

	# 非远程怪物（不是索引2）移动速度x3；索引2为带武器的远程怪物，保持原速
	if random_index != 2:
		linear_velocity *= 2

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

func change_direction():
	# 计算随机的方向变化增量（-90° 到 90° 之间）
	var direction_delta = randf_range(-PI/2, PI/2)
	
	# 1. 更新旋转角度（累加增量）
	rotation += direction_delta
	
	# 2. 用相同的增量旋转速度向量（关键：使用增量而非绝对角度）
	linear_velocity = linear_velocity.rotated(direction_delta)
	
func _physics_process(_delta: float) -> void:
	# 持续检查地图边界（2560x1440）
	const MAP_WIDTH = 2560.0
	const MAP_HEIGHT = 1440.0
	const MARGIN = 50.0  # 边界边距，避免怪物完全贴边
	
	# 如果怪物超出地图边界，强制改变方向并夹回范围内
	var needs_correction = false
	
	if global_position.x < MARGIN:
		linear_velocity.x = abs(linear_velocity.x)  # 向右移动
		global_position.x = MARGIN
		needs_correction = true
	elif global_position.x > MAP_WIDTH - MARGIN:
		linear_velocity.x = -abs(linear_velocity.x)  # 向左移动
		global_position.x = MAP_WIDTH - MARGIN
		needs_correction = true
	
	if global_position.y < MARGIN:
		linear_velocity.y = abs(linear_velocity.y)  # 向下移动
		global_position.y = MARGIN
		needs_correction = true
	elif global_position.y > MAP_HEIGHT - MARGIN:
		linear_velocity.y = -abs(linear_velocity.y)  # 向上移动
		global_position.y = MAP_HEIGHT - MARGIN
		needs_correction = true


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	# 此函数已由 _physics_process() 中的边界检查代替，但保留以防向后兼容
	pass


func _on_change_timer_timeout() -> void:
	change_direction()
