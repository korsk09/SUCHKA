extends CharacterBody2D

@export var walk_speed := 200.0
@export var run_speed := 300.0
@export var acceleration := 1000.0

@export var jump_velocity := -200.0
@export var jump_hold_gravity := 400.0
@export var fall_gravity := 800.0
@export var jump_amount := 1
var jumps_left := jump_amount

@export var wall_jump_force := 250.0
@export var wall_jump_vertical_force := -200.0
@export var wall_slide_speed := 35.0

var is_wall_sliding := false
var wall_direction := 0

var can_control := true
var is_invulnerable := false

@export var damage := 1

var carried_stone: RigidBody2D = null # Ссылка на поднятый камень
var is_carrying: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hurt_timer: Timer = $hurtTimer
@onready var carry_point = $CarryPoint
@onready var pickup_zone = $PickupZone

var keys = [] # Список ID имеющихся ключей

# Сигнал для обновления интерфейса
signal key_collected(texture)

# Состояния 
enum State { IDLE, WALK, RUN, JUMP, FALL, ATTACK, HURT, DEAD, WALL_SLIDE }
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

func _ready():
    animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
  apply_gravity(delta)
  if current_state == State.DEAD:
        return
        
  if can_control:
        handle_input(delta)
    
  update_state()
  handle_state(delta)   
  move_and_slide()
  handle_wall_slide()

# сброс прыжков при касании пола
  if is_on_floor():
    jumps_left = jump_amount

