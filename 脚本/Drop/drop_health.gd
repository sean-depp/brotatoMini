extends "res://脚本/Drop/drop_base.gd"

# 回血道具：玩家拾取后恢复2点生命值

# 回血量（可配置）
@export var heal_amount: float = 2.0

func _on_pickup(player: Node) -> void:
	# 检查玩家是否有回血方法
	if player and player.has_method("add_health"):
		var current_health = player.get_health()
		var max_health = player.get_max_health()
		
		# 只有未满血时才回血
		if current_health < max_health:
			# 恢复生命值
			player.add_health(heal_amount)
			
			# 更新HUD血条显示
			var hud = _get_hud()
			if hud and hud.has_method("update_health_bar"):
				hud.update_health_bar(player.get_health(), max_health)