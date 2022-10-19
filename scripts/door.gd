extends KinematicBody2D

onready var sprite = $AnimatedSprite;
onready var collision = $CollisionShape2D;

var facing;

func init(pos, dir):
	global_position = pos;
	facing = dir;
	var coll = RectangleShape2D.new();
	if dir == "front":
		coll.set_extents(Vector2(32, 18.3));
		collision.position.y = 13.5;
	else:
		coll.set_extents(Vector2(13.5, 32.7));
	collision.set_shape(coll);
	sprite.play(facing + "_open_state");

func close():
	sprite.play(facing + "_close");
	collision.set_deferred("disabled", false);

func open():
	sprite.play(facing + "_open");
	collision.set_deferred("disabled", true);

func initialise(biome):
	for dir in ["front", "side"]:
		for i in range(5):
			$AnimatedSprite.get_sprite_frames().set_frame(dir + "_close", i, load("res://art/tileset/" + biome + "/door/" + dir + "_" + String(5-i) + ".png"));
			$AnimatedSprite.get_sprite_frames().set_frame(dir + "_open", i, load("res://art/tileset/" + biome + "/door/" + dir + "_" + String(i+1) + ".png"));
		$AnimatedSprite.get_sprite_frames().set_frame(dir + "_open_state", 0, load("res://art/tileset/" + biome + "/door/" + dir + "_5.png"));
	queue_free();