# Управление вводом 
func handle_input(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    var target_speed := 0.0

    # --- ИЗМЕНЕНИЕ СКОРОСТИ ---
    if is_carrying:
        target_speed = walk_speed * 0.5  # Если несем, скорость режется пополам
    else:
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
        $hitbox.scale.x = -1.3

    # --- ПРЫЖОК (запрещаем, если несем камень) ---
    if Input.is_action_just_pressed("jump") and not is_carrying:
        if is_wall_sliding:
            velocity.x = wall_direction * wall_jump_force
            velocity.y = wall_jump_vertical_force
            is_wall_sliding = false
            return

        if jumps_left > 0:
            velocity.y = jump_velocity
            current_state = State.JUMP
            jumps_left -= 1

    # --- КНОПКА ПОДНЯТИЯ (наша новая логика) ---
    if Input.is_action_just_pressed("interact"):
        if is_carrying:
            drop_stone()
        else:
            pick_up_stone()

    if Input.is_action_just_pressed("attack") and current_state != State.ATTACK:
        current_state = State.ATTACK

# Гравитация 
func apply_gravity(delta: float) -> void:
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

  # приоритет стены
  if is_wall_sliding:
      current_state = State.WALL_SLIDE
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
    $hitbox/CollisionShape2D.disabled = true

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
    State.WALL_SLIDE:
      animation_player.play("WallSlide")
    State.ATTACK:
      animation_player.play("Attack")
    State.HURT:
      AudioController.play_kick()
      animation_player.play("Hurt")
    State.DEAD:
      AudioController.play_dead()
      animation_player.play("Dead")
    
func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "Hurt":
      current_state = State.IDLE
    
    if anim_name == "Attack":
        # после атаки возвращаемся в нормальный цикл
        current_state = State.IDLE
        
    if anim_name == "Dead":
        queue_free()
        
func heal():
    # Мы обращаемся к узлу hpBar и вызываем его метод heal()
    # Убедись, что имя узла в дереве в точности совпадает с "hpBar"
    if has_node("hpBarTwo"):
        $hpBarTwo.heal()
        
func take_damage(amount: int, knockback_direction: float):
    if current_state == State.DEAD or is_invulnerable:
        return
        
    # ПРИНУДИТЕЛЬНО ВЫКЛЮЧАЕМ ХИТБОКС ПРИ ПОЛУЧЕНИИ УРОНА
    $hitbox/CollisionShape2D.set_deferred("disabled", true)
        
    $hpBarTwo.hit()
    can_control = false
    is_invulnerable = true
    
    current_state = State.HURT
    
    # Отбрасывание
    velocity.x = knockback_direction * 200
    velocity.y = -150
    
    if $hpBarTwo.current_hp <= 0:
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
    
func handle_wall_slide():
    if is_on_wall() and not is_on_floor() and velocity.y > 0:
        
        var normal = get_wall_normal()
        # normal.x = -1 если стена справа
        # normal.x = 1 если стена слева
        
        # Проверяем нажата ли кнопка В СТОРОНУ СТЕНЫ
        if (normal.x < 0 and Input.is_action_pressed("move_right")) \
        or (normal.x > 0 and Input.is_action_pressed("move_left")):
            if is_wall_sliding:
                sprite_2d.flip_h = wall_direction < 0
            is_wall_sliding = true
            wall_direction = normal.x
            velocity.y = min(velocity.y, wall_slide_speed)
        else:
            is_wall_sliding = false
            wall_direction = 0
    else:
        is_wall_sliding = false
        wall_direction = 0

func pick_up_stone():
    var bodies = $PickupZone.get_overlapping_bodies()
    for body in bodies:
        if body is RigidBody2D and body.is_in_group("stone"):
            carried_stone = body
            is_carrying = true
            
            # 1. Замораживаем физику
            carried_stone.freeze = true 
            
            # 2. Отключаем коллизию, чтобы камень не толкал игрока изнутри
            # Используем set_deferred, так как менять физику во время столкновения нельзя
            carried_stone.get_node("CollisionShape2D").set_deferred("disabled", true)
            
            # 3. Привязываем к игроку. 
            # Аргумент 'false' означает: "НЕ сохраняй старые координаты, 
            # я сейчас сам их назначу".
            carried_stone.reparent(self, false)
            
            # 4. Ставим ровно в точку CarryPoint
            carried_stone.position = $CarryPoint.position
            
            # На всякий случай выводим в топ по слоям отрисовки
            carried_stone.top_level = false # Убеждаемся, что он не живет своей жизнью
            carried_stone.z_index = 10      # Рисуем поверх игрока
            AudioController.play_rock()
            return

func drop_stone():
    if not carried_stone: return

    var direction = -1 if sprite_2d.flip_h else 1
    
    # 1. Сначала считаем смещение (куда хотим положить)
    var drop_offset = Vector2(direction * 40, -10) 
    
    # 2. Считаем итоговую глобальную позицию
    # Именно этой переменной не хватало в твоём коде
    var spawn_pos = global_position + drop_offset

    var shapecast = $ShapeCast2D
    shapecast.clear_exceptions()
    shapecast.add_exception(self)
    shapecast.add_exception(carried_stone)
    
    # Настраиваем проверку
    shapecast.target_position = drop_offset
    shapecast.force_shapecast_update()

    # 3. Если путь прегражден стеной или дверью — выходим
    if shapecast.is_colliding():
        print("Не могу поставить: мешает ", shapecast.get_collider(0).name)
        return

    # 4. Если чисто — переносим камень из "рук" на уровень
    carried_stone.reparent(get_parent())
    carried_stone.global_position = spawn_pos
        
    # 5. Включаем физику
    carried_stone.freeze = false
    carried_stone.get_node("CollisionShape2D").set_deferred("disabled", false)
        
    # 6. Импульс
    await get_tree().physics_frame
    if carried_stone: # Проверка на случай, если камень удалили за этот кадр
        carried_stone.apply_central_impulse(Vector2(direction * 120, -80))
        
    # Очищаем переменные
    carried_stone = null
    is_carrying = false
        
        
func collect_key(id, texture):
    keys.append(id)
    AudioController.play_keys()
    # Вызываем функцию отрисовки ключа в UI
    if has_node("hpBarTwo"):
        $hpBarTwo.add_key_to_gui(texture)

func has_key(id) -> bool:
    return id in keys
        
func remove_key(id):
    var index = keys.find(id) # Ищем, где в списке лежит этот ключ
    if index != -1:
        keys.remove_at(index) # Удаляем его из памяти
        print("Ключ использован и удален: ", id)
        
        # Если хочешь, чтобы иконка тоже исчезла из UI:
        if has_node("hpBarTwo"):
            $hpBarTwo.remove_key_from_gui(index)
