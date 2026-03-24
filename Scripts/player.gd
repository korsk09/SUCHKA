extends CharacterBody2D

@export var walk_speed := 200.0
@export var run_speed := 450.0
@export var acceleration := 1000.0

@export var jump_velocity := -200.0
@export var jump_hold_gravity := 400.0
@export var fall_gravity := 800.0
@export var jump_amount := 2
var jumps_left := jump_amount

@export var wall_jump_force := 250.0
@export var wall_jump_vertical_force := -200.0
@export var wall_slide_speed := 35.0

var is_wall_sliding := false
var wall_direction := 0

var can_control := true
var is_invulnerable := false

var is_crouching := false

@export var damage := 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hurt_timer: Timer = $hurtTimer
@onready var stand_collision: CollisionShape2D = $StandCollision
@onready var crouch_collision: CollisionShape2D = $CrouchCollision

# Состояния 
enum State { IDLE, WALK, RUN, JUMP, FALL, ATTACK, HURT, DEAD, WALL_SLIDE, CROUCH, CROUCH_WALK }
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

  if is_crouching:
    target_speed = walk_speed * 0.4
  else:
    if Input.is_action_pressed("move_run"):
        target_speed = run_speed
    else:
        target_speed = walk_speed

  velocity.x = move_toward(
    velocity.x,
    direction * target_speed,
    acceleration * delta
  )

  # направление спрайта
  if direction > 0:
    sprite_2d.flip_h = false
    $hitbox.scale.x = 1
  elif direction < 0:
    sprite_2d.flip_h = true
    $hitbox.scale.x = -1.3
    
  # присед
  if Input.is_action_pressed("crouch"):
    is_crouching = true
  else:
    if can_stand():
      is_crouching = false

  stand_collision.disabled = is_crouching
  crouch_collision.disabled = not is_crouching
  # прыжок
  if Input.is_action_just_pressed("jump") and not is_crouching:

    # Прыжок от стены
    if is_wall_sliding:
      velocity.x = wall_direction * wall_jump_force
      velocity.y = wall_jump_vertical_force
    
      is_wall_sliding = false
      return

    # Обычный прыжок
    if jumps_left > 0:
        velocity.y = jump_velocity
        current_state = State.JUMP
        jumps_left -= 1
    
    
  if Input.is_action_just_pressed("attack"):
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
  if is_crouching and is_on_floor():
    var direction := Input.get_axis("move_left", "move_right")
    
    if abs(direction) > 0.1:
        current_state = State.CROUCH_WALK
    else:
        current_state = State.CROUCH
    return
  if current_state == State.ATTACK or current_state == State.HURT or current_state == State.DEAD:
    return 

  # приоритет стены
  if is_wall_sliding:
      current_state = State.WALL_SLIDE
      return

  if not is_on_floor():
    if velocity.y < 0:
      current_state = State.JUMP
    else:
      current_state = State.FALL
  else:
    if velocity.x == 0:
      current_state = State.IDLE
    else:
      if abs(velocity.x) >= run_speed * 0.8:
        current_state = State.RUN
      else:
        current_state = State.WALK
        
# Логика состояний 
func handle_state(delta: float) -> void:
  if current_state == previous_state:
    return

  previous_state = current_state

  match current_state:
    State.IDLE:
      animation_player.play("Idle")
    State.WALK:
      animation_player.play("Walk")
    State.RUN:
      animation_player.play("Run")
    State.JUMP:
      animation_player.play("Jump")
    State.FALL:
      animation_player.play("Fall")
    State.WALL_SLIDE:
      animation_player.play("WallSlide")
    State.ATTACK:
      animation_player.play("Attack")
    State.HURT:
      animation_player.play("Hurt")
    State.DEAD:
      animation_player.play("Dead")
    State.CROUCH:
      animation_player.play("Crouch")
    State.CROUCH_WALK:
      animation_player.play("CrouchWalk")
    
func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "Hurt":
      current_state = State.IDLE
    
    if anim_name == "Attack":
        # после атаки возвращаемся в нормальный цикл
        current_state = State.IDLE
        
    if anim_name == "Dead":
        queue_free()
        
func take_damage(amount: int, knockback_direction: float):
    if current_state == State.DEAD or is_invulnerable:
        return
        
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
    
func handle_wall_slide():
    if is_on_wall() and not is_on_floor() and velocity.y > 0 and not is_crouching:
        
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
