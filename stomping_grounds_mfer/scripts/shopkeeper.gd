extends KinematicBody2D

onready var sprite = $sprite;
onready var collision = $CollisionPolygon2D;
onready var detection_area = $shopkeeper/CollisionPolygon2D;

signal start_interact_notifier
signal stop_interact_notifier

var shopkeeper_frames = {"green_dungeon": 8,
						 "gemcave": 4};

var shopkeeper_coll_array = {"green_dungeon": [Vector2(175, 122), Vector2(275, 122), Vector2(265, 185), Vector2(185, 185)],
							 "gemcave": [Vector2(), Vector2(), Vector2(), Vector2()]};

var shopkeeper_detection_coll_array = {"green_dungeon": [Vector2(-12, 1), Vector2(98, 1), Vector2(98, 78), Vector2(-12, 78)],
									   "gemcave": [Vector2(), Vector2(), Vector2(), Vector2()]};

func initialize(biome):
	for i in range(shopkeeper_frames[biome]):
		sprite.get_sprite_frames().add_frame("default", load("res://art/shopkeeper/" + biome + "/" + String(i+1) + ".png"));
	collision.set_polygon(shopkeeper_coll_array[biome]);
	detection_area.set_polygon(shopkeeper_detection_coll_array[biome]);

func _on_shopkeeper_body_entered(body):
	if body.is_in_group("player"):
		global.can_shop = true;
		emit_signal("start_interact_notifier");

func _on_shopkeeper_body_exited(body):
	if body.is_in_group("player"):
		global.can_shop = false;
		emit_signal("stop_interact_notifier");
