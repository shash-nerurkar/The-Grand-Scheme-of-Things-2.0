extends KinematicBody2D

signal screen_shake_requested
signal blood_requested
signal weapon_pickup
signal weapon_combine
signal hide_pickup
signal display_out_of_ammo
signal zoom_in
signal zoom_out
signal player_has_fallen

var notifier = preload("res://scenes/notifier.tscn");
var dust = preload("res://scenes/dust.tscn");
#var ability_1_sound = preload();
#var ability_2_sound = preload();

onready var sprite = $character;
onready var weapon = $weapon;
onready var throwable = $ability_nodes_container/throwable;
onready var throwable_sprite = $ability_nodes_container/throwable/rock_shield;
onready var shield = $ability_nodes_container/hulk_shield;
onready var shield_sprite = $ability_nodes_container/hulk_shield/sprite;
onready var cc_timer = $cc_timer;
onready var shield_ray = $shield_detector;
onready var a1_timer = $ability_1;
onready var a2_timer = $ability_2;
onready var pixelstan = $"../../..";
onready var debuff_timer = $debuff_timer;

var a1_cooldown = 3;
var a2_cooldown = 3;
var flipped_collision_array := [Vector2(1.153, -19.406), Vector2(15.324, -11.565),
								Vector2(15.229, 2.038), Vector2(10.832, 6.114),
								Vector2(2.948, 19.987), Vector2(-9.238, 19.987),
								Vector2(-15.053, 13.902), Vector2(-14.151, -13.454),
								Vector2(-9.71, -19.122)];
var collision_array := [];
var debuff_type;
var debuff_amount;
var health := 2000;
var max_health := 2000.0;
var speed = 150;
var min_speed = 150;
var max_speed = 200;
var armor = 25;
var velocity = Vector2();
var type = "machine_gun";
var STATE := "IDLE";
var is_shopping := false;
# warning-ignore:unused_class_variable
var look_direction := Vector2();
var alive := true;
var once := true;
var shield_pos := Vector2();
var throw := Vector2();
var scent_array := [];
var knockedback := false;
var knockback_dir := Vector2();
var can_move := true;
var can_flip := true;
var can_shoot := true;
var knockup_damage := 5;
var crater_texture;
var shield_debris_texture;
var dust_texture;

func initialize(biome):
	shield.debris_texture = load("res://art/hulk/abilities/" + biome + "/shield/break_3.png");
	throwable.debris_texture = load("res://art/hulk/abilities/" + biome + "/explosion/13.png");
	dust_texture = load("res://art/hulk/abilities/" + biome +"/particle.png");
	crater_texture = load("res://art/hulk/abilities/" + biome + "/crater.png");
	shield_debris_texture = load("res://art/hulk/abilities/" + biome + "/shield_debris.png");
	shield_sprite.get_sprite_frames().add_frame("break_1", load("res://art/hulk/abilities/" + biome + "/shield/cracked.png"));
	throwable_sprite.get_sprite_frames().add_frame("rock_fly", load("res://art/hulk/abilities/" + biome + "/rock.png"));
	throwable_sprite.get_sprite_frames().add_frame("shield_fly", load("res://art/hulk/abilities/" + biome + "/shield.png"));
	for i in range(3):
		sprite.get_sprite_frames().add_frame("chuck_rock", load("res://art/hulk/chuck/" + biome + "/" + String(i+1) + ".png"));
		sprite.get_sprite_frames().add_frame("chuck_rock_2", load("res://art/hulk/chuck/" + biome + "/" + String(i+6) + ".png"));
		sprite.get_sprite_frames().add_frame("chuck_shield", load("res://art/hulk/pick/" + biome + "/" + String(i+1) + ".png"));
		shield_sprite.get_sprite_frames().add_frame("broken", load("res://art/hulk/abilities/" + biome + "/shield/break_" + String(i+1) + ".png"));
		shield_sprite.get_sprite_frames().add_frame("sprout", load("res://art/hulk/abilities/" + biome + "/shield/sprout_" + String(i+1) + ".png"));
		throwable_sprite.get_sprite_frames().add_frame("explosion", load("res://art/hulk/abilities/" + biome + "/explosion/" + String(i+1) + ".png"));
	for i in range(3, 5):
		sprite.get_sprite_frames().add_frame("chuck_rock", load("res://art/hulk/chuck/" + biome + "/" + String(i+1) + ".png"));
		sprite.get_sprite_frames().add_frame("chuck_rock_2", load("res://art/hulk/chuck/" + biome + "/" + String(i+6) + ".png"));
		sprite.get_sprite_frames().add_frame("chuck_shield", load("res://art/hulk/pick/" + biome + "/" + String(i+1) + ".png"));
		shield_sprite.get_sprite_frames().add_frame("sprout", load("res://art/hulk/abilities/" + biome + "/shield/sprout_" + String(i+1) + ".png"));
		throwable_sprite.get_sprite_frames().add_frame("explosion", load("res://art/hulk/abilities/" + biome + "/explosion/" + String(i+1) + ".png"));
	for i in range(5, 8):
		sprite.get_sprite_frames().add_frame("chuck_rock_2", load("res://art/hulk/chuck/" + biome + "/" + String(i+6) + ".png"));
		sprite.get_sprite_frames().add_frame("chuck_shield", load("res://art/hulk/pick/" + biome + "/" + String(i+1) + ".png"));
		shield_sprite.get_sprite_frames().add_frame("sprout", load("res://art/hulk/abilities/" + biome + "/shield/sprout_" + String(i+1) + ".png"));
		throwable_sprite.get_sprite_frames().add_frame("explosion", load("res://art/hulk/abilities/" + biome + "/explosion/" + String(i+1) + ".png"));
	for i in range(8, 10):
		sprite.get_sprite_frames().add_frame("chuck_shield", load("res://art/hulk/pick/" + biome + "/" + String(i+1) + ".png"));
		shield_sprite.get_sprite_frames().add_frame("sprout", load("res://art/hulk/abilities/" + biome + "/shield/sprout_" + String(i+1) + ".png"));
		throwable_sprite.get_sprite_frames().add_frame("explosion", load("res://art/hulk/abilities/" + biome + "/explosion/" + String(i+1) + ".png"));
	for i in range(10, 13):
		sprite.get_sprite_frames().add_frame("chuck_shield", load("res://art/hulk/pick/" + biome + "/" + String(i+1) + ".png"));
		throwable_sprite.get_sprite_frames().add_frame("explosion", load("res://art/hulk/abilities/" + biome + "/explosion/" + String(i+1) + ".png"));
	sprite.get_sprite_frames().add_frame("chuck_shield", load("res://art/hulk/pick/" + biome + "/14.png"));

