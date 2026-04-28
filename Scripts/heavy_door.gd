extends StaticBody2D

@export var required_key: String = "blue_key"
var is_player_nearby = false
var current_body_in_zone: Node2D = null # Храним того, кто зашел

func _input(event):
    # Используем Input вместо event, чтобы избежать старой ошибки
    if current_body_in_zone and Input.is_action_just_pressed("interact"):
        try_open(current_body_in_zone)

func try_open(body):
    if body.has_method("has_key") and body.has_key(required_key):
        # Сначала забираем ключ у игрока
        if body.has_method("remove_key"):
            body.remove_key(required_key)
            
        open_door() # Затем открываем дверь
    else:
        print("Ключа нет!")

func open_door():
    # Здесь можно запустить анимацию или просто удалить дверь
    AudioController.play_door_open()
    $AnimationPlayer.play("open") 
        
func _on_interaction_area_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        current_body_in_zone = body # Запоминаем этого конкретного игрока

func _on_interaction_area_body_exited(body: Node2D) -> void:
    if body == current_body_in_zone:
        current_body_in_zone = null # Очищаем, когда он ушел
