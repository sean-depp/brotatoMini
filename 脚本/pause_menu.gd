extends CanvasLayer

func update_value_labels() -> void:
	var cur_scene = get_tree().get_current_scene()
	if not cur_scene:
		return
	# HUD 的生命上限
	if cur_scene.has_node("HUD") and has_node("Grid/HPVBox/HPValue"):
		var hud = cur_scene.get_node("HUD")
		var hp_label = get_node("Grid/HPVBox/HPValue")
		if hud and hp_label:
			hp_label.text = "生命上限: %d" % hud.get_max_health()

	# Player -> Weapon 的数值
	if cur_scene.has_node("Player"):
		var player = cur_scene.get_node("Player")
		for child in player.get_children():
			if child is Weapon:
				var weapon = child
				if has_node("Grid/RangeVBox/RangeValue") and weapon.has_method("get_auto_shoot_range"):
					get_node("Grid/RangeVBox/RangeValue").text = "射程: %d" % int(weapon.get_auto_shoot_range())
				if has_node("Grid/FireVBox/FireValue") and weapon.has_method("get_auto_shoot_interval"):
					# 显示为秒数保留两位
					get_node("Grid/FireVBox/FireValue").text = "攻速: %.2fs" % weapon.get_auto_shoot_interval()
				if has_node("Grid/WeaponVBox/WeaponValue"):
					get_node("Grid/WeaponVBox/WeaponValue").text = "武器数: %d" % player.weapons.size()
				# 只处理第一个找到的 Weapon
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
					if hud.get_health() < hud.get_max_health():
						# 扣除金币，增加血量值
						hud.update_health_bar(1)
						main.score -= 2
						hud.update_score(main.score)
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
						hud.show_message("购买武器成功！")
						update_value_labels()
						return
					else:
						hud.show_message("武器数量已达上限！")
						return
			else:
				hud.show_message("金币不足！")			
