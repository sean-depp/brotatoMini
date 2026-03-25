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
		
		# 遍历所有金币，创建追踪动画
		for item in drop_items:
			if item != self and item.is_inside_tree() and not item.is_queued_for_deletion() and not item.has_meta("animating"):
				collected_count += 1
				# 标记为动画中
				item.set_meta("animating", true)
				# 启动追踪吸附
				_start_magnet_track(item, area)
		
		# 增加金币得分（在动画开始时立即加分，提升体验）
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

# 启动追踪吸附动画
func _start_magnet_track(item: Node2D, player_area: Area2D) -> void:
	# 创建一个脚本实例来处理追踪动画
	var tracker = MagnetTracker.new()
	tracker.setup(item, player_area)
	get_tree().current_scene.add_child(tracker)

# 内部类：处理金币追踪动画
class MagnetTracker extends Node:
	var item: Node2D
	var player_area: Area2D
	var collected: bool = false
	
	# 速度参数
	var min_speed: float = 400.0   # 最小速度（近距离）
	var max_speed: float = 1500.0  # 最大速度（远距离）
	
	func setup(p_item: Node2D, p_player_area: Area2D) -> void:
		item = p_item
		player_area = p_player_area
	
	func _process(delta: float) -> void:
		# 检查金币是否还有效
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			queue_free()
			return
		
		# 检查玩家是否还有效
		if not is_instance_valid(player_area) or not player_area.is_inside_tree():
			# 玩家不存在了，直接销毁金币
			item.queue_free()
			queue_free()
			return
		
		# 获取玩家当前位置
		var target_pos = player_area.global_position
		
		# 计算方向和距离
		var direction = (target_pos - item.global_position).normalized()
		var distance = item.global_position.distance_to(target_pos)
		
		# 检查是否到达玩家位置（收集）
		if distance < 15:
			item.queue_free()
			queue_free()
			return
		
		# 根据距离计算速度（距离越远速度越快）
		var speed = min_speed
		if distance > 300:
			speed = max_speed
		elif distance > 100:
			# 线性插值
			speed = min_speed + (max_speed - min_speed) * ((distance - 100) / 200.0)
		
		# 直接向玩家移动（不累积速度，避免飞过头）
		var move_distance = speed * delta
		# 确保不会移动超过剩余距离
		if move_distance > distance:
			move_distance = distance
		
		item.global_position += direction * move_distance