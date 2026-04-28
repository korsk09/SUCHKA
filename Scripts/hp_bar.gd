extends CanvasLayer

@export var heart_scene : PackedScene
# Сюда можно перетащить спрайт ключа, чтобы он отображался в UI
@export var key_icon_texture : Texture2D 

var max_hp = 5
var current_hp = 5

func _ready() -> void:
    set_hp()
    
# --- Логика Ключей ---

func add_key_to_gui(texture: Texture2D = null):
    # Создаем новый TextureRect для иконки ключа
    var rect = TextureRect.new()
    
    # Если мы передали текстуру из ключа — используем её, 
    # иначе берем дефолтную key_icon_texture из инспектора
    if texture:
        rect.texture = texture
    else:
        rect.texture = key_icon_texture
        
    # Настройки размера, чтобы ключи не были огромными
    rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
    rect.custom_minimum_size = Vector2(40, 40) # Подбери нужный размер
    
    # Добавляем в новый контейнер
    $KeysContainer.add_child(rect)

# --- Твой существующий код HP ---

func set_hp():
    validate_hp()
    clean_current_representation()
    draw_hearts()
    
func clean_current_representation():
    # Очищаем только контейнер с сердечками!
    for child in $HBoxContainer.get_children():
        child.queue_free()
        
func draw_hearts():
    for x in current_hp:
        var heart_instance = heart_scene.instantiate()
        $HBoxContainer.add_child(heart_instance)
        
func validate_hp():
    current_hp = [current_hp, max_hp].min()
    
func heal():
    current_hp += 1
    AudioController.play_health_poition()
    set_hp()
    
func hit():
    current_hp -= 1
    set_hp()
    
func remove_key_from_gui(index: int):
    var container = get_node_or_null("KeysContainer")
    if container and container.get_child_count() > index:
        var key_icon = container.get_child(index)
        key_icon.queue_free() # Удаляем иконку из UI
