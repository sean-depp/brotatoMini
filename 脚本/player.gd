extends Area2D

signal hit

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

# 武器系统：同时挂载多把枪（最多 `max_weapons`）
@export var max_weapons: int = 6
# 左右各三点，依次从上到下右侧再左侧
@export var weapon_offsets := [
	Vector2(40, -16),
	Vector2(40, 0),
	Vector2(40, 16),
	Vector2(-40, -16),
	Vector2(-40, 0),
	Vector2(-40, 16)
]
var weapons: Array = []
var weapon_scene = preload("res://武器/weapon.tscn")

func _ready() -> void:
	screen_size = get_viewport_rect().size
	add_weapon()
	
	hide()

func _physics_process(delta: float) -> void:
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("up"):
		velocity.y -= 1

	# 面向鼠标方向
	# look_at(get_global_mouse_position())

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

func under_hurt() -> void:
	#hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	# 如果在引擎的碰撞处理过程中禁用区域的碰撞形状可能会导致错误。
	# 使用 set_deferred() 告诉 Godot 等待可以安全地禁用形状时再这样做。
	$CollisionShape2D.set_deferred("disabled", true)

	$InvincibilityTimer.wait_time = 1
	$InvincibilityTimer.start()

func _on_body_entered(_body: Node2D) -> void:
	under_hurt()

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func _on_invincibility_timer_timeout() -> void:
	$CollisionShape2D.set_deferred("disabled", false)


# 在玩家身上添加一把武器实例（不会检查货币）
func add_weapon() -> bool:
	if weapons.size() >= max_weapons:
		return false
	var w = weapon_scene.instantiate()
	add_child(w)
	w.name = "Weapon%d" % (weapons.size() + 1)
	# 放置到预设偏移位置（如果有）
	if weapon_offsets.size() > weapons.size():
		w.position = weapon_offsets[weapons.size()]
	weapons.append(w)
	return true
