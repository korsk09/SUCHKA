extends CharacterBody2D

@export var walk_speed := 200.0
@export var run_speed := 350.0
@export var acceleration := 1000.0

@export var jump_velocity := -200.0
@export var jump_hold_gravity := 400.0
@export var fall_gravity := 800.0
@export var jump_amount := 2
var jumps_left := jump_amount

@export var slide_speed := 450.0  # Скорость подката
@export var slide_duration := 0.5 # Длительность подката в секундах
var slide_timer := 0.0            # Текущее время подката

var can_control := true
var is_invulnerable := false
var is_crouching := false
var is_down_attacking := false

@export var damage := 1

var carried_stone: RigidBody2D = null # Ссылка на поднятый камень
var is_carrying: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hurt_timer: Timer = $hurtTimer
@onready var stand_collision: CollisionShape2D = $StandCollision
@onready var crouch_collision: CollisionShape2D = $CrouchCollision

var keys = [] # Список ID имеющихся ключей

# Сигнал для обновления интерфейса
signal key_collected(texture)

# Состояния 
enum State { IDLE, WALK, RUN, JUMP, FALL, ATTACK, HURT, DEAD, SLIDE, DOWN_ATTACK }
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

func _ready():
    animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
  apply_gravity(delta)
  if current_state == State.DEAD:
        return
        
  if current_state == State.SLIDE:
        slide_timer -= delta
        
        # Замедляем подкат, чтобы он не был бесконечным
        velocity.x = move_toward(velocity.x, 0, acceleration * delta * 0.5)
        
        # Если время вышло ИЛИ мы почти остановились
        if slide_timer <= 0 or abs(velocity.x) < 50:
            if can_stand(): 
                # ВОЗВРАЩАЕМСЯ В НОРМУ
                current_state = State.IDLE
                is_crouching = false
                stand_collision.disabled = false # Включаем большую коллизию
                crouch_collision.disabled = true # Выключаем маленькую
            else:
                slide_timer = 0.1 

  if can_control:
        handle_input(delta)
    
  update_state()
  handle_state(delta)   
  move_and_slide()

# сброс прыжков при касании пола
  if is_on_floor():
    jumps_left = jump_amount

