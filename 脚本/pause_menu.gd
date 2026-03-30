extends CanvasLayer

# 宝物定义（与 player.gd 保持同步）
const TREASURE_DEFINITIONS = {
	"ramen": {"name": "拉面", "description": "伤害+10%", "damage_bonus_percent": 0.1, "color": Color(1.0, 0.8, 0.4)},
}

func _ready() -> void:
	# 添加到 pause_menu 组，方便其他节点查找
	add_to_group("pause_menu")
	
	# 设置宝物图标的鼠标事件
	_setup_treasure_tooltip()

# 设置宝物悬浮提示
func _setup_treasure_tooltip() -> void:
	var ramen_icon_slot = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/RamenIconSlot")
	if ramen_icon_slot:
		# 启用鼠标事件
		ramen_icon_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# 连接鼠标事件
		ramen_icon_slot.mouse_entered.connect(_on_treasure_mouse_entered.bind("ramen"))
		ramen_icon_slot.mouse_exited.connect(_on_treasure_mouse_exited)

# 鼠标进入宝物图标
func _on_treasure_mouse_entered(treasure_id: String) -> void:
	var tooltip_panel = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/RamenIconSlot/TooltipPanel")
	if tooltip_panel:
		tooltip_panel.visible = true

# 鼠标离开宝物图标
func _on_treasure_mouse_exited() -> void:
	var tooltip_panel = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/RamenIconSlot/TooltipPanel")
	if tooltip_panel:
		tooltip_panel.visible = false

func update_value_labels() -> void:
	var cur_scene = get_tree().get_current_scene()
	if not cur_scene:
		return
	
	# 更新金币显示
	if cur_scene.has_node("HUD") and has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/ScoreLabel"):
		var main = cur_scene
		if "score" in main:
			get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/ScoreLabel").text = "金币: %d" % main.score
	
	# HUD 的生命上限
	if cur_scene.has_node("HUD") and has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/HPValue"):
		var hud = cur_scene.get_node("HUD")
		var hp_label = get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/HPValue")
		if hud and hp_label:
			hp_label.text = "生命上限: %d" % hud.get_max_health()

	# Player -> Weapon 的数值（显示加成值，初始为0）
	if cur_scene.has_node("Player"):
		var player = cur_scene.get_node("Player")
		
		# 更新武器槽显示
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/WeaponSlotValue"):
			get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/WeaponSlotValue").text = "武器槽: %d/%d" % [player.weapons.size(), player.max_weapons]
		
		# 查找第一个武器用于显示属性
		var first_weapon = null
		for child in player.get_children():
			if child is Weapon:
				first_weapon = child
				break
		
		# 更新射程显示
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/RangeValue"):
			if first_weapon and first_weapon.has_method("get_range_bonus"):
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/RangeValue").text = "射程: %d" % int(first_weapon.get_range_bonus())
			else:
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/RangeValue").text = "射程: 0"
		
		# 更新攻速显示
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/FireValue"):
			if first_weapon and first_weapon.has_method("get_fire_rate_bonus"):
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/FireValue").text = "攻速: %.1f" % first_weapon.get_fire_rate_bonus()
			else:
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/FireValue").text = "攻速: 0.0"
		
		# 更新速度显示
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/SpeedValue") and player.has_method("get_speed"):
			get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/SpeedValue").text = "速度: %d" % int(player.get_speed())
		
		# 更新伤害加成显示（合并显示武器加成 + 宝物加成）
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/DamageValue"):
			if first_weapon and first_weapon.has_method("get_damage_bonus"):
				var total_bonus = first_weapon.get_damage_bonus()  # 已包含宝物加成
				var percent = total_bonus * 10  # 每点加成10%
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/DamageValue").text = "伤害: +%d%%" % percent
			else:
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/DamageValue").text = "伤害: +0%"
		
		# 更新爆炸范围加成显示
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/ExplosionValue"):
			if first_weapon and first_weapon.has_method("get_explosion_radius_bonus"):
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/ExplosionValue").text = "爆炸范围: %d" % int(first_weapon.get_explosion_radius_bonus())
			else:
				get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/ExplosionValue").text = "爆炸范围: 0"
		
		# 更新防御值显示
		if has_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/DefenseValue") and player.has_method("get_defense"):
			var defense = player.get_defense()
			var damage_reduction = min(defense * 2, 90)  # 每点防御减少2%伤害，最高90%
			get_node("MainContainer/ContentRow/RightPanel/RightContent/StatsVBox/DefenseValue").text = "防御: %d (%d%%减伤)" % [int(defense), damage_reduction]
		
		# 更新宝物显示
		update_treasure_display(player)

func _on_buy_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检测金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 2:
				if hud.add_max_health(1):
					# 扣除金币，增加血量上限
					main.score -= 2
					hud.update_score(main.score)
					update_value_labels()
				else:
					# 生命值已达上限提示
					hud.show_message("生命值已达上限！")
			else:
				# 金币不足提示
				hud.show_message("金币不足！")

