extends CharacterBody2D

# 1. Добавляем ссылку на сцену зелья
@export var potion_scene : PackedScene 
# 2. Шанс выпадения (от 0.0 до 1.0, где 0.3 это 30%)
@export_range(0, 1) var drop_chance : float = 0.3

var hp = 3
var active = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    $AnimationPlayer.play("idle")
    await get_tree().create_timer(0.2).timeout
    active = true

func _physics_process(delta: float) -> void:
    apply_gravity(delta)
    move_and_slide()

func apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        velocity.y = 0

func _on_hurt_box_area_entered(area: Area2D) -> void:
    if not active: return
    if area.name == "hitbox":
        take_damage()
        
func take_damage():
    hp -= 1
    if hp == 2:
        $AnimationPlayer.play("damage_1")
    elif hp == 1:
        $AnimationPlayer.play("damage_2")
    elif hp <= 0:
        die() # Вынесли логику смерти в отдельную функцию

func die():
    active = false # Чтобы нельзя было ударить в процессе анимации смерти
    $AnimationPlayer.play("death")
    
    # Пытаемся выкинуть лут
    spawn_loot()
    
    await $AnimationPlayer.animation_finished
    queue_free()

func spawn_loot():
    # Генерируем случайное число от 0.0 до 1.0
    var roll = randf()
    
    # Если выпавшее число меньше или равно нашему шансу — создаем зелье
    if roll <= drop_chance:
        if potion_scene: # Проверяем, не забыли ли мы перетащить сцену в инспектор
            var potion = potion_scene.instantiate()
            # Добавляем зелье в корень уровня, чтобы оно не удалилось вместе с коробкой
            get_tree().current_scene.add_child(potion)
            # Ставим зелье на место коробки
            potion.global_position = global_position
            
            # (Опционально) Если у зелья есть физика, можно подкинуть его немного вверх
            if potion is CharacterBody2D:
                potion.velocity = Vector2(randf_range(-50, 50), -150)
