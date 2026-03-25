extends Area2D

# 子弹速度
@export var speed = 1000

# 子弹方向
var direction = Vector2.RIGHT

# 子弹伤害（由武器设置）
var damage = 1

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
func _on_body_entered(body):
	# 如果碰到的是怪物，造成伤害
	if body.is_in_group("mobs"):
		# 调用怪物的受伤函数（使用子弹的伤害值）
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# 销毁子弹
		queue_free()
	# 如果碰到其他物体，只销毁子弹
	else:
		queue_free()

func _spawn_drop_item(drop_item):
	# 把掉落物加入一个组，便于统一清理
	if not drop_item.is_in_group("drops"):
		drop_item.add_to_group("drops")
	get_tree().get_root().add_child(drop_item)