func _ready():
	a1_timer.set_wait_time(a1_cooldown);
	a2_timer.set_wait_time(a2_cooldown);
	$scent_timeout_timer.paused = true;
	position = get_viewport_rect().size/2;
	collision_array = $collision.get_polygon();
	global.weapon_in_hand = type;
	weapon.type_assign(type);
	weapon.ammo_assign(type);
	weapon.get_node("collision").set_deferred("disabled", true);

func _input(event):
	if event.is_action_pressed("player_interact"):
		if global.can_shop:
			if is_shopping:
				is_shopping = false;
				emit_signal("zoom_out");
			else:
				is_shopping = true;
				emit_signal("zoom_in");
		elif global.weapon_to_pickup:
			global.weapon_to_pickup = false;
			emit_signal("weapon_pickup");
			emit_signal("hide_pickup");
			global.weapon_in_hand = type;
	if event.is_action_pressed("weapon_combine"):
		if global.weapon_to_pickup:
			emit_signal("weapon_combine");
	if event.is_action_pressed("player_ability") and a1_timer.is_stopped():
		a1_timer.start();
		shield.throwable = true;
		weapon.hide();
		$hand.hide();
		shield_pos = global_position + Vector2(80*cos(get_angle_to(get_global_mouse_position())), 80*sin(get_angle_to(get_global_mouse_position())));
		sprite.play("test");
		set_physics_process(false);
		set_process_input(false);
	if event.is_action_pressed("player_ability_2") and a2_timer.is_stopped():
		a2_timer.start();
		throw = get_global_mouse_position();
		weapon.hide();
		$hand.hide();
		var circle = CircleShape2D.new();
		if shield.throwable and global_position.distance_to(shield_pos) <= 70 and shield_ray.is_colliding():
			shield.throwable = false;
			shield.hide();
			shield.get_node("collision").set_deferred("disabled", true);
			sprite.play("chuck_shield");
			circle.radius = 10.5;
			throwable.get_node("CollisionShape2D").set_shape(circle);
			throwable.get_node("CollisionShape2D").position = Vector2(0.177, 0.812);
		else:
			sprite.play("chuck_rock");
			circle.radius = 13.5;
			throwable.get_node("CollisionShape2D").set_shape(circle);
			throwable.get_node("CollisionShape2D").position = Vector2(-0.25, 2.378);
		set_physics_process(false);
		set_process_input(false);
	if event.is_action_pressed("backdoor"):
		position = pixelstan.end_room.position;

