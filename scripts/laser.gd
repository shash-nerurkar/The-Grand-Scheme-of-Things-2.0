extends Area2D

onready var sprite = $sprite;
onready var collision = $collision;

var bullet_type;
var target;

func init(angle, start_point, end_point, enemy_type):
	rotation = angle;#if not $"../../sprite".flip_h else -start_point.angle_to(end_point);
	global_position = (start_point + end_point) / 2;
	bullet_type = enemy_type;
	scale.x = start_point.distance_to(end_point) / (2*collision.shape.extents.x);
	sprite.play("start");
 
func end():
	collision.set_deferred("disabled", true);
	sprite.play("end");

func _on_sprite_animation_finished():
	if sprite.get_animation() == "start":
		sprite.play("sizzle"); 
	elif sprite.get_animation() == "end":
		queue_free(); 

func _on_laser_body_entered(body):
	if body.is_in_group("player"):
		body.damage(global.enemy_damage[bullet_type], (body.global_position - global_position).normalized()*1, 0.015, global.enemy_debuff_type[bullet_type], global.enemy_debuff_amount[bullet_type], global.enemy_debuff_duration[bullet_type]);
		target = body;
		$Timer.start();

func _on_laser_body_exited(body):
	if body.is_in_group("player"):
		target = null;

func _on_Timer_timeout():
	if target != null:
		$Timer.start();
		target.damage(global.enemy_damage[bullet_type], (target.global_position - global_position).normalized()*1, 0.015, global.enemy_debuff_type[bullet_type], global.enemy_debuff_amount[bullet_type], global.enemy_debuff_duration[bullet_type]);
