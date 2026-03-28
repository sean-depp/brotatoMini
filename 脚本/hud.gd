extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game
signal pause_toggle_requested

# 血条系统
var health_bar: Control
var health_bar_fill: ColorRect
var health_bar_bg: ColorRect
var health_label: Label

# 经验条系统
var exp_bar: Control
var exp_bar_fill: ColorRect
var exp_bar_bg: ColorRect
var exp_label: Label

func _ready() -> void:
	# 设置为始终处理，即使游戏暂停也能接收输入
	process_mode = PROCESS_MODE_ALWAYS
	
	# 将HUD添加到"hud"组，方便其他节点查找
	add_to_group("hud")
	
	# 初始化血条
	_setup_health_bar()

func _unhandled_input(event):
	if event.is_action_pressed("菜单"):
		# 只在游戏运行时响应ESC键
		var main = get_tree().get_current_scene()
		if main and main.has_method("is_running") and main.is_running():
			pause_toggle_requested.emit()

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func show_level(level):
	var level_str = "Level: %d" % level
	$Level.text = level_str
	$Level.show()

	show_message(level_str)
	
func hide_message():
	$Message.hide()
	
func show_game_over():
	$Message.text = "游戏结束"
	$Message.show()
	await get_tree().create_timer(2.0).timeout
	
	$Message.text = "躲避怪物！ESC进入商店！"
	$Message.show()
	$StartButton.show()
	
func update_score(score):
	$ScoreLabel.text = str(score)

# 初始化血条
func _setup_health_bar() -> void:
	# 创建血条容器（Control节点）
	health_bar = Control.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(20, 20)  # 血条位置（左上角）
	health_bar.custom_minimum_size = Vector2(200, 20)  # 血条容器大小
	
	# 创建血条背景（红色）
	health_bar_bg = ColorRect.new()
	health_bar_bg.name = "Background"
	health_bar_bg.color = Color(0.8, 0.2, 0.2, 0.8)
	health_bar_bg.size = Vector2(200, 20)  # 背景大小
	health_bar_bg.position = Vector2(0, 0)
	health_bar.add_child(health_bar_bg)
	
	# 创建血条前景（绿色）
	health_bar_fill = ColorRect.new()
	health_bar_fill.name = "Fill"
	health_bar_fill.color = Color(0.2, 0.8, 0.2, 0.8)
	health_bar_fill.size = Vector2(200, 20)  # 前景大小（初始为满血）
	health_bar_fill.position = Vector2(0, 0)
	health_bar.add_child(health_bar_fill)
	
	# 创建血量标签（显示当前/最大血量）
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "1/1"
	health_label.position = Vector2(210, 0)  # 在血条右侧
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_bar.add_child(health_label)
	
	# 将血条添加到HUD节点
	add_child(health_bar)
	
	# 初始化经验条
	_setup_exp_bar()

# 初始化经验条
func _setup_exp_bar() -> void:
	# 创建经验条容器（Control节点）
	exp_bar = Control.new()
	exp_bar.name = "ExpBar"
	exp_bar.position = Vector2(20, 45)  # 经验条位置（血条下方）
	exp_bar.custom_minimum_size = Vector2(200, 15)  # 经验条容器大小
	
	# 创建经验条背景（深灰色）
	exp_bar_bg = ColorRect.new()
	exp_bar_bg.name = "Background"
	exp_bar_bg.color = Color(0.3, 0.3, 0.3, 0.8)
	exp_bar_bg.size = Vector2(200, 15)  # 背景大小
	exp_bar_bg.position = Vector2(0, 0)
	exp_bar.add_child(exp_bar_bg)
	
	# 创建经验条前景（黄色）
	exp_bar_fill = ColorRect.new()
	exp_bar_fill.name = "Fill"
	exp_bar_fill.color = Color(1.0, 0.8, 0.0, 0.9)  # 金黄色
	exp_bar_fill.size = Vector2(0, 15)  # 前景大小（初始为0）
	exp_bar_fill.position = Vector2(0, 0)
	exp_bar.add_child(exp_bar_fill)
	
	# 创建经验标签（显示等级和经验）
	exp_label = Label.new()
	exp_label.name = "ExpLabel"
	exp_label.text = "Lv.1 0/5"
	exp_label.position = Vector2(210, 0)  # 在经验条右侧
	exp_label.add_theme_font_size_override("font_size", 14)
	exp_label.add_theme_color_override("font_color", Color.WHITE)
	exp_bar.add_child(exp_label)
	
	# 将经验条添加到HUD节点
	add_child(exp_bar)

# 更新经验条显示
func update_exp_bar(current_exp: int, exp_required: int, level: int) -> void:
	if exp_bar_fill != null and is_instance_valid(exp_bar_fill):
		# 计算经验条宽度比例
		var exp_ratio = float(current_exp) / float(exp_required) if exp_required > 0 else 0.0
		# 更新经验条前景宽度
		exp_bar_fill.size.x = 200.0 * exp_ratio
	
	# 更新经验标签
	if exp_label != null and is_instance_valid(exp_label):
		exp_label.text = "Lv.%d %d/%d" % [level, current_exp, exp_required]

# 更新血条显示（支持浮点类型）
func update_health_bar(current: float, max_val: float) -> void:
	if health_bar_fill != null and is_instance_valid(health_bar_fill):
		# 计算血条宽度比例
		var health_ratio = current / max_val
		# 更新血条前景宽度
		health_bar_fill.size.x = 200.0 * health_ratio
	
	# 更新血量标签（显示一位小数）
	if health_label != null and is_instance_valid(health_label):
		health_label.text = "%.1f/%.1f" % [current, max_val]

func set_full_health():
	if health_bar_fill != null and is_instance_valid(health_bar_fill):
		health_bar_fill.size.x = 200.0

# 获取玩家当前血量
func get_health() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_health"):
		return player.get_health()
	return 0.0

# 获取玩家最大血量
func get_max_health() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_max_health"):
		return player.get_max_health()
	return 0.0

# 增加最大血量
func add_max_health(amount: float) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_max_health"):
		var current_max = player.get_max_health()
		# 血量上限最大100
		if current_max < 100:
			player.set_max_health(current_max + amount)
			player.add_health(amount)
			# 更新HUD血条显示
			update_health_bar(player.get_health(), player.get_max_health())
			return true
	return false

# 恢复血量
func heal_health(amount: float) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_health") and player.has_method("get_max_health"):
		var current = player.get_health()
		var max_val = player.get_max_health()
		# 只有当前血量小于最大血量时才能恢复
		if current < max_val:
			player.add_health(amount)
			# 更新HUD血条显示
			update_health_bar(player.get_health(), player.get_max_health())
			return true
	return false

func _on_message_timer_timeout() -> void:
	$Message.hide()

func _on_start_button_pressed() -> void:
	$StartButton.hide()
	# 禁用开始按钮的快捷键，防止ESC键触发
	$StartButton.shortcut = null

	start_game.emit()

func show_pause_panel(isshow: bool) -> void:
	# 显示或隐藏暂停面板
	var pause_menu = get_node_or_null("PauseMenu")
	if pause_menu == null:
		return
	
	if isshow:
		# 在显示暂停面板前刷新其数值显示
		if pause_menu.has_method("update_value_labels"):
			pause_menu.update_value_labels()
		pause_menu.show()
	else:
		pause_menu.hide()