# warning-ignore:unused_argument
func _physics_process(delta):
	shield_ray.cast_to = get_global_mouse_position() - shield_ray.global_position;
	velocity = Vector2();
	if alive:
		if health<=0:
			alive = false;
			health = 0;
			weapon.hide();
			sprite.play("death");
		else:
			if can_move:
				STATE = "IDLE";
				if(Input.is_action_pressed("player_right")):
					velocity.x += 1;
					STATE = "RUN";
				elif(Input.is_action_pressed("player_left")):
					velocity.x -= 1;
					STATE = "RUN";
				if(Input.is_action_pressed("player_up")):
					velocity.y -= 1;
					STATE = "RUN";
				elif(Input.is_action_pressed("player_down")):
					velocity.y += 1;
					STATE = "RUN";
				if STATE == "RUN":
					$dust.emitting = true;
					if get_angle_to(get_global_mouse_position())>1.57 or get_angle_to(get_global_mouse_position())<-1.57:
						if velocity.x == 1:
							sprite.play("run", true);
						else:
							sprite.play("run");
					else:
						if velocity.x == -1:
							sprite.play("run", true);
						else:
							sprite.play("run");
					$hand.set_frame(sprite.get_frame());
					$hand.play("run");
				else:
					$dust.emitting = false;
					sprite.play("idle");
					$hand.set_frame(sprite.get_frame());
					$hand.play("idle");
				velocity = velocity*speed;
				if velocity != Vector2(0, 0):
					speed += 3;
				else:
					speed = max_speed;
				speed = clamp(speed, min_speed, max_speed);
			# warning-ignore:return_value_discarded
				move_and_slide(velocity);
				$dust.get_process_material().direction = Vector3(-velocity.x, -velocity.y, 0);
			if can_shoot:
				if(Input.is_action_pressed("player_shoot")):
					if STATE == "IDLE":
						sprite.stop();
					if($weapon/bullet_cooldown.get_time_left() == 0 and weapon.ammo > 0):
						weapon.shoot();
					elif weapon.ammo <= 0:
						weapon.ammo = 0;
						emit_signal("display_out_of_ammo");
			if can_flip:
				weapon.rotation = get_angle_to(get_global_mouse_position());
				if get_angle_to(get_global_mouse_position())>1.57 or get_angle_to(get_global_mouse_position())<-1.57:
					$weapon/Sprite.flip_v = true;
					$dust.position = Vector2(4.5, 32.9);
					sprite.flip_h = true;
					$hand.flip_h = true;
					$hand.position = Vector2(15.132, -1.021);
					$collision.set_polygon(flipped_collision_array);
				else:
					$weapon/Sprite.flip_v = false;
					$dust.position = Vector2(-4.6, 32.9);
					sprite.flip_h = false;
					$hand.flip_h = false;
					$hand.position = Vector2(-15.991, -0.859);
					$collision.set_polygon(collision_array);
				weapon_adjust();
			if knockedback:
# warning-ignore:return_value_discarded
				move_and_collide(knockback_dir*speed*delta);
			if STATE == "RUN":
				$hand.position += Vector2(0, 1);

func weapon_adjust():
	if($weapon/Sprite.is_flipped_v()):
		$weapon/Sprite.position = Vector2(global.weapon_x[type].x, -global.weapon_x[type].y);
		$weapon/collision.position = Vector2(global.weapon_x[type].x, -global.weapon_x[type].y);
	elif(!$weapon/Sprite.is_flipped_v()):
		$weapon/Sprite.position = global.weapon_x[type];
		$weapon/collision.position = global.weapon_x[type];

