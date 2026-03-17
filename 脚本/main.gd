extends Node

@export var mob_scene: PackedScene
var score = 0
var cur_level = 1
var speed_min = 150
var speed_max = 250
var running = false

# 怪物类型批量生成配置（怪物类型索引 -> 生成数量）
var mob_spawn_count := {
	0: 1,  # mob1 生成1个
	1: 1,  # mob2 生成1个
	2: 1,  # mob3 生成1个
	3: 1,  # mob4 生成1个
	4: 5,  # mob5 生成5个
}

func _ready() -> void:
	$HUD.pause_toggle_requested.connect(_on_pause_toggle_requested)
	
	# 设置相机跟踪玩家
	_setup_camera()
	
	# 初始化：玩家和相机都放在 StartPos，避免初始时显示灰色区域
	$Player.start($StartPos.position)
	if has_node("Camera2D"):
		get_node("Camera2D").global_position = $StartPos.position
	
	# 绘制地图边界
	_draw_map_boundary()

func _on_pause_toggle_requested():
	if not running:
		return

	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	$HUD.show_pause_panel(true)

func resume_game():
	$HUD.show_pause_panel(false)
	get_tree().paused = false

func game_over():
	$HUD.update_health_bar(-1)

	# 检测血量，只有为0才是game over
	if $HUD.get_health() <= 0:
		running = false
		$Player.hide()
		
		$ScoreTimer.stop()
		$MobTimer.stop()

		$HUD.show_game_over()
		$Music.stop()
		$DeathSound.play()

func game_update():
	score = 0
	$HUD.update_score(score)
	
	# 0.5 1，提升到1就不提升了
	$ScoreTimer.stop()
	if cur_level <= 2:
		$ScoreTimer.wait_time += 0.5
	$ScoreTimer.start()

	# 显示等级
	$HUD.show_level(cur_level)
	
	# 怪物生成加速
	if $MobTimer.wait_time > 0.5:
		$MobTimer.wait_time -= 0.1

	# 怪物移速增加
	if speed_max < 1000:
		speed_min += 50
		speed_max += 100

	# 每关增加1个血量上限
	# $HUD.add_max_health(1)

func add_score(amount: int = 1) -> void:
	# 通过主脚本统一修改分数并更新 HUD
	score += amount
	$HUD.update_score(score)

func is_running() -> bool:
	return running

# func _process(_delta: float) -> void:
# 	# 实时跟踪玩家位置到相机
# 	if running and has_node("Camera2D") and has_node("Player"):
# 		var camera = get_node("Camera2D")
# 		var player = get_node("Player")
# 		if camera.is_current():
# 			camera.global_position = player.global_position

func _process(_delta: float) -> void:
	# 实时跟踪玩家位置到相机，但限制在地图边界内
	if running and has_node("Camera2D") and has_node("Player"):
		var camera = get_node("Camera2D")
		var player = get_node("Player")
		if camera.is_current():
			# 计算相机应该跟随的目标位置
			var target_pos = player.global_position
			
			# 地图边界 (0,0) 到 (2560,1440)
			# 考虑相机视口大小，确保相机不会超出地图边界
			var viewport_size = get_viewport().size
			var half_viewport_x = viewport_size.x / 2
			var half_viewport_y = viewport_size.y / 2
		
			# 限制相机位置，确保不会超出地图边界
			target_pos.x = clamp(target_pos.x, half_viewport_x, 2560 - half_viewport_x)
			target_pos.y = clamp(target_pos.y, half_viewport_y, 1440 - half_viewport_y)
		
			# 设置相机位置
			camera.global_position = target_pos

func _setup_camera() -> void:
	# 检查是否已存在 Camera2D
	if has_node("Camera2D"):
		return
	
	# 创建 Camera2D
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	add_child(camera)
	
	# 配置相机
	camera.enabled = true
	camera.make_current()
	camera.zoom = Vector2(1.0, 1.0)
	
	# 启用平滑跟踪，改善移动手感
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0

func _create_background_overlay() -> void:
	# 创建一个 CanvasLayer 来显示背景（在 HUD 下面）
	if has_node("BackgroundLayer"):
		return
	
	var bg_layer = CanvasLayer.new()
	bg_layer.name = "BackgroundLayer"
	bg_layer.layer = -1  # 在所有东西下面
	add_child(bg_layer)
	
	# 创建背景 ColorRect（覆盖整个游戏区域）
	var bg_rect = ColorRect.new()
	bg_rect.name = "BG"
	bg_rect.color = Color(0.235294, 0.372549, 1, 1)
	bg_rect.anchor_left = 0.0
	bg_rect.anchor_top = 0.0
	bg_rect.anchor_right = 1.0
	bg_rect.anchor_bottom = 1.0
	bg_layer.add_child(bg_rect)

func _draw_map_boundary() -> void:
	# 如果边界已存在，删除旧的
	if has_node("MapBoundary"):
		get_node("MapBoundary").queue_free()
	
	# 创建地图边界线
	var boundary = Line2D.new()
	boundary.name = "MapBoundary"
	boundary.width = 2.0
	boundary.default_color = Color.WHITE
	boundary.closed = true
	
	# 绘制矩形边界 (0,0)-(2560,1440)
	boundary.add_point(Vector2(0, 0))
	boundary.add_point(Vector2(2560, 0))
	boundary.add_point(Vector2(2560, 1440))
	boundary.add_point(Vector2(0, 1440))
	
	add_child(boundary)

func new_game():
	# 通过start_game信号启动新游戏
	running = true
	# 清理场景中残留的怪物和掉落物
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("drops", "queue_free")
	get_tree().call_group("magnets", "queue_free")
	get_tree().call_group("mob_bullets", "queue_free")
	
	score = 20
	
	$HUD.set_max_health(1)
	$HUD.set_full_health()

	$Player.start($StartPos.position)
	
	#$StartTimer.start()
	
	$HUD.update_score(score)
	$HUD.hide_message()
	$HUD.get_node("MessageTimer").stop()
	#$HUD.show_message("准备完成")
	
	$Music.play()
	
	$MobTimer.start()
	$ScoreTimer.start()
	
func _on_mob_timer_timeout() -> void:
	# 随机选择一个怪物类型（0-4）
	var mob_type = randi() % 5
	
	# 根据配置获取该怪物类型的生成数量
	var spawn_count = mob_spawn_count.get(mob_type, 1)
	
	# 批量生成怪物
	for i in range(spawn_count):
		# Create a new instance of the Mob scene.
		var mob = mob_scene.instantiate()

		# 在地图范围内随机生成怪物位置（直接在范围内，不在边界外）
		var spawn_pos = Vector2(
			randf_range(100, 2460),  # x: 100 到 2460（避免边界）
			randf_range(100, 1340)   # y: 100 到 1340（避免边界）
		)
		
		mob.global_position = spawn_pos

		# 随机方向
		var direction = randf_range(0, TAU)
		mob.rotation = direction

		# Choose the velocity for the mob.
		var velocity = Vector2(randf_range(speed_min, speed_max), 0.0)
		mob.linear_velocity = velocity.rotated(direction)

		# Spawn the mob by adding it to the Main scene.
		add_child(mob)

func _on_score_timer_timeout() -> void:
	pass
	# score += 1
	# $HUD.update_score(score)
	
	# # 如果超过了10，就认为游戏成功，升级到下一关
	# if score >= 10:
	# 	cur_level += 1
	# 	game_update()

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
