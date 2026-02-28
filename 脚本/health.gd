extends TextureRect

@onready var full_heart = $Full
@onready var empty_heart = $Empty

# 设置爱心状态
func set_heart_state(is_full: bool) -> void:
	full_heart.visible = is_full
	empty_heart.visible = !is_full
