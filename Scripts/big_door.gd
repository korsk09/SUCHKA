extends StaticBody2D

# Список всех ключей, которые нужны для открытия
@export var required_keys: Array[String] = ["key_1", "key_2", "key_3"]

var current_body_in_zone: Node2D = null

func _input(_event):
    if current_body_in_zone and Input.is_action_just_pressed("interact"):
        try_open(current_body_in_zone)

func try_open(body):
    if not body.has_method("has_key") or not body.has_method("remove_key"):
        return

    # 1. Проверяем, есть ли у игрока ВСЕ нужные ключи
    var has_all = true
    for key_id in required_keys:
        if not body.has_key(key_id):
            has_all = false
            break
    
    # 2. Если все ключи на месте
    if has_all:
        # Удаляем каждый ключ из инвентаря игрока
        for key_id in required_keys:
            body.remove_key(key_id)
        
        open_door()
    else:
        print("Тебе не хватает ключей для этой двери!")
        # Здесь можно добавить звук "отказа" или анимацию покачивания

func open_door():
    AudioController.play_door_open()
    if has_node("AnimationPlayer"):
        $AnimationPlayer.play("open")
    else:
        # Если анимации нет, просто удаляем коллизию или саму дверь
        queue_free()

func _on_interaction_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        current_body_in_zone = body


func _on_interaction_area_body_exited(body: Node2D) -> void:
    if body == current_body_in_zone:
        current_body_in_zone = null
