extends KinematicBody2D

onready var player;
onready var sprite = $AnimatedSprite;
onready var pixelstan = $"../../..";

var offset_mid;
var src_pos;
var dest_pos := Vector2();
var bounces = 4;
var rng = RandomNumberGenerator.new();
var dir := Vector2();
var pickup_range = 120;
var natural := true;
var magnet := false;
var time := 0.0;
var has_collided := false;

func _ready():
	rng.randomize();
	dir.x = rng.randf_range(-1, 1); 
	dir.y = rng.randf_range(-1, 1); 
	set_physics_process(false);

func _physics_process(delta):
	if bounces <= 3:
		$collision_area/CollisionShape2D.disabled = false;
	if global_position.distance_to(player.position) <= pickup_range:
		magnet = true;
		natural = false;
	if global_position.distance_to(player.position) <= 30:
		pixelstan.get_parent().player_current_gold += 1;
		queue_free();
	if magnet:
		time += delta*0.9;
		global_position = global_position.linear_interpolate(player.position, time);
	if natural:
		if not has_collided:
			if bounces >= 0:
				if $erp_timer.get_time_left() == 0:
					bounces -= 1;
					initiate(dest_pos);
				else:
					global_position = Bezier(1-(2*$erp_timer.get_time_left()));
			else:
				if weakref(sprite).get_ref() and sprite is AnimatedSprite:
					sprite.playing = true;
		else:
			if bounces >= 0:
				if $erp_timer.get_time_left() == 0:
					bounces -= 1;
					initiate(global_position);
				else:
					global_position = Bezier(1-(2*$erp_timer.get_time_left()));
			else:
				if weakref(sprite).get_ref() and sprite is AnimatedSprite:
					sprite.playing = true;

func initiate(a):
	global_position = a;
	src_pos = a;
	dest_pos.x = src_pos.x + 50*dir.x;
	dest_pos.y = src_pos.y + 50*dir.y;
	if dest_pos.x > src_pos.x:
		offset_mid = (dest_pos - src_pos)/2;
	else:
		offset_mid = (src_pos - dest_pos)/2;
	offset_mid.x += min(src_pos.x, dest_pos.x);
	offset_mid.y = min(src_pos.y, dest_pos.y) - 5*bounces*bounces*bounces;
	$erp_timer.start();
	set_physics_process(true);

func Bezier(t:float):
	var p1 = src_pos.linear_interpolate(offset_mid,t);
	var p2 = offset_mid.linear_interpolate(dest_pos,t);
	var pos =  p1.linear_interpolate(p2,t);
	return pos;

func _on_collision_area_body_entered(body):
	if body.is_in_group("wall"):
		$erp_timer.stop();
		has_collided = true;
		dir = -dir;
