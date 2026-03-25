extends CanvasLayer

func update_value_labels() -> void:
	var cur_scene = get_tree().get_current_scene()
	if not cur_scene:
		return
	
	# 更新金币显示
	if cur_scene.has_node("HUD") and has_node("MainContainer/RightPanel/StatsVBox/ScoreLabel"):
		var main = cur_scene
		if "score" in main:
			get_node("MainContainer/RightPanel/StatsVBox/ScoreLabel").text = "金币: %d" % main.score
	
	# HUD 的生命上限
	if cur_scene.has_node("HUD") and has_node("MainContainer/RightPanel/StatsVBox/HPValue"):
		var hud = cur_scene.get_node("HUD")
		var hp_label = get_node("MainContainer/RightPanel/StatsVBox/HPValue")
		if hud and hp_label:
			hp_label.text = "生命上限: %d" % hud.get_max_health()

	# Player -> Weapon 的数值（显示加成值，初始为0）
	if cur_scene.has_node("Player"):
		var player = cur_scene.get_node("Player")
		for child in player.get_children():
			if child is Weapon:
				var weapon = child
				# 显示射程加成
				if has_node("MainContainer/RightPanel/StatsVBox/RangeValue") and weapon.has_method("get_range_bonus"):
					get_node("MainContainer/RightPanel/StatsVBox/RangeValue").text = "射程: %d" % int(weapon.get_range_bonus())
				# 显示攻速加成（每秒攻击次数的增加值）
				if has_node("MainContainer/RightPanel/StatsVBox/FireValue") and weapon.has_method("get_fire_rate_bonus"):
					get_node("MainContainer/RightPanel/StatsVBox/FireValue").text = "攻速: %.1f" % weapon.get_fire_rate_bonus()
				if has_node("MainContainer/RightPanel/StatsVBox/WeaponValue"):
					get_node("MainContainer/RightPanel/StatsVBox/WeaponValue").text = "武器数: %d" % player.weapons.size()
				# 只处理第一个找到的 Weapon
				break
		
		# 更新速度显示
		if has_node("MainContainer/RightPanel/StatsVBox/SpeedValue") and player.has_method("get_speed"):
			get_node("MainContainer/RightPanel/StatsVBox/SpeedValue").text = "速度: %d" % int(player.get_speed())
		
		# 更新伤害加成显示（取第一个武器的伤害加成值）
		if has_node("MainContainer/RightPanel/StatsVBox/DamageValue"):
			for child in player.get_children():
				if child is Weapon:
					if child.has_method("get_damage_bonus"):
						get_node("MainContainer/RightPanel/StatsVBox/DamageValue").text = "伤害: %d" % child.get_damage_bonus()
					break

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
								any_upgraded = true
							else:
								any_upgraded = false

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
								any_upgraded = true
							else:
								any_upgraded = false
								
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
								any_upgraded = true
							else:
								any_upgraded = false
								
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
