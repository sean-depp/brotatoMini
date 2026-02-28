# Godot 官方Demo - AI 编程助手指南

## 项目概述
一款 Godot 4.4 游戏项目，玩家躲避随机生成的怪物，随着等级提升，难度递增。核心架构采用场景节点树 + GDScript 脚本绑定的模式。

## 架构与数据流

### 核心场景层级
- **Main** (`main.gd`): 游戏主控制器，负责怪物生成、等级管理、游戏状态
- **Player** (`player.gd`): 玩家角色，Area2D 节点，鼠标操控、动画管理
- **HUD** (`hud.gd`): 用户界面层，血量、等级、得分显示
- **Mobs**: 怪物集群，RigidBody2D 物理节点，随机选择 5 种怪物类型显示

### 关键通信模式
1. **信号机制**: `Player.hit` 信号 → `Main.game_over()` 触发游戏结束判定
2. **组管理**: 怪物使用 `call_group("mobs", ...)` 实现批量操作（销毁、清空）
3. **计时器驱动**: `MobTimer`、`ScoreTimer`、`ChangeTimer` 分别控制怪物生成、得分增长、怪物转向

### 难度递增机制
在 `main.gd` 的 `game_update()` 中：
- 血量上限每关 +1
- 怪物生成速度递加（`MobTimer.wait_time` 递减至 0.5）
- 怪物移速范围 (`speed_min`/`speed_max`) 递增至 1000

## 场景与物理交互

### 碰撞设计
- **玩家-怪物**: Area2D 与 RigidBody2D，触发 `body_entered` 信号扣血
- **子弹-怪物**: Area2D 子弹检测 `body_entered`，命中后双方 `queue_free()`
- **子弹-屏幕**: VisibleOnScreenNotifier2D 检测离屏自动销毁

### 怪物多形态系统 (`mob.gd`)
- 单个 Mob 节点包含 5 个子节点对：`mob1-5` (AnimatedSprite2D + CollisionShape2D)
- 运行时随机激活一个类型，其他禁用（`disabled = true`）
- 使用 `sprite_frames.get_animation_names()` 获取动画列表

## 脚本约定与模式

### 资源导出 (`@export`)
```gdscript
@export var speed = 400          # Player 移动速度
@export var mob_scene: PackedScene  # Main 中的怪物场景引用
@export var bullet_scene: PackedScene  # Weapon 的子弹场景引用
```

### 输入处理
- **玩家移动**: 使用 Input.is_action_pressed("right"/"left"/"up"/"down")
- **射击**: `_input()` 检测 `InputEventMouseButton` 的左键，需检查 `player.visible` 状态
- **鼠标跟踪**: `player.look_at(get_global_mouse_position())` 实现视角对齐

### 延迟操作
使用 `set_deferred()` 在物理回调中安全禁用碰撞（见 `player.gd` 第 41 行）：
```gdscript
$CollisionShape2D.set_deferred("disabled", true)
```

## 重要工作流

### 怪物生成流程
1. `MobTimer.timeout` 触发 `_on_mob_timer_timeout()`
2. Path2D 上随机采样位置：`progress_ratio = randf()`
3. 设置旋转 + 随机偏角，计算速度方向
4. 使用 `add_child(mob)` 添加到场景树

### 血量系统 (`health.gd`)
- `HealthBar` 节点维护当前/最大血量
- HUD 通过 `update_health_bar(value)` 传递增减值（负数扣血）
- `get_health() <= 0` 触发 `show_game_over()`

### 子弹系统 (`weapon.gd`)
- 检查 `can_shoot` 和 `player.visible` 状态（无敌时段禁射）
- 子弹初速方向：`(mouse_pos - player_pos).normalized()`
- 射击冷却由 `ShootTimer` 管理，wait_time = 0.1

## 编码约定

### 文件组织
- `脚本/`: 所有 GDScript 文件（含 `.uid` 元数据）
- 场景文件: `主场景/main.tscn`、`玩家/player.tscn`、`怪物/mob.tscn`
- 美术资源: `资源/art/` 按怪物类型分类（Slime、BugBit、Spookmoth 等）

### 命名约定
- **节点名**: 英文+数字（如 `mob1`、`AnimatedSprite2D_1`）
- **脚本函数**: 使用下划线命名，避免动作顺序（如 `_on_timer_timeout`）
- **全局变量**: 驼峰式（如 `mob_visuals`、`can_shoot`）

### 调试与注释
- 关键逻辑包含中文注释说明（见 `mob.gd` 第 21-22 行）
- print() 用于快速调试（如 `weapon.gd` 第 14 行的错误检查）

## 常见扩展点

1. **新增怪物类型**: 在 `mob.gd` 中增加 mob6/AnimatedSprite2D_6 + CollisionShape2D_6
2. **武器升级**: 修改 `weapon.gd` 的 `fire_rate`、`bullet_scene` 或在 `shoot()` 添加多枪支
3. **特殊攻击**: 在 `mob_weapon.gd` 参考射击逻辑，为怪物增加反击机制
4. **难度曲线微调**: 调整 `main.gd` 的 speed_min/max 增量或生成频率递减速度

## 项目配置
- **Godot 版本**: 4.4
- **视口分辨率**: 1920×1080，采用 `canvas_items` 拉伸模式
- **输入映射**: WASD 移动、Arrow Keys 备选、Space 开始游戏
