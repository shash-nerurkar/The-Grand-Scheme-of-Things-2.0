extends Area2D

onready var ability_nodes_container = $"..";
onready var player = $"../..";

var offset_mid := Vector2();
var src_pos;
var dest_pos := Vector2();
var explodable := true;
var compensator := 0;
var debris_texture;

func _ready():
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	global_rotation += .1;
	global_position = Bezier(1-(compensator*$erp_timer.get_time_left()));

func initiate(s, d):
	var wait_time =.32;
	wait_time -= ( 550 - (s.distance_to(d) if s.distance_to(d)<=550 else 550) )/2000;
	compensator = 1/wait_time;
	explodable = true;
	src_pos = s;
	dest_pos = d;
	offset_mid.x = (src_pos.x + dest_pos.x)/2;
	offset_mid.y = min(src_pos.y, dest_pos.y) - 120;
	$erp_timer.start(wait_time);
	set_physics_process(true);

func Bezier(t:float):
	var p1 = src_pos.linear_interpolate(offset_mid,t);
	var p2 = offset_mid.linear_interpolate(dest_pos,t);
	var pos =  p1.linear_interpolate(p2,t);
	return pos;

func _on_erp_timer_timeout():
	if explodable:
		explodable = false;
		set_physics_process(false);
		var dmg = 10 if $rock_shield.get_animation()=="shield_fly" else 6;
		$rock_shield.play("explosion");
		var debris = Sprite.new();
		debris.set_texture(debris_texture);
		debris.global_position = global_position + Vector2(-1.3,1.3);
		debris.global_rotation = global_rotation;
		ability_nodes_container.add_child(debris);
		if player.pixelstan.current_room != null:
			for enemy in get_tree().get_nodes_in_group(String(player.pixelstan.current_room.get_instance_id()) + "enemy"):
				var dis = enemy.global_position.distance_to(global_position);
				if dis <= 200:
					enemy.damage(dmg, "KNOCKBACK", (enemy.global_position - global_position).normalized(), 0.2);

func _on_throwable_body_entered(body):
	if body.is_in_group("wall"):
		if explodable:
			explodable = false;
			set_physics_process(false);
			var dmg = 10 if $rock_shield.get_animation()=="shield_fly" else 6;
			$rock_shield.play("explosion");
			var debris = Sprite.new();
			debris.set_texture(debris_texture);
			debris.global_position = global_position + Vector2(-1.3,1.3);
			debris.global_rotation = global_rotation;
			ability_nodes_container.add_child(debris);
			if player.pixelstan.current_room != null:
				for enemy in get_tree().get_nodes_in_group(String(player.pixelstan.current_room.get_instance_id()) + "enemy"):
					var dis = enemy.global_position.distance_to(global_position);
					if dis <= 200:
						enemy.damage(dmg, "KNOCKBACK", (enemy.global_position - global_position).normalized(), 0.2);

func _on_rock_shield_animation_finished():
	if $rock_shield.get_animation() == "explosion":
		hide();
