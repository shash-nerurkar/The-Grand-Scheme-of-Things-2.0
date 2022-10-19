extends Area2D

onready var bullet = get_node("AnimatedSprite");

var damage;
var vel = Vector2();
export var speed = 1000;

func start_pos(dir, pos):
	set_rotation(dir);
	set_position(pos);
	vel = Vector2(speed, 0).rotated(dir);

func _physics_process(delta):
	position += vel*delta;
	if not weakref(bullet).get_ref():
		queue_free();

func _on_player_bullet_body_entered(body):
	if body.is_in_group("wall"):
		bullet.playing = true;
		vel = Vector2(0, 0);

func _on_player_bullet_area_entered(area):
	if area.get_parent().is_in_group("enemies"):
		bullet.playing = true;
		area.get_parent().damage(damage, "KNOCKBACK", vel.normalized(), 0.02);
		vel = Vector2(0, 0);

func _on_AnimatedSprite_animation_finished():
	queue_free();
