extends Area2D

@export var speed := 350.0
var direction := Vector2.ZERO # Направление полета, задается боссом при спавне

func _physics_process(delta: float):
    # Если направление задано, двигаем шар
    if direction != Vector2.ZERO:
        global_position += direction * speed * delta
    
    # Можно добавить небольшое вращение для красоты
    $Sprite2D.rotation += 10 * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        if body.has_method("take_damage"):
            # Наносим урон и передаем направление отброса
            body.take_damage(1, sign(direction.x))
        queue_free() # Удаляем шар после попадания
    elif body is StaticBody2D: 
        queue_free() # Удаляем при столкновении со стеной
