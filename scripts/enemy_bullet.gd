extends Area2D

onready var sprite = get_node("AnimatedSprite");

var vel = Vector2();
export var speed = 600;
var curve_bullet := false;
var once := true;
var bullet_type;

func _ready():
	set_physics_process(false);

func start_pos(dir, pos, type):
	rotation = dir;
	position = pos;
	vel = Vector2(speed, 0).rotated(dir);
	bullet_type = type;
	sprite.play("%s_fly" % bullet_type);
	var coll;
	match global.enemy_bullet_coll_shape[type]:
		"CAPSULE":
			coll = CapsuleShape2D.new();
			coll.radius = global.enemy_bullet_coll_rad[type];
			coll.height = global.enemy_bullet_coll_height[type];
		"CIRCLE":
			coll = CircleShape2D.new();
			coll.radius = global.enemy_bullet_coll_rad[type];
		"RECTANGLE":
			coll = RectangleShape2D.new();
			coll.extents = global.enemy_bullet_coll_extents[type];
	$collision.shape = coll;
	$collision.position = global.enemy_bullet_coll_pos[type];
	set_physics_process(true);

func _physics_process(delta):
	position += vel * delta;
	if curve_bullet:
		vel = vel.rotated(0.03);
		sprite.rotation += 0.03;
	if not weakref(sprite).get_ref():
		queue_free();

func _on_enemy_bullet_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("player_friendly"):
		sprite.play("%s_collide" % bullet_type);
		$collision.set_deferred("disabled", true);
		vel = Vector2(0, 0);
		body.damage(global.enemy_damage[bullet_type], (body.global_position - global_position).normalized()*1, 0.015, global.enemy_debuff_type[bullet_type], global.enemy_debuff_amount[bullet_type], global.enemy_debuff_duration[bullet_type]);
	elif body.is_in_group("wall"):
		sprite.play("%s_collide" % bullet_type);
		$collision.set_deferred("disabled", true);
		vel = Vector2(0, 0);

func _on_AnimatedSprite_animation_finished():
	if sprite.get_animation() == ("%s_collide" % bullet_type):
		queue_free();
