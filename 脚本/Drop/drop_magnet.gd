extends "res://脚本/Drop/drop_base.gd"

# 吸磁道具：吸收地图上全部的金币

# 是否已被拾取（防止重复触发）
var has_collected: bool = false

func _on_pickup(_player: Node) -> void:
	# 防止重复触发
	if has_collected:
		return
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
			_start_magnet_track(item, _player)
	
	# 增加金币得分（在动画开始时立即加分，提升体验）
	var main = _get_main()
	if main and main.has_method("add_score"):
		main.add_score(collected_count)
	else:
		# 回退方案
		if main and "score" in main:
			main.score += collected_count
			var hud = _get_hud()
			if hud and hud.has_method("update_score"):
				hud.update_score(main.score)

# 启动追踪吸附动画
func _start_magnet_track(item: Node2D, player: Node) -> void:
	# 创建一个脚本实例来处理追踪动画
	var tracker = MagnetTracker.new()
	tracker.setup(item, player)
	get_tree().current_scene.add_child(tracker)

# 内部类：处理金币追踪动画
class MagnetTracker extends Node:
	var item: Node2D
	var player: Node
	var collected: bool = false
	
	# 速度参数
	var min_speed: float = 400.0   # 最小速度（近距离）
	var max_speed: float = 1500.0  # 最大速度（远距离）
	
	func setup(p_item: Node2D, p_player: Node) -> void:
		item = p_item
		player = p_player
	
	func _process(delta: float) -> void:
		# 检查金币是否还有效
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			queue_free()
			return
		
		# 检查玩家是否还有效
		if not is_instance_valid(player) or not player.is_inside_tree():
			# 玩家不存在了，直接销毁金币
			item.queue_free()
			queue_free()
			return
		
		# 获取玩家当前位置
		var target_pos = player.global_position
		
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