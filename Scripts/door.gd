extends StaticBody2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func open():
    # Отключаем коллизию, чтобы можно было пройти
    animation_player.play("open")

func close():
    # Включаем коллизию обратно
    animation_player.play("close")
