extends KinematicBody2D

signal release_coins
signal clear_arrays

var notifier = preload("res://scenes/notifier.tscn");
var bullet = preload("res://scenes/enemy_bullet.tscn");
var laser = preload("res://scenes/laser.tscn");
var dead_body = preload("res://scenes/dead_body.tscn");

onready var trail = $trail;
onready var sprite = $sprite;
onready var collision = $inner_coll/CollisionShape2D;
onready var anims = $damage;
onready var player;
onready var timer = $cooldown_timer;
onready var ray = $player_ray;
onready var cc_timer = $cc_timer;

var speed = 200;
var arange := 0;
var enemy;
var health = 20;
var rot = 1.57;
var has_stamina := true;
var STATE = 'IDLE';
var STATE_LOCK := true;
var caught := false;
var should_flip := true;
var knockback_dir := Vector2();
var cc_time := 0.0;
var src_pos := Vector2();
var dest_pos := Vector2();
var offset_mid := Vector2();
var label = null;
var label2 = null;
var cd;
var dash_dir;

func _ready():
	randomize();
	set_physics_process(false);

func _physics_process(delta):
	$cooldown_indicator.set_value(cd - timer.time_left);
	$health_bar.set_value(health);
	ray.cast_to = player.global_position - ray.global_position;
	if STATE_LOCK:
		STATE = assassin_change_state();
		STATE_LOCK = false;
	match STATE:
		"DEAD":
			$health_bar.hide();
			$cooldown_indicator.hide();
			timer.stop();
			sprite.play("death");
			collision.set_deferred("disabled", true);
			$inner_coll/CollisionShape2D.set_deferred("disabled", true);
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
		
		"ATTACK":
			timer.paused = false;
			should_flip = true;
			caught = true;
			if health <= 0:
				STATE_LOCK = true;
			if sprite.get_sprite_frames().has_animation("attack_2"):
				if sprite.get_animation() == "attack":
					sprite.play("attack");
				else:
					sprite.play("idle");
					STATE_LOCK = true;
			else:
				sprite.play("idle");
				STATE_LOCK = true;
			
		"ATTACK_2":
			should_flip = false;
			trail.texture = sprite.frames.get_frame(sprite.animation, sprite.frame);
			if global.bezier_enemy.has(enemy):
				global_position = bez(1-2*($erp_timer.get_time_left()));
			else:
			# warning-ignore:return_value_discarded
				move_and_collide(dash_dir*speed*delta);
			if health <= 0:
				STATE_LOCK = true;
			
		"IDLE": 
			timer.paused = true;
			should_flip = false if not caught else true;
			sprite.play("idle");
			STATE_LOCK = true;
			
		"STUN":
			sprite.stop();
			should_flip = false;
			
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
			$inner_coll.position = global.enemy_inner_flipped_coll_pos[enemy];
			$melee_weapon.set_position(global.melee_flipped_coll_pos[enemy]);
		else:
			sprite.flip_h = false;
			collision.set_position(global.enemy_coll_pos[enemy]);
			collision.set_rotation(global.enemy_coll_rot[enemy]);
			$cooldown_indicator.rect_position = global.cd_indicator_pos[enemy];
			$health_bar.rect_position = global.health_bar_pos[enemy];
			$inner_coll.position = global.enemy_inner_coll_pos[enemy];
			$melee_weapon.set_position(global.melee_coll_pos[enemy]);

func init(enemy_type, pos):
	load_anims(enemy_type);
	#setting type, stats, scales
	enemy = enemy_type;
	position = pos;
# warning-ignore:narrowing_conversion
	arange = global.activation_range[enemy]*(1+randf());
	health = global.enemy_health[enemy];
	speed = global.enemy_speed[enemy]*(1+randf());
	cd = global.enemy_shoot_cooldown[enemy] + randi()%4;
	timer.set_wait_time(cd);
	scale = global.enemy_scale[enemy];
	
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
	
	var coll2; 
	match global.melee_coll_shape[enemy]:
		'CIRCLE':
			coll2 = CircleShape2D.new();
			coll2.set_radius(global.melee_coll_rad[enemy]);
		'CAPSULE':
			coll2 = CapsuleShape2D.new();
			coll2.set_radius(global.melee_coll_rad[enemy]);
			coll2.set_height(global.melee_coll_height[enemy]);
		'RECTANGLE':
			coll2 = RectangleShape2D.new();
			coll2.set_extents(global.melee_coll_extents[enemy]);
	$melee_weapon/CollisionShape2D.set_shape(coll2);
	$melee_weapon.set_position(global.melee_coll_pos[enemy]);
	
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
	
	trail.scale = scale;

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
	elif sprite.get_animation() == ("attack"):
		if sprite.get_sprite_frames().has_animation("attack_2"):
			sprite.play("attack_2");
			start_attack();
		elif enemy == "gondurr":
			return;
		else:
			end_attack();
	elif sprite.get_animation() == ("attack_2"):
		end_attack();

