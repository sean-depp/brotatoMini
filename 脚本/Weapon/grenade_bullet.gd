extends "res://脚本/Weapon/bullet_base.gd"

# 榴弹子弹：击中后爆炸，造成范围伤害

# ==================== 榴弹特有属性 ====================
# 爆炸半径（基础值）
@export var base_explosion_radius: float = 80.0

# 爆炸范围加成（由武器传递）
var explosion_radius_bonus: float = 0.0

# 爆炸伤害衰减（边缘伤害 = damage * damage_falloff）
@export var damage_falloff: float = 0.5

# 爆炸特效场景
var explosion_effect_scene = preload("res://子弹/explosion_effect.tscn")

func _ready():
	super._ready()
	# 榴弹类型
	bullet_type = BulletType.GRENADE
	# 榴弹速度较慢
	speed = 400.0

# 击中目标时的处理（重写父类方法）
func _on_hit_target(_target: Node2D) -> void:
	explode()

# 击中其他物体时的处理（重写父类方法）
func _on_hit_other(_body: Node2D) -> void:
	explode()

# 获取最终爆炸半径（基础 + 加成）
func get_explosion_radius() -> float:
	return base_explosion_radius + explosion_radius_bonus

# 爆炸函数：对范围内所有怪物造成伤害
func explode() -> void:
	# 获取最终爆炸半径
	var final_explosion_radius = get_explosion_radius()
	
	# 获取爆炸范围内的所有节点
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# 创建圆形碰撞形状用于检测
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = final_explosion_radius
	
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1  # 怪物在碰撞层1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# 查询范围内的所有碰撞体
	var results = space_state.intersect_shape(query, 32)  # 限制最大结果数
	
	# 收集所有被击中的怪物（使用字典去重，key为怪物实例ID）
	var hit_mobs: Dictionary = {}
	for result in results:
		var collider = result.get("collider")
		if collider != null and collider.is_in_group("mobs"):
			var collider_id = collider.get_instance_id()
			if not hit_mobs.has(collider_id):
				hit_mobs[collider_id] = collider
	
	# 对每个怪物造成伤害（根据距离计算伤害衰减）
	for mob_id in hit_mobs:
		var mob = hit_mobs[mob_id]
		if mob.has_method("take_damage") and is_instance_valid(mob):
			var distance = global_position.distance_to(mob.global_position)
			# 计算伤害：距离越远伤害越低
			var damage_multiplier = 1.0 - (distance / final_explosion_radius) * (1.0 - damage_falloff)
			var final_damage = max(1.0, damage * damage_multiplier)  # 保持浮点数
			mob.take_damage(final_damage)
	
	# 生成爆炸特效
	if explosion_effect_scene != null:
		var effect = explosion_effect_scene.instantiate()
		effect.global_position = global_position
		effect.radius = final_explosion_radius  # 传递爆炸半径
		get_tree().get_root().add_child(effect)
	
	# 销毁子弹
	queue_free()