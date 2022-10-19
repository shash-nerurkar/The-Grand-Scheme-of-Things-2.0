extends KinematicBody2D

signal release_coins
signal clear_arrays

var notifier = preload("res://scenes/notifier.tscn");
var bullet = preload("res://scenes/enemy_bullet.tscn");
var laser = preload("res://scenes/laser.tscn");
var dead_body = preload("res://scenes/dead_body.tscn");

onready var muzzle = $muzzle;
onready var sprite = $sprite;
onready var collision = $inner_coll/CollisionShape2D;
onready var anims = $damage;
onready var player;
onready var bullet_container = $bullet_container;
onready var timer = $cooldown_timer;
onready var ray = $player_ray;
onready var laser_ray = $laser_ray;
onready var cc_timer = $cc_timer;

var speed = 200;
var arange := 0;
var erange := 0;
var enemy;
var health = 20;
var rot = 1.57;
var STATE = 'IDLE';
var STATE_LOCK := true;
var should_flip := true;
var knockback_dir := Vector2();
var laser_ins;
var cd;

func _ready():
	randomize();
	set_physics_process(false);

func _physics_process(delta):
	$cooldown_indicator.set_value(cd - timer.time_left);
	$health_bar.set_value(health);
	ray.cast_to = player.global_position - ray.global_position;
	if STATE_LOCK:
		STATE = laser_change_state();
		STATE_LOCK = false;
	match STATE:
		"DEAD":
			$health_bar.hide();
			$cooldown_indicator.hide();
			timer.stop();
			sprite.play("death");
			collision.set_deferred("disabled", true);
			$collision.set_deferred("disabled", true);
			emit_signal("release_coins", global_position);
			set_physics_process(false);
			
		"CELEBRATE":
			$health_bar.hide();
			$cooldown_indicator.hide();
			timer.stop();
			sprite.play("happy");
			set_physics_process(false);
		
		"MOVE":
			should_flip = true;
			timer.paused = true;
			sprite.play("run");
			var direction_of_trav = (player.position - global_position).normalized();
# warning-ignore:return_value_discarded
			move_and_collide(direction_of_trav*speed*delta);
			STATE_LOCK = true;
		
		"SHOOT":
			timer.paused = false;
			should_flip = true;
			sprite.play("idle");
			STATE_LOCK = true;
		
		"SHOOT_2":
			should_flip = false;
			if health <= 0:
				STATE_LOCK = true;
		
		"IDLE": 
			timer.paused = true;
			should_flip = true;
			sprite.play("idle");
			STATE_LOCK = true;
		
		"STUN":
			should_flip = false;
			sprite.stop();
		
		"KNOCKBACK":
			should_flip = false;
# warning-ignore:return_value_discarded
			move_and_collide(knockback_dir*500*delta);
			
		"KNOCKUP":
			should_flip = false;
			if $cc_timer.time_left <= $cc_timer.wait_time/2:
				position = position.linear_interpolate(position + 80*Vector2(0, 1), $cc_timer.time_left);
			else:
				position = position.linear_interpolate(position + 30*Vector2(0, -1), $cc_timer.time_left);
	
	if should_flip:
		if get_angle_to(player.position) > 1.57 or get_angle_to(player.position) < -1.57:
			sprite.flip_h = true;
			collision.set_position(global.enemy_flipped_coll_pos[enemy]);
			collision.set_rotation(-global.enemy_coll_rot[enemy]);
			$cooldown_indicator.rect_position = global.cd_indicator_flipped_pos[enemy];
			$health_bar.rect_position = global.health_bar_flipped_pos[enemy];
			$collision.position = global.enemy_inner_flipped_coll_pos[enemy];
			if sprite.get_sprite_frames().has_animation("laser"):
				$laser_ray.set_position(global.laser_flipped_pos[enemy]);
		else:
			sprite.flip_h = false;
			collision.set_position(global.enemy_coll_pos[enemy]);
			collision.set_rotation(global.enemy_coll_rot[enemy]);
			$cooldown_indicator.rect_position = global.cd_indicator_pos[enemy];
			$health_bar.rect_position = global.health_bar_pos[enemy];
			$collision.position = global.enemy_inner_coll_pos[enemy];
			if sprite.get_sprite_frames().has_animation("laser"):
				$laser_ray.set_position(global.laser_pos[enemy]);

func init(enemy_type, pos):
	load_anims(enemy_type);
	#setting type, stats, scales
	enemy = enemy_type;
	position = pos;
