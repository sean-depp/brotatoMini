extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game
signal pause_toggle_requested

func _ready() -> void:
	# 设置为始终处理，即使游戏暂停也能接收输入
	process_mode = PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event.is_action_pressed("菜单"):
		pause_toggle_requested.emit()

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()
	
func show_level(level):
	var level_str = "Level: %d" % level
	$Level.text = level_str
	$Level.show()

	show_message(level_str)
	
func hide_message():
	$Message.hide()
	
func show_game_over():
	show_message("游戏结束")
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout
	
	$Message.text = "躲避怪物！ESC进入商店！"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	#await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	
func update_score(score):
	$ScoreLabel.text = str(score)

func update_health_bar(value:int):
	if value < 0:
		$HealthBar.subtract_health(abs(value))
	else:
		$HealthBar.add_health(value)
		
func get_health() -> int:
	return $HealthBar.get_health()

func set_max_health(new_max: int):
	$HealthBar.set_max_health(new_max)
	
func get_max_health() -> int:
	return $HealthBar.max_health

func set_full_health():
	$HealthBar.set_full_health()

func add_max_health(new_max: int) -> bool:
	return $HealthBar.add_max_health(new_max)

func _on_message_timer_timeout() -> void:
	$Message.hide()

func _on_start_button_pressed() -> void:
	$StartButton.hide()

	start_game.emit()

func show_pause_panel(isshow: bool) -> void:
	# 显示或隐藏暂停面板
	if isshow:
		# 在显示暂停面板前刷新其数值显示（如果实现了刷新方法）
		if has_node("PauseMenu"):
			var pm = $PauseMenu
			if pm and pm.has_method("update_value_labels"):
				pm.update_value_labels()
		$PauseMenu.show()
	else:
		# $PauseLabel.hide()
		$PauseMenu.hide()
