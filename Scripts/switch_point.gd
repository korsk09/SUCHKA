extends Area2D

var current = 1
var is_player_in_swap_zone = false

@onready var player_a = $"../Player"
@onready var player_b = $"../PlayerB"

func _ready():
    activate_a()

func _input(event):
    if event.is_action_pressed("switch_character") and is_player_in_swap_zone:
        if current == 1:
            activate_b()
        else:
            activate_a()

func activate_a():
    player_b.visible = false
    player_b.process_mode = Node.PROCESS_MODE_DISABLED
    player_b.get_node("hpBarTwo").visible = false
    

    player_a.visible = true
    player_a.process_mode = Node.PROCESS_MODE_INHERIT
    player_a.get_node("hpBar").visible = true
    player_a.get_node("Camera2D").make_current()

    player_a.global_position = player_b.global_position
    current = 1

func activate_b():
    player_a.visible = false
    player_a.process_mode = Node.PROCESS_MODE_DISABLED
    player_a.get_node("hpBar").visible = false

    player_b.visible = true
    player_b.process_mode = Node.PROCESS_MODE_INHERIT
    player_b.get_node("hpBarTwo").visible = true
    player_b.get_node("Camera2D").make_current()

    player_b.global_position = player_a.global_position
    current = 2

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        is_player_in_swap_zone = true

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        is_player_in_swap_zone = false