# warning-ignore:narrowing_conversion
	erange = rand_range(global.min_range[enemy], global.max_range[enemy]);
	health = global.enemy_health[enemy];
	speed = global.enemy_speed[enemy]*(1+randf());
	cd = global.enemy_shoot_cooldown[enemy] + randi()%4;
	timer.set_wait_time(cd);
	scale = global.enemy_scale[enemy];
	arange = global.activation_range[enemy]*(1+randf());
	
	#setting collision boxes
	var coll; 
	match global.enemy_coll_shape[enemy]:
		'CIRCLE':
			coll = CircleShape2D.new();
			coll.set_radius(global.enemy_rad[enemy]);
		'CAPSULE':
			coll = CapsuleShape2D.new();
			coll.set_radius(global.enemy_rad[enemy]);
			coll.set_height(global.enemy_height[enemy]);
		'RECTANGLE':
			coll = RectangleShape2D.new();
			coll.set_extents(global.enemy_extents[enemy]);
	collision.set_shape(coll);
	collision.set_position(global.enemy_coll_pos[enemy]);
	collision.set_rotation(global.enemy_coll_rot[enemy]);
	
	#setting cd indicator and hp var values
	$cooldown_indicator.rect_position = global.cd_indicator_pos[enemy];
	$cooldown_indicator.rect_scale = global.cd_indicator_scale[enemy];
	$cooldown_indicator.max_value = cd;
	$health_bar.rect_position = global.health_bar_pos[enemy];
	$health_bar.rect_scale = global.health_bar_scale[enemy];
	$health_bar.value = timer.get_wait_time();
	$health_bar.max_value = health;
	$health_bar.value = health;
	
	#miscellaneous
	if global.flying_enemy.has(enemy):
		$inner_coll.set_collision_layer_bit(1, false);
		$inner_coll.set_collision_layer_bit(10, true);
		$inner_coll.set_collision_mask_bit(0, false);
		$inner_coll.set_collision_mask_bit(1, false);

func damage(amount, CC, dir, duration): 
	#if health > 0:
	#anims.play("damage");
	#damage
	health -= amount;
	#cc logic
	knockback_dir = dir;
	cc_timer.start(duration);
	STATE_LOCK = false;
	STATE = CC;
	#damage label
	for child in get_children():
		if child is Label:
			if child.type == 'damage' and child.editable:
				child.set_val(amount, amount/global.weapon_damage[global.weapon_in_hand] == 2);
				return;
	var l = notifier.instance();
	add_child(l);
	l.initialize(Vector2());
	l.set_val(amount, amount/global.weapon_damage[global.weapon_in_hand] == 2);

func _on_mughal_mongol_animation_finished():
	if sprite.get_animation() == ("death"):
		emit_signal("clear_arrays", self);
		queue_free();
	elif sprite.get_animation() == ("spawn"):
		set_physics_process(true);
		collision.disabled = false;
	elif sprite.get_animation() == ("shoot"):
		STATE_LOCK = true;
		single_shoot(enemy);
		timer.start();
	elif sprite.get_animation() == ("laser"):
		sprite.play("laser_2");
		laser_ins = laser.instance();
		bullet_container.add_child(laser_ins);
		laser_ins.init(laser_ray.global_rotation, laser_ray.global_position, laser_ray.get_collision_point(), enemy);
	elif sprite.get_animation() == ("laser_2"):
		timer.start();
		STATE_LOCK = true;
		laser_ins.end();

func _on_cooldown_timer_timeout():
	STATE = "SHOOT_2";
	STATE_LOCK = false;
	if sprite.get_sprite_frames().has_animation("laser"):
		laser_ray.global_rotation = 0;
		laser_ray.global_rotation = laser_ray.get_angle_to(player.global_position);
		sprite.play("laser");
	elif sprite.get_sprite_frames().has_animation("shoot"):
		sprite.play("shoot");

func _on_cc_timer_timeout():
	STATE_LOCK = true;
	timer.start();

func laser_change_state():
	if health <= 0:
		return 'DEAD';
	elif ray.is_colliding():
		if ray.get_collider() == player:
			if global_position.distance_to(player.position) > erange:
				return 'MOVE';
			else:
				return 'SHOOT';
		else:
			return "IDLE";
	else:
		return "IDLE";

func single_shoot(type):
	var b = bullet.instance();
	b.scale = scale;
	bullet_container.add_child(b);
	b.start_pos(muzzle.get_angle_to(player.position), muzzle.global_position, type);

func load_anims(enemy_type):
	var sf = SpriteFrames.new();
	var loop = {"death": false, "idle": true, "run": true, "spawn": false, "happy": true, "laser": false, 
				"laser_2": false, "shoot": false, "shoot_2": false, "reload": false, "attack": false, "attack_2": false};
	for anim_type in ["death", "idle", "run", "spawn", "happy", "laser", "laser_2", "shoot", "shoot_2", "reload", "attack", "attack_2"]:
		if global.get(anim_type + "_frames").has(enemy_type):
			sf.add_animation(anim_type);
			for i in global.get(anim_type + "_frames")[enemy_type][0]:
				sf.add_frame(anim_type, load("res://art/enemies/" + enemy_type + "/" + anim_type + "/" + String(i+1) +  ".png"));
			sf.set_animation_speed(anim_type, global.death_frames[enemy_type][1]);
			sf.set_animation_loop(anim_type, loop[anim_type]);
	sprite.set_sprite_frames(sf);
