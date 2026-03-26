extends Area2D
class_name BulletBase

# 子弹基类：所有子弹都继承此类
# 子类可以重写 _on_hit_target() 和 _on_hit_other() 方法来自定义行为

# ==================== 子弹基础属性 ====================
# 子弹速度
@export var speed: float = 1000.0

# 子弹方向
var direction: Vector2 = Vector2.RIGHT

# 子弹伤害（由武器设置，支持浮点型）
var damage: float = 1.0

# 子弹类型枚举
enum BulletType {
	NORMAL,     # 普通子弹（直线飞行，击中敌人造成伤害）
	PIERCING,   # 穿透子弹（可以穿透多个敌人）
	GRENADE,    # 榴弹（击中后爆炸，范围伤害）
	HOMING,     # 追踪子弹（自动追踪最近的敌人）
}

# 子弹类型（子类可以覆盖）
var bullet_type: BulletType = BulletType.NORMAL

# 穿透次数（仅对 PIERCING 类型有效）
@export var pierce_count: int = 1

# 当前已穿透次数
var _current_pierce: int = 0

func _ready():
	# 连接body_entered信号，用于检测碰撞
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# 根据给定方向设置朝向（贴图默认朝右）
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# 子类可以重写此方法实现特殊移动逻辑（如追踪）
	_move_bullet(delta)

# 子弹移动逻辑（子类可重写）
func _move_bullet(delta: float) -> void:
	position += direction * speed * delta

# 当子弹离开屏幕时销毁
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

# 当子弹碰到物体时的处理
func _on_body_entered(body: Node2D) -> void:
	# 如果碰到的是怪物
	if body.is_in_group("mobs"):
		_on_hit_target(body)
	else:
		_on_hit_other(body)

# 击中目标（怪物）时的处理（子类可重写）
func _on_hit_target(target: Node2D) -> void:
	# 调用目标的受伤函数
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# 检查是否可以穿透
	if bullet_type == BulletType.PIERCING and _current_pierce < pierce_count:
		_current_pierce += 1
		return  # 不销毁，继续飞行
	
	# 销毁子弹
	queue_free()

# 击中其他物体时的处理（子类可重写）
func _on_hit_other(_body: Node2D) -> void:
	# 默认行为：直接销毁
	queue_free()

# 设置子弹方向
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

# 设置子弹伤害（支持浮点型）
func set_damage(dmg: float) -> void:
	damage = dmg
