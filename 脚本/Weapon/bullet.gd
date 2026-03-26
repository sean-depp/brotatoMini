extends "res://脚本/Weapon/bullet_base.gd"

# 普通子弹：直线飞行，击中敌人造成伤害

# 掉落物品场景（已弃用，掉落逻辑已移至 mob.gd）
@export var drop_item_scene: PackedScene
@export var drop_magnet_scene: PackedScene

func _ready():
	super._ready()
	# 普通子弹类型
	bullet_type = BulletType.NORMAL