func _on_character_animation_finished():
	if sprite.get_animation() == "death":
		$collision.disabled = true;
		hide();
		set_physics_process(false);
		set_process_input(false);
		emit_signal("player_has_fallen");
	elif sprite.get_animation() == "test":
		sprite.play("smash");
	elif sprite.get_animation() == "smash":
		var d = dust.instance();
		$ability_nodes_container.add_child(d);
		d.global_position = shield_pos;
		d.set_texture(dust_texture);
		d.emitting = true;
		emit_signal("screen_shake_requested", 15, 17, 0.5);
		shield.show();
		shield.global_position = shield_pos;
		shield.get_node("collision").set_deferred("disabled", false);
		shield_sprite.play("sprout");
		shield_sprite.set_frame(0);
		if sprite.flip_h:
			shield_sprite.flip_h = true;
			shield.get_node("collision").position = Vector2(-32.7, 10.8);
		else:
			shield_sprite.flip_h = false;
			shield.get_node("collision").position = Vector2(35.3, 10.8);
		sprite.play("rise_up");
	elif sprite.get_animation() == "rise_up":
		weapon.show();
		set_physics_process(true);
		set_process_input(true);
		$hand.show();
	elif sprite.get_animation() == "chuck_rock":
		sprite.play("chuck_rock_2");
		var crater = Sprite.new();
		crater.set_texture(crater_texture);
		crater.z_index = -50;
		crater.z_as_relative = false;
		crater.scale = Vector2(3, 3);
		if pixelstan.current_room != null:
			for enemy in pixelstan.current_room.enemy_container.get_children():
				var dis = enemy.global_position.distance_to(global_position);
				if dis <= 250 and not global.flying_enemy.has(enemy.enemy):
					enemy.damage(5, "KNOCKUP", Vector2(), 0.5);
		if sprite.flip_h:
			crater.global_position = global_position + Vector2(18.6, 40.6);
		else:
			crater.global_position = global_position + Vector2(-18.6, 40.6);
		$ability_nodes_container.add_child(crater);
		var d = dust.instance();
		d.set_texture(dust_texture);
		d.global_position = crater.global_position;
		d.emitting = true;
		$ability_nodes_container.add_child(d);
		emit_signal("screen_shake_requested", 20, 30, 0.2);
	elif sprite.get_animation() == "chuck_rock_2":
		sprite.play("chuck_end");
		throwable.global_rotation = 0;
		if sprite.flip_h:
			throwable.global_position = global_position + Vector2(10, -45);
		else:
			throwable.global_position = global_position + Vector2(-10, -45);
		throwable.show();
		throwable.initiate(throwable.global_position, throw);
		throwable_sprite.play("rock_fly");
	elif sprite.get_animation() == "chuck_shield":
		sprite.play("chuck_end");
		throwable.global_rotation = 0;
		if sprite.flip_h:
			throwable.global_position = global_position + Vector2(10, -45);
		else:
			throwable.global_position = global_position + Vector2(-10, -45);
		throwable.show();
		throwable.initiate(throwable.global_position, get_global_mouse_position());
		var shield_debris = Sprite.new();
		shield_debris.set_texture(shield_debris_texture);
		if sprite.flip_h:
			shield_debris.global_position = global_position + Vector2(-36.5, 29);
			shield_debris.flip_h = true;
		else:
			shield_debris.global_position = global_position + Vector2(37, 29);
		$ability_nodes_container.add_child(shield_debris);
		throwable_sprite.play("shield_fly");
	elif sprite.get_animation() == "chuck_end":
		$hand.show();
		weapon.show();
		set_process_input(true);
		set_physics_process(true);

func damage(amount, k_dir, k_duration, d_type, d_amount, d_duration):#shake_frequency, shake_amplitude, shake_duration):
	emit_signal("screen_shake_requested", 12, 10, 0.2);
	if health < max_health/2:
		emit_signal("blood_requested");
	knockback(k_dir, k_duration);
	apply_debuff(d_type, d_amount, d_duration);
	if alive:
		health -= amount * 100 / (100+armor); 

# warning-ignore:shadowed_variable
func apply_debuff(type, amount, duration):
	match(type):
		"armor_reduction":
			armor = armor * (1-amount);
		"slow":
			max_speed *= (1 - amount);
			min_speed *= (1 - amount);
		"poison":
			pass#reduce health continually for duration
		"none":
			return;
	#debuff label
	var l = notifier.instance();
	add_child(l);
	l.initialize(Vector2(-2.9, -44.2));
	l.set_info(type);
	debuff_type = type;
	debuff_amount = amount;
	debuff_timer.start(duration);

func _on_debuff_timer_timeout():
	match(debuff_type):
		"armor_reduction":
			armor = armor * (1/(1 - debuff_amount));
		"slow":
			max_speed *=(1/(1 - debuff_amount));
			min_speed *=(1/(1 - debuff_amount));
		"poison":
			pass#halt poison timer

func knockback(k_dir, k_duration):
	can_move = false;
	can_shoot = false;
	can_flip = false;
	knockedback = true;
	knockback_dir = k_dir;
	set_collision_mask_bit(3, false);
	cc_timer.start(k_duration);

func _on_combination_timer_timeout():
	set_process_input(true);
	weapon.type_assign(type);
	$combination_particles.emitting = false;
	can_shoot = true;
	$weapon_label.set_text(global.weapon_name[type]);
	$weapon_label.show();
	yield(get_tree().create_timer(1), "timeout");
	$weapon_label.hide();

func complete_combine():
	set_process_input(false);
	$combination_particles/combination_timer.start();
	$combination_particles.emitting = true;
	can_shoot = false;

func cant_be_combined():
	$weapon_label.set_text("Cannot be combined!");
	$weapon_label.show();
	yield(get_tree().create_timer(0.5), "timeout");
	$weapon_label.hide();

func _on_cc_timer_timeout():
	set_collision_mask_bit(3, true);
	knockedback = false;
	can_move = true;
	can_flip = true;
	can_shoot = true;
	STATE = 'IDLE';

func _on_scent_timer_timeout():
	$scent_timeout_timer.paused = false;
	scent_array.append(global_position);

func _on_scent_timeout_timer_timeout():
	scent_array.remove(0);

func save():
	var save_dict = {
		"name": get_name(),
		"health" : health
	};
	return save_dict;
