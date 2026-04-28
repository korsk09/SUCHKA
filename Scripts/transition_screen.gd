extends CanvasLayer


# Внутри TransitionScreen.gd
func change_scene(target_scene_path: String):
    $AnimationPlayer.play("fade_out")
    await $AnimationPlayer.animation_finished # В Godot 4 используем await вместо yield
    
    get_tree().change_scene_to_file(target_scene_path) # Новый метод
    
    $AnimationPlayer.play_backwards("fade_out")