func _on_fire_rate_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		# 检查金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 1:
				# 尝试找到 Player 的所有武器并一次性升级（成功则只扣一次金币）
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					var found = false
					var any_upgraded = false
					for child in player.get_children():
						if typeof(child) == TYPE_OBJECT and child.has_method("decrease_auto_shoot_interval"):
							found = true
							if child.decrease_auto_shoot_interval(0.01):
								any_upgraded = true  # 只要有任何一个武器升级成功就标记为成功

					# 没有找到任何武器
					if not found:
						hud.show_message("未找到武器！")
						return
					if any_upgraded:
						main.score -= 1
						hud.update_score(main.score)
						update_value_labels()
						return
					else:
						hud.show_message("攻速已达上限！")
						return
			else:
				hud.show_message("金币不足！")
	else:
		# 回退提示
		print("无法访问 HUD 或当前场景")

func _on_range_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		# 检查金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 1:
				# 尝试找到 Player 的所有武器并一次性升级射程（成功则只扣一次金币）
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					var found = false
					var any_upgraded = false
					for child in player.get_children():
						if typeof(child) == TYPE_OBJECT and child.has_method("increase_auto_shoot_range"):
							found = true
							if child.increase_auto_shoot_range(20.0):
								any_upgraded = true  # 只要有任何一个武器升级成功就标记为成功
								
					if not found:
						hud.show_message("未找到武器！")
						return
					if any_upgraded:
						main.score -= 1
						hud.update_score(main.score)
						update_value_labels()
						return
					else:
						hud.show_message("射程已达上限！")
						return
			
			else:
				hud.show_message("金币不足！")
	else:
		print("无法访问 HUD 或当前场景")


func _on_weapon_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var main = get_tree().get_current_scene()
		var hud = cur_scene.get_node("HUD")

		if main and "score" in main:
			if main.score >= 10:
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					if player.add_weapon():
						main.score -= 10
						hud.update_score(main.score)
						hud.show_message("购买冲锋枪成功！")
						update_value_labels()
						return
					else:
						hud.show_message("武器数量已达上限！")
						return
			else:
				hud.show_message("金币不足！")

func _on_shotgun_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var main = get_tree().get_current_scene()
		var hud = cur_scene.get_node("HUD")

		if main and "score" in main:
			if main.score >= 15:
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					if player.add_shotgun():
						main.score -= 15
						hud.update_score(main.score)
						hud.show_message("购买霰弹枪成功！")
						update_value_labels()
						return
					else:
						hud.show_message("武器数量已达上限！")
						return
			else:
				hud.show_message("金币不足！")

func _on_grenade_launcher_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var main = get_tree().get_current_scene()
		var hud = cur_scene.get_node("HUD")

		if main and "score" in main:
			if main.score >= 20:
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					if player.add_grenade_launcher():
						main.score -= 20
						hud.update_score(main.score)
						hud.show_message("购买榴弹枪成功！")
						update_value_labels()
						return
					else:
						hud.show_message("武器数量已达上限！")
						return
			else:
				hud.show_message("金币不足！")

func _on_heal_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检查金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 1:
				# 尝试恢复血量
				if hud.heal_health(1):
					# 扣除金币，恢复1血
					main.score -= 1
					hud.update_score(main.score)
					update_value_labels()
				else:
					# 血量已满提示
					hud.show_message("血量已满！")
			else:
				# 金币不足提示
				hud.show_message("金币不足！")

func _on_speed_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检测金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 1:
				# 尝试增加速度
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					if player.increase_speed(20.0):
						# 扣除金币，增加20速度
						main.score -= 1
						hud.update_score(main.score)
						update_value_labels()
					else:
						# 速度已达上限提示
						hud.show_message("速度已达上限！")
			else:
				# 金币不足提示
				hud.show_message("金币不足！")

func _on_damage_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检测金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 10:
				# 尝试找到 Player 的所有武器并一次性升级伤害（成功则只扣一次金币）
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					var found = false
					var any_upgraded = false
					for child in player.get_children():
						if typeof(child) == TYPE_OBJECT and child.has_method("increase_damage"):
							found = true
							if child.increase_damage(1):
								any_upgraded = true  # 只要有任何一个武器升级成功就标记为成功
								
					if not found:
						hud.show_message("未找到武器！")
						return
					if any_upgraded:
						main.score -= 10
						hud.update_score(main.score)
						update_value_labels()
						return
					else:
						hud.show_message("伤害已达上限！")
						return
			else:
				hud.show_message("金币不足！")

