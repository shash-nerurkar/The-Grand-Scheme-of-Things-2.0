extends Position2D

onready var player;
onready var camera = $main_camera;

var fake_drag_margin := 300;

func _ready():
	#camera.global_position = player.position;
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	if(weakref(player).get_ref() and player is KinematicBody2D):
		camera.global_position = camera.global_position.linear_interpolate(player.look_direction, delta);
		while camera.global_position.distance_to(player.position) > fake_drag_margin:
			camera.global_position = camera.global_position.linear_interpolate(player.global_position, delta);

func update_pivot_angle():
	rotation = player.look_direction.angle();

