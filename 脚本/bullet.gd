extends Area2D

# 子弹速度
@export var speed = 1000

# 子弹方向
var direction = Vector2.RIGHT

# 掉落物品场景
@export var drop_item_scene: PackedScene

func _ready():
	# 连接body_entered信号，用于检测与怪物的碰撞
	connect("body_entered", Callable(self, "_on_body_entered"))

	# 根据给定方向设置朝向（贴图默认朝右）
	rotation = direction.angle()

func _physics_process(delta):
	# 根据方向和速度移动子弹
	position += direction * speed * delta

# 当子弹离开屏幕时销毁
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# 当子弹碰到物体时的处理
func _on_body_entered(body):
	# 如果碰到的是怪物，先掉落物品，再销毁怪物和子弹
	if body.is_in_group("mobs"):
		# 【关键】先在怪物位置生成金币（在销毁前）
		if drop_item_scene:
			var drop_item = drop_item_scene.instantiate()
			# 使用怪物的全局位置作为金币的生成位置
			drop_item.global_position = body.global_position
			# 添加到场景根节点，确保金币独立存在
			# get_tree().get_root().add_child(drop_item)
			call_deferred("_spawn_drop_item", drop_item)

		# 然后销毁怪物和子弹
		body.queue_free()
		queue_free()
	# 如果碰到其他物体，只销毁子弹
	else:
		queue_free()

func _spawn_drop_item(drop_item):
	# 把掉落物加入一个组，便于统一清理
	if not drop_item.is_in_group("drops"):
		drop_item.add_to_group("drops")
	get_tree().get_root().add_child(drop_item)
