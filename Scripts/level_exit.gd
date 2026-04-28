extends Area2D

# Указываем путь к следующей сцене через инспектор
@export_file("*.tscn") var next_scene_path: String


func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        # 1. Отключаем обработку игрока (он перестанет реагировать на кнопки и двигаться)
        body.process_mode = Node.PROCESS_MODE_DISABLED
        
        # 2. (Опционально) Если есть анимация бега, принудительно ставим Idle
        if body.has_node("AnimationPlayer"):
            body.get_node("AnimationPlayer").play("idle")
            
        # 3. Запускаем переход
        TransitionScreen.change_scene(next_scene_path)
