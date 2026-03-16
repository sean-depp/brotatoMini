extends Area2D

# 吸磁道具：吸收地图上全部的金币

func _ready():
	# 连接与玩家的碰撞信号
	connect("area_entered", Callable(self, "_on_area_entered"))
	
func _on_area_entered(area):
	# 检查碰撞对象是否为玩家
	if area.is_in_group("player"):
		# 获取当前场景中所有的掉落金币
		var drop_items = get_tree().get_nodes_in_group("drops")
		var collected_count = 0
		
		# 遍历所有金币，统计后销毁
		for item in drop_items:
			if item != self and item.is_inside_tree():
				collected_count += 1
				item.queue_free()
		
		# 增加金币得分
		var main = get_tree().get_current_scene()
		if main and main.has_method("add_score"):
			main.add_score(collected_count)
		else:
			# 回退方案
			if main:
				if "score" in main:
					main.score += collected_count
					if main.has_node("HUD"):
						main.get_node("HUD").update_score(main.score)
		
		# 销毁吸磁道具
		queue_free()
