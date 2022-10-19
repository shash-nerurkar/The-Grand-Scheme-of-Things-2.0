extends KinematicBody2D

onready var sprite = $lloyd;
onready var player = $"../player";
onready var ray = $laser;
onready var pray = $player_ray;

var laser_ins;

func _ready():
	queue_free();
	for i in range(1, 10, 0):
		print(i);
	print(2);
	sprite.play("shoot");
	ray.global_rotation = ray.get_angle_to(player.global_position);

func _on_lloyd_animation_finished():
	if sprite.get_animation() == "shoot":
		sprite.play("shoot_2");
		laser_ins = preload("res://scenes/laser.tscn").instance();
		$Node.add_child(laser_ins);
		laser_ins.init(ray.global_rotation, ray.global_position, ray.get_collision_point(), 'lloyd');
	elif sprite.get_animation() == "shoot_2":
		ray.global_rotation = 0;
		sprite.play("shoot");
		ray.global_rotation = ray.get_angle_to(player.global_position);
		laser_ins.queue_free();
