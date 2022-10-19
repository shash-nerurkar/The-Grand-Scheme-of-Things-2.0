extends KinematicBody2D

onready var player = $maratha;

var speed = 12000
var velocity = Vector2()
var flipped_collision_polygon_array := [Vector2(15.349, -23.073), Vector2(6.798, -23.097),
										Vector2(-10.787, -14.033), Vector2(-10.382, -2.4),
										Vector2(-17.145, 4.364), Vector2(-16.109, 26.05),
										Vector2(-1.183, 28.172), Vector2(7.475, 27.767),
										Vector2(10.153, -15.799), Vector2(13.292, -16.063)];
var collision_polygon_array := [];

func _ready():
	collision_polygon_array = $collision.get_polygon();

func _physics_process(delta):
	velocity = Vector2();
	if(Input.is_action_pressed("player_right")):
		velocity.x += 1;
		player.play("run");
	if(Input.is_action_pressed("player_left")):
		velocity.x -= 1;
		player.play("run");
	if(Input.is_action_pressed("player_up")):
		velocity.y -= 1;
		player.play("run");
	if(Input.is_action_pressed("player_down")):
		velocity.y += 1;
		player.play("run");
	if(Input.is_action_just_released("player_right") || Input.is_action_just_released("player_left") || Input.is_action_just_released("player_up") || Input.is_action_just_released("player_down")):
		player.play("idle");
	velocity = velocity*speed*delta;
# warning-ignore:return_value_discarded
	move_and_slide(velocity);
	if get_angle_to(get_global_mouse_position())>1.57 or get_angle_to(get_global_mouse_position())<-1.57:
		player.flip_h = true;
		$collision.set_polygon(flipped_collision_polygon_array);
		$lantern.position = Vector2(-11.337, 12.407);
	else:
		player.flip_h = false;
		$collision.set_polygon(collision_polygon_array);
		$lantern.position = Vector2(13.874, 12.223);

