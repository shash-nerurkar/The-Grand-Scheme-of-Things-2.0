extends Area2D

signal reel_in
signal is_back

onready var player = $"..";

var speed := 1000;
var velocity := Vector2();
var reel := false;
var index := 0;
var rope_texture = load("res://art/bounty_hunter/hook/rope.png");
var hook_range := 500;
var is_in_range = true;
var rot;
var pos_1 := Vector2();
var pos_2 := Vector2();
var hit_obj;

func _ready():
	set_process(true);
	set_physics_process(false);

func start(dir):
	$collision.disabled = false;
	rot = dir;
	$collision.rotation = $Sprite.rotation;
	velocity = Vector2(1, 0).rotated(dir);
	set_process(false);
	set_physics_process(true);

# warning-ignore:unused_argument
func _process(delta):
	if $"../character".flip_h:
		$Sprite.position = Vector2(0, 5);
		$Sprite2.position = Vector2(12.5, 5);
	else:
		$Sprite.position = Vector2(-6, 5);
		$Sprite2.position = Vector2(6.5, 5);
	$Sprite.rotation = get_angle_to(get_global_mouse_position());
	$Sprite2.rotation = get_angle_to(get_global_mouse_position());
	global_position = $"..".global_position;

func _physics_process(delta):
	if rot > 1.57 or rot < -1.57:
		$collision.position = $Sprite.position + Vector2(5, 0);
	else:
		$collision.position = $Sprite2.position + Vector2(-5, 0);
	if $Sprite.global_position.distance_to(player.global_position) > hook_range:
		is_in_range = false;
	if is_in_range:
		if not reel:
			$Sprite.position += velocity*speed*delta;
			$Sprite2.position += velocity*speed*delta;
			
			var rope = Sprite.new();
			rope.set_texture(rope_texture);
			rope.global_position = $Sprite.global_position;
			rope.global_rotation = rot;
			$rope_container.add_child(rope);
			
			var rope2 = Sprite.new();
			rope2.set_texture(rope_texture);
			rope2.global_position = $Sprite2.global_position;
			rope2.global_rotation = rot;
			$rope_container2.add_child(rope2);
		else:
				$Sprite.global_position = pos_1;
				$Sprite2.global_position = pos_2;
	elif not reel:
		$Sprite.position -= velocity*speed*delta;
		$Sprite2.position -= velocity*speed*delta;
		if $Sprite.global_position.distance_to(player.global_position) >= 10 and $rope_container.get_child_count() > 0:
			$rope_container.get_child($rope_container.get_child_count()-1).queue_free();
		if $Sprite.global_position.distance_to(player.global_position) >= 10 and $rope_container2.get_child_count() > 0:
			$rope_container2.get_child($rope_container2.get_child_count()-1).queue_free();
		else:
			emit_signal("is_back");
			reel = false;
			is_in_range = true;
			set_process(true);
			set_physics_process(false);
	elif reel:
			$Sprite.global_position = pos_1;
			$Sprite2.global_position = pos_2

func _on_hook_body_entered(body):
	if body.is_in_group("wall") or body.is_in_group("enemy"):
		hit_obj = body;
		reel = true;
		pos_1 = $Sprite.global_position;
		pos_2 = $Sprite2.global_position;
		$collision.set_deferred("disabled", true);
		emit_signal("reel_in");

func _on_player_reeling_done():
	reel = false;
	is_in_range = true;
	set_process(true);
	set_physics_process(false);

func _on_player_retract_rope():
	is_in_range = false;
	reel = false;
