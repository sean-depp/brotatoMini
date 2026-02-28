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

func new_game():
	# 通过start_game信号启动新游戏
	running = true
	# 清理场景中残留的怪物和掉落物
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("drops", "queue_free")
	
	score = 20
	
	$HUD.set_max_health(1)
	$HUD.set_full_health()

	$Player.start($StartPos.position)
	#$StartTimer.start()
	
	$HUD.update_score(score)
	$HUD.hide_message()
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

		# Choose a random location on Path2D.
		var mob_spawn_location = $MobPath/MobSpawnLocation
		
		# 随机起始位置
		mob_spawn_location.progress_ratio = randf()

		# Set the mob's position to the random location.
		mob.position = mob_spawn_location.position

		# Set the mob's direction perpendicular to the path direction.
		# 沿着法线往里移动
		var direction = mob_spawn_location.rotation + PI / 2

		# Add some randomness to the direction.
		direction += randf_range(-PI / 4, PI / 4)
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
