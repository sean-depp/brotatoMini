extends Node2D

# 子弹场景
@export var bullet_scene: PackedScene
@export var min_fire_rate := 3  # 最小冷却时间
@export var max_fire_rate := 5  # 最大冷却时间

# 射击冷却时间
var can_shoot = true

func _ready():
	# 确保子弹场景已设置
	if bullet_scene == null:
		print("错误：未设置子弹场景")

	# 启动随机射击计时器
	_start_random_timer()

# 随机设置射击间隔
func _start_random_timer():
	var random_cd = randf_range(min_fire_rate, max_fire_rate)
	$ShootTimer.wait_time = random_cd
	$ShootTimer.start()

# func _input(event):
# 	# 检测鼠标左键点击进行射击
# 	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
# 		if can_shoot:
# 			shoot()
# 			can_shoot = false
# 			# 启动射击冷却计时器
# 			$ShootTimer.start()

# 射击函数
func shoot():
	# 获取玩家节点（假设武器是玩家的子节点）
	# var player:Area2D = get_parent()
	# if player == null:
	# 	return

	var enemy = get_parent()
	if enemy == null:
		return

	# 实例化子弹
	var bullet = bullet_scene.instantiate()
	
	# 设置子弹位置为玩家位置
	# bullet.position = player.position
	# 将子弹加到怪物的父节点，这样坐标系正确

	# 获取鼠标位置
	# var mouse_pos = get_global_mouse_position()

	# 假设敌人面向方向或朝向玩家
	var player = get_tree().get_first_node_in_group("player") # 或自定义引用
	if player == null:
		return

	# 计算射击方向
	# var direction = (mouse_pos - player.position).normalized()
	# 2. 立即计算子弹应该在的世界位置（怪物中心）
	var bullet_spawn_pos = enemy.global_position
	bullet.global_position = bullet_spawn_pos

	# 3. 计算方向（指向玩家）
	bullet.direction = (player.global_position - bullet_spawn_pos).normalized()

	#bullet.direction = (player.global_position - bullet.global_position).normalized()
	
	# 将子弹添加到场景中
	# player.get_parent().add_child(bullet)
	get_tree().get_root().add_child(bullet)
	
	can_shoot = false
	_start_random_timer()
	
# 射击冷却计时器超时处理
func _on_shoot_timer_timeout():
	can_shoot = true       # 射击前允许
	shoot()
