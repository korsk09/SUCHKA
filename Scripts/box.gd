extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


func _on_hurt_box_area_entered(area: Area2D) -> void:
    if area.name == "hitbox":
         $AnimationPlayer.play("take_damage")
         await $AnimationPlayer.animation_finished
         queue_free()
