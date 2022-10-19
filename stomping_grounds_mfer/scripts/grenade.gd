extends Area2D

var offset_mid := Vector2();
var src_pos;
var dest_pos := Vector2();
var bounce := 3;
var dir := 0.0;
var i := 1;
var rot_amt := 10;
var once := true;
var height := 25.0;
var duration := 3;
var slow_rotation := false;
var nade_type;
var frag_damage := 10;
var flash_stun := 2;

onready var smoke = $color/Particles2D;
onready var smoke_duration = $color/duration;
onready var sprite = $AnimatedSprite;
onready var player = $"../..";

func _ready():
	smoke_duration.start(duration);
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	if bounce > 0:
		smoke_duration.paused = true;
		if bounce != 1:
			rotation_degrees += rot_amt;
		if $erp_timer.get_time_left() == 0:
			rot_amt = -rot_amt;
			initiate(global_position, dir, nade_type);
		else:
			global_position = Bezier(1-(2*$erp_timer.get_time_left()));
	else:
		match nade_type:
			"smoke":
				if slow_rotation:
					if sprite.speed_scale > 0.05:
						sprite.speed_scale -= 0.0014;
					else:
						queue_free();
				else:
					smoke_duration.paused = false;
					smoke.emitting = true;
					global_rotation = 0;
					$color/CollisionShape2D.disabled = false;
					sprite.play("smoke_color");
			"frag":
				global_rotation = 0;
				$color/CollisionShape2D.disabled = false;
				sprite.play("frag_color");
				if player.pixelstan.current_room != null:
					for enemy in get_tree().get_nodes_in_group(String(player.pixelstan.current_room.get_instance_id()) + "enemy"):
						var dis = enemy.global_position.distance_to(global_position);
						if dis <= 105:
							enemy.damage(frag_damage, "KNOCKBACK", (enemy.global_position - global_position).normalized(), 0.25);
				set_physics_process(false);
			"flash":
				global_rotation = 0;
				$color/CollisionShape2D.disabled = false;
				sprite.play("flash_color");
				if player.pixelstan.current_room != null:
					for enemy in get_tree().get_nodes_in_group(String(player.pixelstan.current_room.get_instance_id()) + "enemy"):
						var dis = enemy.global_position.distance_to(global_position);
						if dis <= 105:
							enemy.damage(1, "STUN", Vector2(), flash_stun);
				set_physics_process(false);

func initiate(s, d, type):
	nade_type = type;
	sprite.play("%s_fly" % nade_type);
	sprite.get_sprite_frames().set_animation_speed("smoke_color", 35);
	var coll = RectangleShape2D.new();	
	coll.set_extents(Vector2(8.6, 17.8));
	$CollisionShape2D.set_shape(coll);
	$CollisionShape2D.set_position(Vector2(-2.8, 2.1));
	match nade_type:
		"smoke":
			coll = CapsuleShape2D.new();
			coll.radius = 39;
			coll.height = 60.5;
			$color/CollisionShape2D.set_shape(coll);
			$CollisionShape2D.set_position(Vector2(1.8, 1.3));
		"frag":
			coll = CircleShape2D.new();
			coll.radius = 43;
			$color/CollisionShape2D.set_shape(coll);
			$CollisionShape2D.set_position(Vector2(1.8, 1.3));
		"flash":
			coll = CircleShape2D.new();
			coll.radius = 43;
			$color/CollisionShape2D.set_shape(coll);
			$CollisionShape2D.set_position(Vector2(-2.8, 2.1));
	src_pos = s;
	dest_pos = s + Vector2(150, 0).rotated(d);
	offset_mid = Vector2(50, 0);
	dir = d;
	offset_mid.x += min(src_pos.x, dest_pos.x);
	offset_mid.y = min(src_pos.y, dest_pos.y) - 5*height;
	height /= 1.5;
	bounce -= 1;
	$erp_timer.start();
	set_physics_process(true);

func Bezier(t:float):
	var p1 = src_pos.linear_interpolate(offset_mid,t);
	var p2 = offset_mid.linear_interpolate(dest_pos,t);
	var pos =  p1.linear_interpolate(p2,t);
	return pos;

func _on_Area2D_body_entered(body):
	if body.is_in_group("wall"):
		$erp_timer.stop();
		dir = deg2rad(rad2deg(dir)+180.0);

func _on_smoke_body_entered(body):
	if body.is_in_group("player") and nade_type == "smoke":
		player.is_invis = true;
		body.modulate = Color(1, 1, 1, .5);
		if player.pixelstan.current_room != null:
			for enemy in player.pixelstan.current_room.enemy_container.get_children():
				enemy.STATE_LOCK = false;
				enemy.STATE = "CC";

func _on_smoke_body_exited(body):
	if body.is_in_group("player") and nade_type == "smoke":
		player.is_invis = false;
		body.modulate = Color(1, 1, 1, 1);
		if player.pixelstan.current_room != null:
			for enemy in player.pixelstan.current_room.enemy_container.get_children():
				enemy.set_physics_process(true);
				enemy.STATE_LOCK = true;

func _on_smoke_duration_timeout():
	slow_rotation = true;
	smoke.emitting = false;
	$color/CollisionShape2D.disabled = true;

func _on_AnimatedSprite_animation_finished():
	if sprite.get_animation() == "frag_color":
		queue_free();
	elif sprite.get_animation() == "flash_color":
		queue_free();
