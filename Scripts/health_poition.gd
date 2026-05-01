extends RigidBody2D

@export var heal_amount: int = 1

func _on_area_2d_body_entered(body: Node2D) -> void:
    # Проверяем, есть ли у объекта (игрока) функция heal 
    if body.has_method("heal"): 
        body.heal() # Вызываем лечение 
        queue_free() # Удаляем зелье с карты
