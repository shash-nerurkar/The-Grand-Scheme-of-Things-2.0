extends KinematicBody2D

signal release_coins
signal clear_arrays

var notifier = preload("res://scenes/notifier.tscn");
var bullet = preload("res://scenes/enemy_bullet.tscn");
var laser = preload("res://scenes/laser.tscn");
var dead_body = preload("res://scenes/dead_body.tscn");

onready var sprite = $sprite;
onready var collision = $inner_coll/CollisionShape2D;
onready var anims = $damage;
onready var player;
onready var timer = $cooldown_timer;
onready var bot = $collision/bot;
onready var top = $collision/top;
onready var ray = $player_ray;
onready var cc_timer = $cc_timer;
onready var trail = $trail;

var speed = 200;
var arange := 0;
var erange := 0;
var erange_2 := 0;
var attack_type;
var enemy;
var health = 20;
var rot = 1.57;
var STATE = 'IDLE';
var STATE_LOCK := false;
var should_flip := true;
var knockback_dir := Vector2();
var scent_search := true;
var visible_scent_position;
var dash_dir := Vector2();
var cd;
var melee_coll_1st_shape;
var melee_coll_2nd_shape;

func _ready():
	randomize();
	set_physics_process(false);

func _physics_process(delta):
	$cooldown_indicator.set_value(cd - timer.time_left);
	$health_bar.set_value(health);
	ray.cast_to = player.global_position - ray.global_position;
	if STATE_LOCK:
		STATE = melee_change_state();
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
			top.cast_to = player.global_position - top.global_position;
			bot.cast_to = player.global_position - bot.global_position;
			sprite.play("run");
			var direction_of_trav = (player.position - global_position).normalized();
# warning-ignore:return_value_discarded
			move_and_collide(direction_of_trav*speed*delta);
# warning-ignore:return_value_discarded
			STATE_LOCK = true;
			
		"ATTACK_1":
			timer.paused = false;
			should_flip = true;
			sprite.play("idle");
			attack_type = "1st";
			STATE_LOCK = true;
			
		"ATTACK_2":
			timer.paused = false;
			should_flip = true;
			sprite.play("idle");
			attack_type = "2nd";
			STATE_LOCK = true;
			
		"ATTACK_END":
			should_flip = false;
			if health <= 0:
				STATE_LOCK = true;
			if global.dash_enemy.has(enemy):
				trail.texture = sprite.frames.get_frame(sprite.animation, sprite.frame);
				move_and_collide(dash_dir*global.dash_speed[enemy]*delta);
			
		"IDLE": 
			timer.paused = true;
			should_flip = true;
			top.cast_to = player.global_position - top.global_position;
			bot.cast_to = player.global_position - bot.global_position;
			sprite.play("idle");
			STATE_LOCK = true;
			
		"SCENT":
			timer.paused = true;
			should_flip = false;
			sprite.play("run");
			if health <= 0:
				STATE_LOCK = true;
			if ray.is_colliding() and bot.is_colliding() and top.is_colliding():
				if top.get_collider().is_in_group("player") and ray.get_collider().is_in_group("player") and bot.get_collider().is_in_group("player"):
					STATE_LOCK = true;
					scent_search = true;
				elif not top.get_collider().is_in_group("player") and ray.get_collider().is_in_group("player") and bot.get_collider().is_in_group("player"):
					var angle = (player.global_position - global_position).normalized();
					angle.rotated(-1.57);
				# warning-ignore:return_value_discarded
					move_and_collide(angle*speed*2/3*delta);
				elif not bot.get_collider().is_in_group("player") and ray.get_collider().is_in_group("player") and top.get_collider().is_in_group("player"):
					var angle = (player.global_position - global_position).normalized();
					angle.rotated(1.57);
				# warning-ignore:return_value_discarded
					move_and_collide(angle*speed*2/3*delta);
				else:
					if scent_search:
						var obstruction = ray.get_collider();
						for i in player.scent_array:
							top.cast_to = i - top.global_position;
							top.force_raycast_update();
							bot.cast_to = i - bot.global_position;
							bot.force_raycast_update();
							if top.get_collider() != obstruction and bot.get_collider() != obstruction:
								scent_search = false;
								visible_scent_position = i;
								break;
							else:
								sprite.play("idle");
					else:
						top.cast_to = player.global_position - top.global_position;
						bot.cast_to = player.global_position - bot.global_position;
						var direction_of_trav = visible_scent_position - global_position;
						direction_of_trav = direction_of_trav.normalized();
						direction_of_trav = direction_of_trav*speed*2/3*delta;
					# warning-ignore:return_value_discarded
						move_and_collide(direction_of_trav);
						if global_position.distance_to(visible_scent_position) <= 1:
							scent_search = true;
			else:
				top.cast_to = player.global_position - top.global_position;
				bot.cast_to = player.global_position - bot.global_position;
			
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
				position = position.linear_interpolate(position+ 80*Vector2(0, 1), $cc_timer.time_left);
			else:
				position = position.linear_interpolate(position+ 30*Vector2(0, -1), $cc_timer.time_left);
	
	if should_flip:
		if get_angle_to(player.position) > 1.57 or get_angle_to(player.position) < -1.57:
			sprite.flip_h = true;
			collision.set_position(global.enemy_flipped_coll_pos[enemy]);
			collision.set_rotation(-global.enemy_coll_rot[enemy]);
			$cooldown_indicator.rect_position = global.cd_indicator_flipped_pos[enemy];
			$health_bar.rect_position = global.health_bar_flipped_pos[enemy];
			$collision.position = global.enemy_inner_flipped_coll_pos[enemy];
		else:
			sprite.flip_h = false;
			collision.set_position(global.enemy_coll_pos[enemy]);
			collision.set_rotation(global.enemy_coll_rot[enemy]);
			$cooldown_indicator.rect_position = global.cd_indicator_pos[enemy];
			$health_bar.rect_position = global.health_bar_pos[enemy];
			$collision.position = global.enemy_inner_coll_pos[enemy];

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
	erange_2 = global.enemy_range_2[enemy];
	
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
	
	match global.melee_coll_1st_shape[enemy]:
		'CIRCLE':
			melee_coll_1st_shape = CircleShape2D.new();
			melee_coll_1st_shape.set_radius(global.melee_coll_1st_rad[enemy]);
		'CAPSULE':
			melee_coll_1st_shape = CapsuleShape2D.new();
			melee_coll_1st_shape.set_radius(global.melee_coll_1st_rad[enemy]);
			melee_coll_1st_shape.set_height(global.melee_coll_1st_height[enemy]);
		'RECTANGLE':
			melee_coll_1st_shape = RectangleShape2D.new();
			melee_coll_1st_shape.set_extents(global.melee_coll_1st_extents[enemy]);
	
	match global.melee_coll_2nd_shape[enemy]:
		'CIRCLE':
			melee_coll_2nd_shape = CircleShape2D.new();
			melee_coll_2nd_shape.set_radius(global.melee_coll_2nd_rad[enemy]);
		'CAPSULE':
			melee_coll_2nd_shape = CapsuleShape2D.new();
			melee_coll_2nd_shape.set_radius(global.melee_coll_2nd_rad[enemy]);
			melee_coll_2nd_shape.set_height(global.melee_coll_2nd_height[enemy]);
		'RECTANGLE':
			melee_coll_2nd_shape = RectangleShape2D.new();
			melee_coll_2nd_shape.set_extents(global.melee_coll_2nd_extents[enemy]);
	
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
		STATE_LOCK = true;
		set_physics_process(true);
	elif sprite.get_animation() == ("attack_1st"):
		end_attack();
	elif sprite.get_animation() == ("attack_2nd"):
		end_attack();

