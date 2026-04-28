extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var current_speed := 0
@export var patrol_speed := 50
@export var chase_speed := 70
@export var max_hp := 5
var current_hp := 5
@export var contact_damage := 1
@export var knockback_force := 200.0
@export var knockback_time := 0.2

var knockback_timer := 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var left_point = $LeftPoint.global_position.x
@onready var right_point = $RightPoint.global_position.x

enum State { PATROL, CHASE, HURT, DEAD, ATTACK }
var current_state: State = State.PATROL
var previous_state: State = State.PATROL

var patrol_dir := 1

@export var jump_force_x := 200.0   # Сила прыжка вперед
@export var jump_force_y := -200.0  # Сила прыжка вверх
@export var attack_cooldown := 2.0  # Пауза между прыжками

var can_attack := true              # Флаг готовности к атаке

func _ready() -> void:
    current_hp = max_hp
    animation_player.animation_finished.connect(_on_animation_finished)
    previous_state = -1 


func _physics_process(delta: float) -> void:
    apply_gravity(delta)
    update_state()
    handle_state(delta)
    
    move_and_slide()

# ГРАВИТАЦИЯ
func apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta


# ОБНОВЛЕНИЕ СОСТОЯНИЯ
func update_state() -> void:
    # Если враг атакован, мертв или в процессе атаки — не меняем состояние сами
    if current_state in [State.HURT, State.DEAD, State.ATTACK]:
        return

    var target = get_target_player()
    if target == null:
        current_state = State.PATROL
        return

    var distance_to_player = global_position.distance_to(target.global_position)

    if distance_to_player < 100:
        current_state = State.CHASE
    else:
        current_state = State.PATROL

# ЛОГИКА СОСТОЯНИЙ
func handle_state(delta: float) -> void:
    
    if current_state != previous_state:
        previous_state = current_state
        
        match current_state:
            State.PATROL:
                animation_player.play("run")
            State.CHASE:
                animation_player.play("run")
            State.HURT:
                animation_player.play("hurt")
            State.DEAD:
                animation_player.play("dead")
            State.ATTACK:
                animation_player.play("attack")


    match current_state:
        State.PATROL:
            patrol_behavior()
        State.CHASE:
            chase_behavior()
        State.HURT:
            knockback_timer -= delta
    
            if knockback_timer <= 0:
                velocity.x = 0
        State.DEAD:
            velocity = Vector2.ZERO


# ПАТРУЛЬ
func patrol_behavior():
    current_speed = patrol_speed
    velocity.x = patrol_dir * current_speed
    sprite_2d.flip_h = patrol_dir > 0

    if global_position.x <= left_point:
        patrol_dir = 1
    elif global_position.x >= right_point:
        patrol_dir = -1


# ПРЕСЛЕДОВАНИЕ
func chase_behavior():
    var target = get_target_player()
    if target == null or current_state == State.HURT:
        return

    var direction = (target.global_position - global_position).normalized()
    var distance = global_position.distance_to(target.global_position)

    # Поворачиваем спрайт в сторону игрока
    sprite_2d.flip_h = direction.x > 0

    # Если враг на земле, готов атаковать и игрок в радиусе прыжка (например, 150 пикселей)
    if is_on_floor() and can_attack and distance < 150:
        attack_jump(direction.x)
    else:
        # Если не прыгаем, то просто идем в сторону игрока
        if is_on_floor():
            velocity.x = direction.x * chase_speed

func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "hurt" or anim_name == "attack": # Добавили attack сюда
        current_state = State.CHASE # После атаки сразу проверяем игрока
    elif anim_name == "dead":
        queue_free()

func take_damage(amount: int, dir: float):
    current_hp -= amount
    
    if current_hp > 0:
        current_state = State.HURT
        velocity.x = dir * knockback_force
        velocity.y = -100
        knockback_timer = knockback_time
    else:
        current_state = State.DEAD
        
func _on_contact_damage_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        var dir = sign(body.global_position.x - global_position.x)
        body.take_damage(contact_damage, dir)

        
func get_target_player() -> Node2D:
    var players = get_tree().get_nodes_in_group("player")
    var closest: Node2D = null
    var min_dist = INF

    for p in players:
        var dist = global_position.distance_to(p.global_position)
        if dist < min_dist:
            min_dist = dist
            closest = p

    return closest

func _on_hurt_box_area_entered(area: Area2D) -> void:
    if current_state == State.DEAD:
        return
        
    if area.name == "hitbox":
        var player = area.get_parent()
        var dir = sign(global_position.x - player.global_position.x)
        take_damage(player.damage, dir)

func attack_jump(dir_x: float):
    can_attack = false
    current_state = State.ATTACK # Включаем состояние атаки (включается анимация)
    
    # Останавливаем врага на мгновение перед прыжком для эффекта подготовки
    velocity.x = 0
    
    # --- ПАУЗА 0.2 СЕКУНДЫ ---
    await get_tree().create_timer(0.2).timeout
    
    # ПРЫЖОК (после паузы прикладываем силу)
    velocity.x = sign(dir_x) * jump_force_x
    velocity.y = jump_force_y
    
    # Ждем кулдаун (перезарядку) перед следующей возможностью атаковать
    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true
