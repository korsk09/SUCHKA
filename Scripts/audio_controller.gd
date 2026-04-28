extends Node2D

@export var mute: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.
    
func play_music_tutorial() -> void:
    if not mute:
        $MusicTutorial.play()


func play_kick() -> void:
    if not mute:
        $Kick.play()

func play_text() -> void:
    if not mute:
        $Text.play()
        
func play_keys() -> void:
    if not mute:
        $Keys.play()
        
func play_jump() -> void:
    if not mute:
        $Jump.play()

func play_change() -> void:
    if not mute:
        $ChangeChar.play()

func play_crouch() -> void:
    if not mute:
        $Crouch.play()
        
func play_dead() -> void:
    if not mute:
        $Dead.play()
        
func play_door_open() -> void:
    if not mute:
        $DoorOpen.play()
        
func play_rock() -> void:
    if not mute:
        $Rock.play()

func play_zombie_attack() -> void:
    if not mute:
        $ZombieAttack.play()
        
func play_zombie_hit() -> void:
    if not mute:
        $ZombieHit.play()
        
func play_zombie_dead() -> void:
    if not mute:
        $ZombieDead.play()
        
func play_health_poition() -> void:
    if not mute:
        $HealthPoition.play()
        
func play_box_hit() -> void:
    if not mute:
        $BoxHit.play()
        
func play_box_broken() -> void:
    if not mute:
        $BoxBroken.play()
        
func play_button() -> void:
    if not mute:
        $Button.play()
        
