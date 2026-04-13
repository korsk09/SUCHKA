extends Area2D

@onready var door = $"../Door"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Счетчик объектов на кнопке (игрок или камень)
var bodies_on_button := 0

func _ready() -> void:
    pass

func _on_body_entered(body: Node2D) -> void:
    # Проверяем, игрок это или камень
    if body.is_in_group("player") or body.is_in_group("stone"):
        bodies_on_button += 1
        update_button_state()

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player") or body.is_in_group("stone"):
        bodies_on_button -= 1
        update_button_state()

func update_button_state():
    if bodies_on_button > 0:
        # Если на кнопке кто-то есть (хотя бы 1 объект)
        animation_player.play("push")
        if door.has_method("open"):
            door.open()
    else:
        # Если счетчик стал равен 0 (все ушли)
        # Проигрываем анимацию возврата кнопки в верхнее положение
        animation_player.play("push_away") 
        if door.has_method("close"):
            door.close()
