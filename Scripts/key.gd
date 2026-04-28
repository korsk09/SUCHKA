extends Area2D

@export var key_id: String = "blue_key" # Уникальный ID ключа

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"): # Проверяем, что это игрок
        if body.has_method("collect_key"):
            body.collect_key(key_id, $Sprite2D.texture) # Передаем ID и картинку
            queue_free() # Удаляем ключ со сцены