# Управление вводом 
func handle_input(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    var target_speed := 0.0

    # --- ИЗМЕНЕНИЕ СКОРОСТИ ---
    if Input.is_action_pressed("move_run"):
        target_speed = run_speed
    else:
        target_speed = walk_speed

    # Обычный расчет движения по X
    velocity.x = move_toward(
        velocity.x,
        direction * target_speed,
        acceleration * delta
    )

    # --- ПОВОРОТ СПРАЙТА И ТОЧКИ ПЕРЕНОСА ---
    if direction > 0:
        sprite_2d.flip_h = false
        $hitbox.scale.x = 1
        # Если точка переноса смещена, можно её тут тоже зеркалить
    elif direction < 0:
        sprite_2d.flip_h = true
        $hitbox.scale.x = -1

    # --- ПРЫЖОК (запрещаем, если несем камень) ---
    if Input.is_action_just_pressed("jump"):
        if jumps_left > 0:
            velocity.y = jump_velocity
            current_state = State.JUMP
            jumps_left -= 1

    if Input.is_action_just_pressed("attack") and current_state != State.ATTACK:
        # Атака вниз: в воздухе + зажат "вниз"
        if not is_on_floor() and Input.is_action_pressed("move_down"):
            current_state = State.DOWN_ATTACK
            is_down_attacking = true
            var dir = -1 if sprite_2d.flip_h else 1
            velocity.y = 600.0
            velocity.x = dir * 450.0  # наискосок при атаке
        else:
            current_state = State.ATTACK
        
    # Логика ПОДКАТА
    if Input.is_action_just_pressed("crouch") and is_on_floor() and current_state != State.SLIDE:
        start_slide()

# Гравитация 
func apply_gravity(delta: float) -> void:
  if current_state == State.DOWN_ATTACK:
    # Своя фиксированная скорость падения уже задана, гравитация не нужна
    return
    
  if velocity.y < 0:
    if Input.is_action_pressed("jump"):
      velocity.y += jump_hold_gravity * delta
    else:
      velocity.y += fall_gravity * delta
  else:
    velocity.y += fall_gravity * delta
    
func can_stand() -> bool:
    return not test_move(transform, Vector2(0, -10))

# Определение состояния 
func update_state() -> void: 
  # 1. Самый высокий приоритет: Смерть и Урон
  if current_state == State.DEAD or current_state == State.HURT:
    return

    # 2. Атака должна иметь приоритет над движением!
    # Если мы уже атакуем, не прерываем анимацию.
  if current_state == State.ATTACK:
    return

    # 3. Блокировка для подката
  if current_state == State.SLIDE:
    return
    
  if current_state == State.DOWN_ATTACK:
    return

  if not is_on_floor():
        current_state = State.JUMP if velocity.y < 0 else State.FALL
  else:
        if abs(velocity.x) < 0.1:
            current_state = State.IDLE
        elif abs(velocity.x) >= run_speed * 0.8:
            current_state = State.RUN
        else:
            current_state = State.WALK
        
# Логика состояний 
func handle_state(delta: float) -> void:
  if current_state == previous_state:
    return
    
  # ЕСЛИ МЫ УХОДИМ ИЗ АТАКИ В ЛЮБОЕ ДРУГОЕ СОСТОЯНИЕ
  if previous_state == State.ATTACK:
    $hitbox/CollisionShape2D.disabled = true # Или как там у тебя путь до коллизии
    
  # ЕСЛИ МЫ УХОДИМ ИЗ АТАКИ В ЛЮБОЕ ДРУГОЕ СОСТОЯНИЕ
  if previous_state == State.DOWN_ATTACK:
    $hitbox/CollisionShape2D2.disabled = true # Или как там у тебя путь до коллизии

  previous_state = current_state

  match current_state:
    State.IDLE:
      animation_player.play("Idle")
    State.WALK:
      animation_player.play("Walk")
    State.RUN:
      animation_player.play("Run")
    State.JUMP:
      AudioController.play_jump()
      animation_player.play("Jump")
    State.FALL:
      animation_player.play("Fall")
    State.ATTACK:
      animation_player.play("Attack")
    State.HURT:
      AudioController.play_kick()
      animation_player.play("Hurt")
    State.DEAD:
      AudioController.play_dead()
      animation_player.play("Dead")
    State.SLIDE:
      AudioController.play_crouch()
      animation_player.play("Crouch")
    State.DOWN_ATTACK:
      animation_player.play("DownAttack") 
    
func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "Hurt":
      current_state = State.IDLE
    
    if anim_name == "Attack":
        # после атаки возвращаемся в нормальный цикл
        current_state = State.IDLE
        
    if anim_name == "Dead":
        queue_free()
        
    if anim_name == "DownAttack":
        is_down_attacking = false
        current_state = State.FALL
        
func heal():
    # Мы обращаемся к узлу hpBar и вызываем его метод heal()
    # Убедись, что имя узла в дереве в точности совпадает с "hpBar"
    if has_node("hpBar"):
        $hpBar.heal()
        
func take_damage(amount: int, knockback_direction: float):
    if current_state == State.DEAD or is_invulnerable:
        return
        
    $hitbox/CollisionShape2D.set_deferred("disabled", true)
    $hitbox/CollisionShape2D2.set_deferred("disabled", true)
        
    $hpBar.hit()
    can_control = false
    is_invulnerable = true
    
    current_state = State.HURT
    
    # Отбрасывание
    velocity.x = knockback_direction * 200
    velocity.y = -150
    
    if $hpBar.current_hp <= 0:
        die()
        return
    
    hurt_timer.start()

func _on_hurt_timer_timeout() -> void:
    can_control = true
    is_invulnerable = false

func die():
    current_state = State.DEAD
    is_invulnerable = true
    can_control = false

    velocity = Vector2.ZERO
    animation_player.play("Dead")
    
# Новая функция для начала подката
func start_slide():
    current_state = State.SLIDE
    slide_timer = slide_duration
    
    # Направление подката зависит от того, куда смотрит спрайт
    var direction = -1 if sprite_2d.flip_h else 1
    velocity.x = direction * slide_speed
    
    # Переключаем коллизии (приседаем)
    stand_collision.disabled = true
    crouch_collision.disabled = false
    
func collect_key(id, texture):
    keys.append(id)
    # Вызываем функцию отрисовки ключа в UI
    AudioController.play_keys()
    if has_node("hpBar"):
        $hpBar.add_key_to_gui(texture)

func has_key(id) -> bool:
    return id in keys

func remove_key(id):
    var index = keys.find(id) # Ищем, где в списке лежит этот ключ
    if index != -1:
        keys.remove_at(index) # Удаляем его из памяти
        print("Ключ использован и удален: ", id)
        
        # Если хочешь, чтобы иконка тоже исчезла из UI:
        if has_node("hpBar"):
            $hpBar.remove_key_from_gui(index)
            
func bounce_up():
    var dir = 1 if sprite_2d.flip_h else -1
    velocity.y = jump_velocity * 1.5
    velocity.x = dir * 350.0  # горизонтальная сила отскока, подбери под себя
    is_down_attacking = false
    is_invulnerable = true  # включаем неуязвимость
    hurt_timer.start()      # hurt_timer уже выключает её по таймауту
    current_state = State.JUMP
