extends KinematicBody2D

onready var sprite = $rhino;

var speed = 300;
var velocity = Vector2(0,0);
var scent_array := [];

func _ready():
	$scent_timeout_timer.paused = true;
	$"../lang_test".set_locale("fr"); 

# warning-ignore:unused_argument
func _physics_process(delta):
	velocity = Vector2();
	sprite.play("idle");
	if Input.is_action_pressed("player_right"):
		sprite.flip_h = true;
		velocity += Vector2(1, 0);
		sprite.play("attack");
	elif Input.is_action_pressed("player_left"):
		sprite.flip_h = false;
		velocity += Vector2(-1, 0);
		sprite.play("attack");
	if Input.is_action_pressed("player_up"):
		velocity += Vector2(0, -1);
		sprite.play("attack");
	elif Input.is_action_pressed("player_down"):
		velocity += Vector2(0, 1);
		sprite.play("attack");
	#var ghost = preload("res://scenes/trail.tscn").instance();
	#$ghost_container.add_child(ghost);
	#ghost.global_position = sprite.global_position;
	#ghost.texture = sprite.frames.get_frame(sprite.animation, sprite.frame);
	#ghost.scale = Vector2(2.5, 2.5);
	#ghost.flip_h = sprite.flip_h;
# warning-ignore:return_value_discarded
	move_and_slide(velocity*speed);

func _on_AnimatedSprite_animation_finished():
	sprite.play("idle");

func _on_scent_timer_timeout():
	$scent_timeout_timer.paused = false;
	scent_array.append(global_position);

func _on_scent_timeout_timer_timeout():
	scent_array.remove(0);

func damage(amount):
	print(amount);
