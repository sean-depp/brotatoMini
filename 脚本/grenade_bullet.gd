extends Area2D
class_name GrenadeBullet

# 子弹速度
@export var speed: float = 400.0

# 子弹方向
var direction: Vector2 = Vector2.RIGHT

# 子弹伤害（由武器设置）
var damage: int = 1

# 爆炸半径
@export var explosion_radius: float = 80.0

# 爆炸伤害衰减（边缘伤害 = damage * damage_falloff）
@export var damage_falloff: float = 0.5

# 爆炸特效场景（可选）
@export var explosion_effect_scene: PackedScene

func _ready():
	# 连接body_entered信号，用于检测与怪物的碰撞
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# 根据给定方向设置朝向（贴图默认朝右）
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# 根据方向和速度移动子弹
	position += direction * speed * delta

# 当子弹离开屏幕时销毁
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

# 当子弹碰到物体时的处理
func _on_body_entered(body: Node2D) -> void:
	# 如果碰到的是怪物，触发爆炸
	if body.is_in_group("mobs"):
		explode()
	# 如果碰到其他物体（墙壁等），也触发爆炸
	else:
		explode()

# 爆炸函数：对范围内所有怪物造成伤害
func explode() -> void:
	# 获取爆炸范围内的所有节点
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# 创建圆形碰撞形状用于检测
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1  # 怪物在碰撞层1
	
	# 查询范围内的所有碰撞体
	var results = space_state.intersect_shape(query)
	
	# 收集所有被击中的怪物（去重）
	var hit_mobs: Array = []
	for result in results:
		var collider = result.get("collider")
		if collider != null and collider.is_in_group("mobs") and not hit_mobs.has(collider):
			hit_mobs.append(collider)
	
	# 对每个怪物造成伤害（根据距离计算伤害衰减）
	for mob in hit_mobs:
		if mob.has_method("take_damage") and is_instance_valid(mob):
			var distance = global_position.distance_to(mob.global_position)
			# 计算伤害：距离越远伤害越低
			var damage_multiplier = 1.0 - (distance / explosion_radius) * (1.0 - damage_falloff)
			var final_damage = max(1, int(damage * damage_multiplier))
			mob.take_damage(final_damage)
	
	# 生成爆炸特效（如果设置了）
	if explosion_effect_scene != null:
		var effect = explosion_effect_scene.instantiate()
		effect.global_position = global_position
		get_tree().get_root().add_child(effect)
	
	# 销毁子弹
	queue_free()