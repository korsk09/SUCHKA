extends Area2D

# Позволяет менять текст каждой таблички в инспекторе
@export_multiline var display_text: String = "Это стандартная подсказка."

@onready var label = $Label # Путь к твоему тексту
@onready var anim_player = $AnimationPlayer
var start_pos_y: float

func _ready():
    label.text = display_text
    label.modulate.a = 0
    start_pos_y = label.position.y

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

    tween.parallel().tween_property(label, "modulate:a", 1.0, 0.3)
    tween.parallel().tween_property(label, "position:y", start_pos_y - 20, 0.3).set_trans(Tween.TRANS_BACK)

func hide_text():
    var tween = create_tween()

    tween.parallel().tween_property(label, "modulate:a", 0.0, 0.2)
    tween.parallel().tween_property(label, "position:y", start_pos_y, 0.2)
