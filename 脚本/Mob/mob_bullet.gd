extends Area2D

# 子弹速度
@export var speed = 500

# 子弹方向
var direction = Vector2.RIGHT

func _ready():
	# 连接body_entered信号，用于检测与怪物的碰撞
	connect("body_entered", Callable(self, "_on_body_entered"))
	# 连接area_entered信号，用于检测与玩家(Area2D)的碰撞
	connect("area_entered", Callable(self, "_on_area_entered"))
	add_to_group("mob_bullets")

func _physics_process(delta):
	# 根据方向和速度移动子弹
	position += direction * speed * delta

# 当子弹离开屏幕时销毁
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# 当子弹碰到物体时的处理
func _on_body_entered(body):
	if body.is_in_group("mobs"):
		return
		
	queue_free()
	# 如果碰到的是玩家，扣除血量
	#if body.is_in_group("player"):
		#print ("打中了")
		## 从HUD的HealthBar执行扣血函数
		#var hud = get_tree().root.get_child(0).get_node("HUD")
		#if hud:
			#hud.update_health_bar(-1)
		#else:
			#print ("没找到 hub")
			#
		#queue_free()
	## 如果碰到其他物体，只销毁子弹
	#else:
		#queue_free()

# 当子弹与Area2D碰撞时的处理(用于与Player碰撞)
func _on_area_entered(area):
	# 检查碰撞对象是否为玩家
	if area.is_in_group("player"):
		# 先尝试让 player 发出 hit 信号（如果定义了该信号）
		if area.has_signal("hit"):
			area.under_hurt()
		#else:
			#print("player 未定义 hit 信号，跳过发信")
		## 从 HUD 的 HealthBar 扣血（保持现有 UI 同步行为）
		#var hud = get_tree().root.get_child(0).get_node("HUD")
		#if hud:
			#hud.update_health_bar(-1)
		#else:
			#print("没找到 HUD")
		queue_free()