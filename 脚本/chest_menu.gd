extends CanvasLayer

# 宝箱选择界面
# 玩家拾取宝箱后弹出，选择一个奖励

signal reward_selected()

# 四个奖励按钮
@onready var button1: Button = $PanelContainer/VBoxContainer/Button1
@onready var button2: Button = $PanelContainer/VBoxContainer/Button2
@onready var button3: Button = $PanelContainer/VBoxContainer/Button3
@onready var button4: Button = $PanelContainer/VBoxContainer/Button4

func _ready():
	# 设置为始终处理，即使游戏暂停也能接收输入
	process_mode = PROCESS_MODE_ALWAYS
	
	# 连接按钮信号
	if button1:
		button1.pressed.connect(_on_button1_pressed)
	if button2:
		button2.pressed.connect(_on_button2_pressed)
	if button3:
		button3.pressed.connect(_on_button3_pressed)
	if button4:
		button4.pressed.connect(_on_button4_pressed)

# 显示宝箱选择界面
func show_chest_menu():
	# 暂停游戏（使用独立的暂停标志）
	get_tree().paused = true
	show()
	# 更新显示
	update_display()

# 隐藏宝箱选择界面并恢复游戏
func hide_chest_menu():
	hide()
	get_tree().paused = false
	emit_signal("reward_selected")

# 更新显示内容
func update_display():
	var cur_scene = get_tree().get_current_scene()
	if not cur_scene:
		return
	
	# 更新按钮文本（显示当前状态）
	if cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		if hud:
			# 按钮1：+1血量上限
			if button1:
				var max_hp = hud.get_max_health()
				button1.text = "+1 血量上限 (当前: %d)" % int(max_hp)
			
			# 按钮2：+3血量
			if button2:
				var current_hp = hud.get_health()
				var max_hp = hud.get_max_health()
				button2.text = "+3 血量 (当前: %d/%d)" % [int(current_hp), int(max_hp)]
			
			# 按钮3：+2金币
			if button3:
				if "score" in cur_scene:
					button3.text = "+2 金币 (当前: %d)" % cur_scene.score
				else:
					button3.text = "+2 金币"

# 按钮1：+1血量上限
func _on_button1_pressed():
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		if hud:
			# 使用与商店相同的逻辑：增加血量上限并恢复1点血量
			if hud.add_max_health(1):
				hud.show_message("获得 +1 血量上限！")
			else:
				hud.show_message("生命值已达上限！")
	hide_chest_menu()

# 按钮2：+3血量
func _on_button2_pressed():
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		if hud:
			hud.heal_health(3)
			hud.show_message("获得 +3 血量！")
	hide_chest_menu()

# 按钮3：+2金币
func _on_button3_pressed():
	var cur_scene = get_tree().get_current_scene()
	if cur_scene:
		if "score" in cur_scene:
			cur_scene.score += 2
			if cur_scene.has_node("HUD"):
				var hud = cur_scene.get_node("HUD")
				if hud and hud.has_method("update_score"):
					hud.update_score(cur_scene.score)
				if hud and hud.has_method("show_message"):
					hud.show_message("获得 +2 金币！")
	hide_chest_menu()

# 按钮4：拉面宝物（伤害+10%）
func _on_button4_pressed():
	var cur_scene = get_tree().get_current_scene()
	if cur_scene:
		# 获取玩家节点并添加宝物
		var player = cur_scene.get_node_or_null("Player")
		if player and player.has_method("add_treasure"):
			player.add_treasure("ramen")
			if cur_scene.has_node("HUD"):
				var hud = cur_scene.get_node("HUD")
				if hud and hud.has_method("show_message"):
					hud.show_message("获得拉面！伤害+10%！")
			# 更新暂停菜单的宝物显示
			var pause_menu = get_tree().get_first_node_in_group("pause_menu")
			if pause_menu and pause_menu.has_method("update_value_labels"):
				pause_menu.update_value_labels()
	hide_chest_menu()
