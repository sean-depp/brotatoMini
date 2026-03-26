extends "res://脚本/Drop/drop_base.gd"

# 宝箱掉落物：拾取后弹出选择界面，选择一个奖励

# Sprite2D 节点（用于显示宝箱图片）
@onready var sprite: Sprite2D = $Sprite2D

# 宝箱选择界面场景
var chest_menu_scene = preload("res://主场景/chest_menu.tscn")

func _ready():
	super._ready()
	# 添加到宝箱组
	add_to_group("chests")

# 拾取效果：显示宝箱选择界面
func _on_pickup(_player: Node) -> void:
	# 获取主场景
	var main = _get_main()
	if main == null:
		return
	
	# 实例化宝箱选择界面
	var chest_menu = chest_menu_scene.instantiate()
	main.add_child(chest_menu)
	
	# 显示宝箱选择界面（会暂停游戏）
	chest_menu.show_chest_menu()
