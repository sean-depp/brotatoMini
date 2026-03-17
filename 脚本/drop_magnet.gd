extends Area2D

# 吸磁道具：吸收地图上全部的金币
var has_collected = false

func _ready():
	# 连接与玩家的碰撞信号
	connect("area_entered", Callable(self, "_on_area_entered"))
	
func _on_area_entered(area):
	# 检查碰撞对象是否为玩家
	if area.is_in_group("player") and not has_collected:
		has_collected = true
		# 获取当前场景中所有的掉落金币
		var drop_items = get_tree().get_nodes_in_group("drops")
		var collected_count = 0
		
		# 遍历所有金币，统计后销毁
		for item in drop_items:
			if item != self and item.is_inside_tree() and not item.is_queued_for_deletion() and not item.has_meta("animating"):
				collected_count += 1
				# 开始吸附动画到玩家位置
				item.set_meta("animating", true)
				var tween = item.create_tween()
				# 从当前位置移动到玩家位置，持续0.5秒
				tween.tween_property(item, "global_position", area.global_position, 0.5)
				tween.tween_callback(item.queue_free)
		
		# 增加金币得分
		var main = get_tree().get_current_scene()
		if main and main.has_method("add_score"):
			main.add_score(collected_count)
			# print("Collected ", collected_count, " coins with magnet!")
		else:
			# 回退方案
			if main:
				if "score" in main:
					main.score += collected_count
					if main.has_node("HUD"):
						main.get_node("HUD").update_score(main.score)
		
		# 销毁吸磁道具
		queue_free()
