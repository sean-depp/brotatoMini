extends Area2D

# 回血道具：玩家拾取后恢复2点生命值

func _ready():
	# 连接与玩家的碰撞信号（Area2D 之间的碰撞使用 area_entered）
	connect("area_entered", Callable(self, "_on_area_entered"))
	
func _on_area_entered(area):
	# 检查碰撞对象是否为玩家
	if area.is_in_group("player"):
		# 获取玩家节点
		var player = area
		if player and player.has_method("add_health"):
			# 检查玩家是否已满血
			var current_health = player.get_health()
			var max_health = player.get_max_health()
			
			if current_health < max_health:
				# 恢复2点生命值
				player.add_health(2.0)
				
				# 更新HUD血条显示
				var hud = get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("update_health_bar"):
					hud.update_health_bar(player.get_health(), max_health)
		
		# 销毁回血道具
		queue_free()