extends Node2D
class_name ExplosionEffect

# 爆炸半径
@export var radius: float = 80.0

# 扩散时间（秒）
@export var expand_duration: float = 0.3

# 消失时间（秒）
@export var fade_duration: float = 0.2

# 圆圈颜色
@export var circle_color: Color = Color(1.0, 0.5, 0.0, 0.8)  # 橙色

# 内部填充颜色
@export var fill_color: Color = Color(1.0, 0.8, 0.0, 0.3)  # 半透明黄色

var elapsed_time: float = 0.0
var current_radius: float = 0.0
var current_alpha: float = 1.0

func _ready():
	# 初始半径为0
	current_radius = 0.0
	# 设置在最顶层
	z_index = 100

func _process(delta: float) -> void:
	elapsed_time += delta
	
	if elapsed_time <= expand_duration:
		# 扩散阶段
		var t = elapsed_time / expand_duration
		# 使用缓动函数让扩散更自然
		t = ease(t, -2.0)  # 缓出效果
		current_radius = radius * t
		current_alpha = 1.0
	elif elapsed_time <= expand_duration + fade_duration:
		# 消失阶段
		var t = (elapsed_time - expand_duration) / fade_duration
		current_alpha = 1.0 - t
	else:
		# 动画结束，销毁
		queue_free()
	
	# 重绘
	queue_redraw()

func _draw() -> void:
	if current_alpha <= 0:
		return
	
	# 绘制填充圆
	var fill_alpha = fill_color.a * current_alpha
	draw_circle(Vector2.ZERO, current_radius, Color(fill_color.r, fill_color.g, fill_color.b, fill_alpha))
	
	# 绘制圆圈边框（多画几圈增加效果）
	var line_alpha = circle_color.a * current_alpha
	
	# 外圈
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, Color(circle_color.r, circle_color.g, circle_color.b, line_alpha), 3.0)
	
	# 中圈
	if current_radius > 10:
		draw_arc(Vector2.ZERO, current_radius * 0.7, 0, TAU, 48, Color(circle_color.r, circle_color.g, circle_color.b, line_alpha * 0.6), 2.0)
	
	# 内圈
	if current_radius > 20:
		draw_arc(Vector2.ZERO, current_radius * 0.4, 0, TAU, 32, Color(circle_color.r, circle_color.g, circle_color.b, line_alpha * 0.3), 1.5)