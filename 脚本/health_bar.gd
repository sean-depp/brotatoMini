extends HBoxContainer

@export var heart_scene: PackedScene  # 引用爱心场景
@export var max_health: int = 1  # 最大生命值

var current_health: int = max_health
var hearts: Array[TextureRect] = []

func _ready() -> void:
	# 初始化血槽
	initialize_health_bar()

# 初始化血槽，创建所有爱心
func initialize_health_bar() -> void:
	# 清空现有爱心
	for child in get_children():
		child.queue_free()
	
	hearts.clear()
	
	# 创建新的爱心
	for i in range(max_health):
		var heart = heart_scene.instantiate()
		
		var full = heart.get_node("Full") as TextureRect
		var scaled_size = full.texture.get_size() * full.scale
		heart.custom_minimum_size = scaled_size

		add_child(heart)
		heart.set_heart_state(i < current_health)
		
		hearts.append(heart)

# 设置当前生命值
func set_health(health: int) -> void:
	if health < 0:
		health = 0
	if health > max_health:
		health = max_health
	
	current_health = health
	update_hearts_visual()

# 更新爱心显示状态
func update_hearts_visual() -> void:
	for i in range(hearts.size()):
		hearts[i].set_heart_state(i < current_health)

# 增加生命值
func add_health(amount: int) -> void:
	set_health(current_health + amount)

# 减少生命值
func subtract_health(amount: int) -> void:
	set_health(current_health - amount)

# 设置最大生命值，会自动调整爱心数量
func set_max_health(new_max: int) -> void:
	max_health = new_max
	# 确保当前生命值不超过新的最大值
	if current_health > max_health:
		current_health = max_health
	initialize_health_bar()

func add_max_health(add_value: int) -> bool:
	# 血量上限最大10
	if max_health < 10:
		max_health += add_value
		current_health += add_value
		# 确保当前生命值不超过新的最大值
		if current_health > max_health:
			current_health = max_health
		initialize_health_bar()
		return true
	return false

func set_full_health():
	current_health = max_health
	initialize_health_bar()
	
func get_health() -> int:
	return current_health
