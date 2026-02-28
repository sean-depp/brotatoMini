extends Area2D

# todo 提供金币全吸附的道具掉落

func _ready():
	# 连接与玩家的碰撞信号（Area2D 之间的碰撞使用 area_entered）
	connect("area_entered", Callable(self, "_on_area_entered"))
	
func _on_area_entered(area):
	# 检查碰撞对象是否为玩家
	if area.is_in_group("player"):
		# 触发增加金币数：通过主场景的 add_score 方法统一处理
		var main = get_tree().get_current_scene()
		if main and main.has_method("add_score"):
			main.add_score(1)
		else:
			# 作为回退（极少使用）：直接访问主节点的 score 并更新 HUD
			if main:
				if "score" in main:
					main.score += 1
					if main.has_node("HUD"):
						main.get_node("HUD").update_score(main.score)
		# 销毁拾取物
		queue_free()
		
