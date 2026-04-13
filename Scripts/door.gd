extends StaticBody2D

func open():
    # Отключаем коллизию, чтобы можно было пройти
    $CollisionShape2D.set_deferred("disabled", true)
    # Скрываем дверь (или запускаем анимацию открытия)
    visible = false

func close():
    # Включаем коллизию обратно
    $CollisionShape2D.set_deferred("disabled", false)
    # Показываем дверь
    visible = true
