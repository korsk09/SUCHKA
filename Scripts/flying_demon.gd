extends CharacterBody2D

# Настройки скоростей
@export var hover_speed := 150.0
@export var dash_speed := 600.0
@export var acceleration := 400.0
@export var max_hp := 3
var current_hp := 3
@export var contact_damage := 1
@export var knockback_force := 200.0
@export var knockback_time := 0.2

var knockback_timer := 0.0

# Ссылки на объекты
@export var fireball_scene: PackedScene
@onready var state_timer: Timer = $StateTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Ссылки на маркеры (Убедитесь, что пути в кавычках верные!)
@onready var point_a: Marker2D = $"../PointA"
@onready var point_b: Marker2D = $"../PointB"
@onready var point_center: Marker2D = $"../PointCenter"
@onready var sprite_2d: Sprite2D = $Sprite2D

# Состояния босса
enum BossState { IDLE, PATROL, SHOOT, DASH, PREPARE, HURT, DEAD }
var current_state: BossState = BossState.IDLE
var previous_state: BossState = BossState.IDLE

# --- ПЕРЕМЕННЫЕ ЛОГИКИ (Те, что выдавали ошибки) ---
var target_player: Node2D = null
var room_points: Array = []        # Список позиций для полета
var current_point_idx: int = 0     # Индекс текущей точки
var patrol_target: Vector2         # Координаты куда летим сейчас
var dash_direction := Vector2.ZERO # Направление рывка

func _ready():
    current_hp = max_hp
    target_player = get_tree().get_first_node_in_group("player")
    animation_player.animation_finished.connect(_on_animation_finished)
    
    if point_a and point_b:
        room_points = [point_a.global_position, point_b.global_position]
        patrol_target = room_points[0]
    
    pick_random_state()

func _physics_process(delta: float):
    if current_state == BossState.DEAD:
        return

    handle_animations() # Обновляем анимации каждый кадр
    
    match current_state:
        BossState.PATROL:
            patrol_logic(delta)
        BossState.SHOOT:
            velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
        BossState.DASH:
            dash_logic(delta)
        BossState.HURT:
            knockback_timer -= delta
            if knockback_timer <= 0:
                velocity = Vector2.ZERO
                # После того как отлетели от удара, возвращаемся к рандомной атаке
                pick_random_state()
            
    move_and_slide()

# --- СИСТЕМА АНИМАЦИЙ (Как у обычного врага) ---
func handle_animations():
    if current_state == previous_state:
        return
    
    previous_state = current_state
    
    match current_state:
        BossState.PATROL, BossState.IDLE:
            animation_player.play("Fly") # Или "Walk"
        BossState.SHOOT:
            animation_player.play("Idle") # Босс замирает перед стрельбой
        BossState.PREPARE:
            animation_player.play("Prepare") # Анимация замаха
        BossState.DASH:
            animation_player.play("Dash")
        BossState.HURT:
            AudioController.play_zombie_hit() # Используем твои звуки
            animation_player.play("Hurt")
        BossState.DEAD:
            AudioController.play_zombie_dead()
            animation_player.play("Dead")

# --- ЛОГИКА ВЫБОРА СОСТОЯНИЙ ---
func pick_random_state():
    #Если босс мертв, ничего не делаем
    if current_state == BossState.DEAD:
        return
    
    # Сбрасываем состояние на IDLE перед выбором нового, 
    # чтобы обойти проверку "if current_state == BossState.HURT"
    current_state = BossState.IDLE 
    
    var r = randi_range(1, 3)
    match r:
        1: start_patrol()
        2: start_shoot()
        3: start_dash_prepare()

func _on_state_timer_timeout() -> void:
    if current_state == BossState.PATROL:
        pick_random_state()

# --- ПАТТЕРНЫ АТАК (Твоя логика) ---
func start_patrol():
    current_state = BossState.PATROL
    state_timer.start(4.0) 

func patrol_logic(delta):
    if room_points.size() == 0: return
    if global_position.distance_to(patrol_target) < 20:
        current_point_idx = (current_point_idx + 1) % room_points.size()
        patrol_target = room_points[current_point_idx]
    
    var dir = (patrol_target - global_position).normalized()
    velocity = velocity.move_toward(dir * hover_speed, acceleration * delta)
    sprite_2d.flip_h = velocity.x > 0

func start_shoot():
    current_state = BossState.SHOOT
    var center_pos = point_center.global_position if point_center else global_position
    var tween = create_tween()
    tween.tween_property(self, "global_position", center_pos, 1.0).set_trans(Tween.TRANS_SINE)
    tween.finished.connect(_on_reached_center)

func _on_reached_center():
    if current_state != BossState.SHOOT: return
    for i in range(3):
        if current_state == BossState.SHOOT:
            spawn_fireball()
            await get_tree().create_timer(0.5).timeout
    pick_random_state()

func spawn_fireball():
    if fireball_scene and target_player:
        var ball = fireball_scene.instantiate()
        ball.global_position = global_position
        ball.direction = (target_player.global_position - global_position).normalized()
        get_parent().add_child(ball)

func start_dash_prepare():
    current_state = BossState.PREPARE
    var corner = room_points.pick_random() if room_points.size() > 0 else global_position
    var tween = create_tween()
    tween.tween_property(self, "global_position", corner, 0.8)
    tween.finished.connect(_prepare_dash)

func _prepare_dash():
    if current_state != BossState.PREPARE: return
    await get_tree().create_timer(1.0).timeout
    if target_player:
        dash_direction = (target_player.global_position - global_position).normalized()
        current_state = BossState.DASH
        sprite_2d.flip_h = dash_direction.x > 0
        await get_tree().create_timer(0.8).timeout
        pick_random_state()

func dash_logic(_delta):
    velocity = dash_direction * dash_speed

# --- ПОЛУЧЕНИЕ УРОНА И СМЕРТЬ ---
func take_damage(amount: int, dir: float):
    if current_state == BossState.DEAD: return
    
    # ОСТАНАВЛИВАЕМ ВСЕ ДВИЖЕНИЯ ТВИНОВ (чтобы босс не "плыл" в центр во время удара)
    var tween = create_tween()
    tween.kill() 
    
    current_hp -= amount
    
    if current_hp > 0:
        current_state = BossState.HURT
        velocity.x = dir * knockback_force
        velocity.y = -100
        knockback_timer = knockback_time
    else:
        die()

func die():
    current_state = BossState.DEAD
    velocity = Vector2.ZERO
    state_timer.stop()
    # Анимация "Dead" запустится через handle_animations

func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "Dead":
        queue_free()
        
func _on_contact_damage_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and current_state != BossState.DEAD:
        var dir = sign(body.global_position.x - global_position.x)
        body.take_damage(contact_damage, dir)


func _on_hurt_box_area_entered(area: Area2D) -> void:
    if current_state == BossState.DEAD: return
    if area.name == "hitbox":
        var player = area.get_parent()
        var dir = sign(global_position.x - player.global_position.x)
        take_damage(player.damage, dir)