func _on_cooldown_timer_timeout():
	STATE = "ATTACK_END";
	STATE_LOCK = false;
	$melee_weapon.set_position(global.get("melee" + ("_flipped_" if sprite.flip_h else "_") + "coll_" + attack_type + "_pos")[enemy]);
	$melee_weapon.rotation_degrees = 0;
	$melee_weapon.rotation_degrees = global.get("melee_coll_" + attack_type + "_rot")[enemy];
	$melee_weapon/CollisionShape2D.set_shape(get("melee_coll_" + attack_type + "_shape"));
	$melee_weapon/CollisionShape2D.set_deferred("disabled", false);
	$inner_coll.set_collision_mask_bit(0, false);
	if global.dash_enemy.has(enemy):
		trail.emitting = true;
		dash_dir = (player.position - global_position).normalized();
	sprite.play("attack_" + attack_type);

func end_attack():
	timer.start();
	$melee_weapon/CollisionShape2D.set_deferred("disabled", true);
	$melee_weapon/CollisionShape2D.set_deferred("disabled", true);
	$inner_coll.set_collision_mask_bit(0, true);
	if global.dash_enemy.has(enemy):
		trail.emitting = false;
	STATE_LOCK = true;

func _on_cc_timer_timeout():
	STATE_LOCK = true;
	timer.start();

func _on_melee_weapon_body_entered(body):
	if body.is_in_group("player"):
		body.damage(global.enemy_damage[enemy], 
						(player.global_position - global_position).normalized()*global.knockback_amount[enemy], 
						global.knockback_duration[enemy], global.enemy_debuff_type[enemy], global.enemy_debuff_amount[enemy],
						global.enemy_debuff_duration[enemy]);

func melee_change_state():
	if health <= 0:
		return 'DEAD';
	elif global_position.distance_to(player.position) > arange:
		return 'IDLE';
	elif ray.is_colliding() and bot.is_colliding() and top.is_colliding():
		if ray.get_collider() == player and bot.get_collider() == player and top.get_collider() == player:
			if global_position.distance_to(player.position) > erange:
				return 'MOVE';
			elif global_position.distance_to(player.position) < erange_2:
				return 'ATTACK_1';
			else:
				return 'ATTACK_2';
		else:
			if global.scent_enemy.has(enemy):
				return 'SCENT';
			else:
				return 'IDLE';
	else:
		return 'MOVE';

func load_anims(enemy_type):
	var sf = SpriteFrames.new();
	var loop = {"death": false, "idle": true, "run": true, "spawn": false, "happy": true, "laser": false, "laser_2": false, "shoot": false, 
				"shoot_2": false, "reload": false, "attack": false, "attack_2": false, "attack_1st": false, "attack_2nd": false};
	for anim_type in ["death", "idle", "run", "spawn", "happy", "laser", "laser_2", "shoot", "shoot_2", "reload", "attack", "attack_2", "attack_1st", "attack_2nd"]:
		if global.get(anim_type + "_frames").has(enemy_type):
			sf.add_animation(anim_type);
			for i in global.get(anim_type + "_frames")[enemy_type][0]:
				sf.add_frame(anim_type, load("res://art/enemies/" + enemy_type + "/" + anim_type + "/" + String(i+1) +  ".png"));
			sf.set_animation_speed(anim_type, global.death_frames[enemy_type][1]);
			sf.set_animation_loop(anim_type, loop[anim_type]);
	sprite.set_sprite_frames(sf);