func _on_explosion_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检测金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 10:
				# 尝试找到 Player 的所有武器并一次性升级爆炸范围（成功则只扣一次金币）
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					var found = false
					var any_upgraded = false
					for child in player.get_children():
						if typeof(child) == TYPE_OBJECT and child.has_method("increase_explosion_radius"):
							found = true
							if child.increase_explosion_radius(10.0):
								any_upgraded = true  # 只要有任何一个武器升级成功就标记为成功
								
					if not found:
						hud.show_message("未找到武器！")
						return
					if any_upgraded:
						main.score -= 10
						hud.update_score(main.score)
						update_value_labels()
						return
					else:
						hud.show_message("爆炸范围已达上限！")
						return
			else:
				hud.show_message("金币不足！")

func _on_defense_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检测金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 5:
				# 尝试增加防御值
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					if player.has_method("increase_defense"):
						# 检查防御值上限（最高9点，90%减伤）
						if player.get_defense() >= 9:
							hud.show_message("防御已达上限！")
							return
						player.increase_defense(1.0)
						main.score -= 5
						hud.update_score(main.score)
						update_value_labels()
						hud.show_message("购买防御成功！")
					else:
						hud.show_message("无法增加防御！")
			else:
				hud.show_message("金币不足！")

func _on_weapon_slot_button_pressed() -> void:
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_node("HUD"):
		var hud = cur_scene.get_node("HUD")
		
		# 检测金币数
		var main = get_tree().get_current_scene()
		if main and "score" in main:
			if main.score >= 30:
				# 尝试增加武器槽
				if cur_scene.has_node("Player"):
					var player = cur_scene.get_node("Player")
					if player.has_method("increase_weapon_slots"):
						if player.increase_weapon_slots():
							main.score -= 30
							hud.update_score(main.score)
							update_value_labels()
							hud.show_message("购买武器槽成功！当前上限: %d" % player.max_weapons)
						else:
							hud.show_message("武器槽已达上限！")
					else:
						hud.show_message("无法增加武器槽！")
			else:
				hud.show_message("金币不足！")

func _on_restart_button_pressed() -> void:
	# 取消暂停
	get_tree().paused = false
	
	# 获取当前场景并调用 new_game
	var cur_scene = get_tree().get_current_scene()
	if cur_scene and cur_scene.has_method("new_game"):
		cur_scene.new_game()
	
	# 隐藏暂停菜单面板
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_pause_panel"):
		hud.show_pause_panel(false)

# 更新宝物显示
func update_treasure_display(player: Node) -> void:
	# 获取玩家的宝物列表
	if not player.has_method("get_treasures"):
		return
	var treasures = player.get_treasures()
	
	# 统计宝物数量
	var treasure_counts = {}
	for treasure_id in treasures:
		if treasure_id in treasure_counts:
			treasure_counts[treasure_id] += 1
		else:
			treasure_counts[treasure_id] = 1
	
	# 更新拉面显示（使用预留的节点）
	var ramen_count = treasure_counts.get("ramen", 0)
	var ramen_icon_slot = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/RamenIconSlot")
	if ramen_icon_slot:
		# 显示/隐藏整个槽位
		ramen_icon_slot.visible = ramen_count > 0
		
		# 更新数量标签（显示在右上角）
		var count_label = ramen_icon_slot.get_node_or_null("RamenCount")
		if count_label:
			if ramen_count > 0:
				count_label.text = str(ramen_count)
				count_label.visible = true
			else:
				count_label.visible = false
		
		# 更新悬浮面板内容
		_update_tooltip_content("ramen", ramen_count, player)
	
	# 隐藏未使用的宝物槽
	var slot1 = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/TreasureSlot1")
	var slot2 = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/TreasureSlot2")
	if slot1:
		slot1.visible = false
	if slot2:
		slot2.visible = false

# 更新悬浮面板内容
func _update_tooltip_content(treasure_id: String, count: int, player: Node) -> void:
	var tooltip_panel = get_node_or_null("MainContainer/ContentRow/MiddlePanel/MiddleContent/TreasureSection/TreasureGrid/RamenIconSlot/TooltipPanel")
	if not tooltip_panel:
		return
	
	var name_label = tooltip_panel.get_node_or_null("TooltipContent/TooltipName")
	var desc_label = tooltip_panel.get_node_or_null("TooltipContent/TooltipDesc")
	var count_label = tooltip_panel.get_node_or_null("TooltipContent/TooltipCount")
	
	var treasure_info = player.get_treasure_info(treasure_id)
	if treasure_info.is_empty():
		return
	
	# 更新名称
	if name_label:
		name_label.text = treasure_info.get("name", "宝物")
	
	# 更新描述
	if desc_label:
		var description = treasure_info.get("description", "")
		# 如果有多个，显示总加成
		if count > 1:
			var damage_bonus = treasure_info.get("damage_bonus_percent", 0.0)
			if damage_bonus > 0:
				var total_bonus = damage_bonus * count * 100
				description = "伤害+%d%%" % int(total_bonus)
		desc_label.text = description
	
	# 更新数量
	if count_label:
		if count > 1:
			count_label.text = "数量: %d" % count
			count_label.visible = true
		else:
			count_label.visible = false
