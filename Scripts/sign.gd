extends Area2D

# Позволяет менять текст каждой таблички в инспекторе
@export_multiline var display_text: String = "Это стандартная подсказка."

@onready var label = $Label # Путь к твоему тексту
@onready var anim_player = $AnimationPlayer

func _ready():
    label.text = display_text
    label.modulate.a = 0 # Скрываем текст при старте

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        show_text()
    
func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        hide_text()
        
func show_text():
    var tween = create_tween()
    anim_player.play("appear")
    AudioController.play_text()
    # Плавное появление и небольшое всплытие вверх
    tween.parallel().tween_property(label, "modulate:a", 1.0, 0.3)
    tween.parallel().tween_property(label, "position:y", label.position.y - 20, 0.3).set_trans(Tween.TRANS_BACK)

func hide_text():
    var tween = create_tween()
    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.2)
    tween.parallel().tween_property(label, "position:y", label.position.y + 20, 0.2)
