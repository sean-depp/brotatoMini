extends Area2D
class_name DropBase

# 掉落物基类：所有掉落物都继承此类
# 子类需要实现 _on_pickup() 方法来定义拾取效果

# 掉落物类型枚举
enum DropType {
	COIN,       # 金币
	HEALTH,     # 回血道具
	MAGNET,     # 吸磁道具
	CHEST,      # 宝箱
}

# 掉落物配置：类型 -> {scene_path, group_name, probability}
const DROP_CONFIG := {
	DropType.COIN: {
		"scene_path": "res://子弹/drop_item.tscn",
		"group_name": "drops",
		"probability": 0.65,  # 65% 概率
	},
	DropType.HEALTH: {
		"scene_path": "res://子弹/drop_health.tscn",
		"group_name": "health_drops",
		"probability": 0.15,  # 15% 概率
	},
	DropType.MAGNET: {
		"scene_path": "res://子弹/drop_magnet.tscn",
		"group_name": "magnets",
		"probability": 0.05,  # 5% 概率
	},
	DropType.CHEST: {
		"scene_path": "res://子弹/drop_chest.tscn",
		"group_name": "chests",
		"probability": 0.05,  # 5% 概率
	},
}

# 缓存加载的场景
static var _loaded_scenes := {}

func _ready():
	# 连接与玩家的碰撞信号（Area2D 之间的碰撞使用 area_entered）
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area):
	# 检查碰撞对象是否为玩家
	if area.is_in_group("player"):
		# 调用子类实现的拾取逻辑
		_on_pickup(area)
		# 销毁掉落物
		queue_free()

# 子类实现此方法来定义拾取效果
func _on_pickup(_player: Node) -> void:
	push_warning("DropBase._on_pickup() 未在子类中实现")

# 获取玩家节点
func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

# 获取HUD节点
func _get_hud() -> Node:
	return get_tree().get_first_node_in_group("hud")

# 获取主场景
func _get_main() -> Node:
	return get_tree().get_current_scene()

# 添加到指定组
func add_to_drop_group(group_name: String) -> void:
	if not is_in_group(group_name):
		add_to_group(group_name)

# 静态方法：加载并缓存场景
static func load_drop_scene(drop_type: DropType) -> PackedScene:
	if _loaded_scenes.has(drop_type):
		return _loaded_scenes[drop_type]
	
	var config = DROP_CONFIG.get(drop_type)
	if config == null:
		push_error("未知的掉落物类型: %s" % drop_type)
		return null
	
	var scene = load(config.scene_path)
	if scene:
		_loaded_scenes[drop_type] = scene
	return scene

# 静态方法：获取掉落物配置
static func get_drop_config(drop_type: DropType) -> Dictionary:
	return DROP_CONFIG.get(drop_type, {})

# 静态方法：根据概率随机选择掉落物类型
# 返回选中的掉落物类型，如果无掉落则返回 -1
static func roll_drop_type() -> int:
	var roll = randf()
	var cumulative = 0.0
	
	for drop_type in DROP_CONFIG.keys():
		var config = DROP_CONFIG[drop_type]
		cumulative += config.probability
		if roll < cumulative:
			return drop_type
	
	# 无掉落
	return -1

# 静态方法：在指定位置生成掉落物
static func spawn_drop(drop_type: int, position: Vector2, parent: Node = null) -> Node:
	if drop_type == -1:
		return null
	
	var scene = load_drop_scene(drop_type)
	if scene == null:
		push_error("无法加载掉落物场景: %s" % drop_type)
		return null
	
	var drop = scene.instantiate()
	drop.global_position = position
	
	# 添加到对应的组
	var config = get_drop_config(drop_type)
	if config.has("group_name"):
		drop.add_to_group(config.group_name)
	
	# 添加到场景树
	if parent:
		parent.add_child(drop)
	else:
		# 如果没有指定父节点，添加到当前场景
		var main = Engine.get_main_loop().current_scene
		if main:
			main.add_child(drop)
	
	return drop