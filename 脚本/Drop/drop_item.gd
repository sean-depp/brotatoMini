extends "res://脚本/Drop/drop_base.gd"

# 金币掉落物：玩家拾取后获得1金币

func _on_pickup(_player: Node) -> void:
	# 检查是否正在被吸磁动画处理
	if has_meta("animating"):
		return
	
	# 增加金币数：通过主场景的 add_score 方法统一处理
	var main = _get_main()
	if main and main.has_method("add_score"):
		main.add_score(1)
	else:
		# 作为回退：直接访问主节点的 score 并更新 HUD
		if main and "score" in main:
			main.score += 1
			var hud = _get_hud()
			if hud and hud.has_method("update_score"):
				hud.update_score(main.score)