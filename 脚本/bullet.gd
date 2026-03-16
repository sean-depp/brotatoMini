extends Area2D

# 子弹速度
@export var speed = 1000

# 子弹方向
var direction = Vector2.RIGHT

# 掉落物品场景
@export var drop_item_scene: PackedScene
# 新揭殖道具场景（吸磊所有金币）
@export var drop_magnet_scene: PackedScene

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
# todo 好像现在计数不太对
func _on_body_entered(body):
	# 如果碰到的是怪物，先掉落物品，再销毁怪物和子弹
	if body.is_in_group("mobs"):
		# 50% 概率掉落金币或吸磊道具
		var should_spawn_magnet = randf() < 0.1
		
		if should_spawn_magnet and drop_magnet_scene != null:
			# 50% 概率：掉落吸磊道具
			var magnet = drop_magnet_scene.instantiate()
			magnet.global_position = body.global_position
			# 不将吸磊道具加入 drops 组，仅追述需要被吸收的金币
			get_tree().get_root().add_child(magnet)
		elif drop_item_scene != null:
			# 50% 概率：掉落金币
			var drop_item = drop_item_scene.instantiate()
			drop_item.global_position = body.global_position
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