func _on_cooldown_timer_timeout():
	sprite.play("attack");
	if not sprite.get_sprite_frames().has_animation("attack_2"):
		start_attack();

func start_attack():
	STATE = "ATTACK_2";
	STATE_LOCK = false;
	$melee_weapon/CollisionShape2D.set_deferred("disabled", false);
	$inner_coll.set_collision_mask_bit(0, false);
	trail.emitting = true;
	if global.bezier_enemy.has(enemy):
		bez_init(global_position, player.global_position);
	else:
		dash_dir = (player.position - global_position).normalized();

func end_attack():
	timer.start();
	$melee_weapon/CollisionShape2D.set_deferred("disabled", true);
	$inner_coll.set_collision_mask_bit(0, true);
	trail.emitting = false;
	STATE_LOCK = true;

func _on_melee_weapon_body_entered(body):
	match enemy:
		"gondurr":
			STATE = "DEAD";
			if global_position.distance_to(player.position) <= 300:
				player.damage(global.enemy_damage[enemy], 
							(player.global_position - global_position).normalized()*global.knockback_amount[enemy], 
							global.knockback_duration[enemy], global.enemy_debuff_type[enemy], global.enemy_debuff_amount[enemy],
							global.enemy_debuff_duration[enemy]);
		"slugpine":
			if body == player:
				body.damage(global.enemy_damage[enemy], 
						(player.global_position - global_position).normalized()*global.knockback_amount[enemy], 
						global.knockback_duration[enemy], global.enemy_debuff_type[enemy], global.enemy_debuff_amount[enemy],
						global.enemy_debuff_duration[enemy]);

func assassin_change_state():
	if health <= 0:
		return 'DEAD';
	elif ray.is_colliding():
		if not ray.get_collider().is_in_group("player"):
			return 'IDLE';
		elif global_position.distance_to(player.position) <= arange:
			return 'ATTACK';
		elif not caught:
			return 'IDLE';
		else:
			return 'MOVE';
	else:
		return 'IDLE';

func load_anims(enemy_type):
	var sf = SpriteFrames.new();
	var loop = {"death": false, "idle": true, "run": true, "spawn": false, "happy": true, "laser": false, 
				"laser_2": false, "shoot": false, "shoot_2": false, "reload": false, "attack": true if enemy_type == "gondurr" else false, "attack_2": false};
	for anim_type in ["death", "idle", "run", "spawn", "happy", "laser", "laser_2", "shoot", "shoot_2", "reload", "attack", "attack_2"]:
		if global.get(anim_type + "_frames").has(enemy_type):
			sf.add_animation(anim_type);
			for i in global.get(anim_type + "_frames")[enemy_type][0]:
				sf.add_frame(anim_type, load("res://art/enemies/" + enemy_type + "/" + anim_type + "/" + String(i+1) +  ".png"));
			sf.set_animation_speed(anim_type, global.death_frames[enemy_type][1]);
			sf.set_animation_loop(anim_type, loop[anim_type]);
	sprite.set_sprite_frames(sf);

func bez(t : float):
	var p1 = src_pos.linear_interpolate(offset_mid,t);
	var p2 = offset_mid.linear_interpolate(dest_pos,t);
	var pos =  p1.linear_interpolate(p2,t);
	return pos;

func bez_init(src, dest):
	src_pos = src;
	dest_pos = dest;
	offset_mid = (dest_pos - src_pos).abs()/2;
	offset_mid.x += min(src_pos.x, dest_pos.x);
	offset_mid.y = min(src_pos.y, dest_pos.y);
	$erp_timer.start();
 
func _on_cc_timer_timeout():
	STATE_LOCK = true;
	timer.start();
