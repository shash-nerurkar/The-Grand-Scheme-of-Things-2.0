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
#var ability_1_sound = preload();
#var ability_2_sound = preload();

onready var sprite = $character;
onready var weapon = $weapon;
onready var cc_timer = $cc_timer;
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
var speed = 200;
var min_speed = 200;
var max_speed = 250;
var armor = 25;
var velocity = Vector2();
var type = "shotgun";
var STATE := "IDLE";
var is_shopping := false;
var rot;
var alive := true;
var once := true;
var scent_array := [];
var knockedback := false;
var knockback_dir := Vector2();
var can_move := true;
var can_flip := true;
var can_shoot := true;

# warning-ignore:unused_argument
func initialize(biome):
	pass

func _ready():
	a1_timer.set_wait_time(a1_cooldown);
	a2_timer.set_wait_time(a2_cooldown);
	$scent_timeout_timer.paused = true;
	collision_array = $collision.get_polygon();
	global.weapon_in_hand = type;
	weapon.type_assign(type);
	weapon.ammo_assign(type);
	$weapon/collision.set_deferred("disabled", true);
	set_physics_process(true);

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
	if event.is_action_pressed("player_ability_2") and a2_timer.is_stopped():
		a2_timer.start();
	if event.is_action_pressed("backdoor"):
		position = pixelstan.end_room.position;

# warning-ignore:unused_argument
func _physics_process(delta):
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
				else:
					$dust.emitting = false;
					sprite.play("idle");
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
				rot = get_angle_to(get_global_mouse_position());
				if rot>1.57 or rot<-1.57:
					sprite.flip_h = true;
					$dust.position = Vector2(-4.2, 20.6);
					$weapon/Sprite.flip_v = true;
					$collision.set_polygon(flipped_collision_array);
				else:
					sprite.flip_h = false;
					$dust.position = Vector2(3.0, 20.3);
					$weapon/Sprite.flip_v = false;
					$collision.set_polygon(collision_array);
				weapon.rotation = rot;
				weapon_adjust();
			if knockedback:
# warning-ignore:return_value_discarded
				move_and_collide(knockback_dir*speed*delta);

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

func damage(amount, k_dir, k_duration, d_type, d_amount, d_duration):#shake_frequency, shake_amplitude, shake_duration):
	emit_signal("screen_shake_requested", 12, 10, 0.2);#0, 1, 1);
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
	l.initialize(Vector2(1.5, -29.6));
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
	knockedback = false;
	can_move = true;
	can_flip = true;
	can_shoot = true;
	set_collision_mask_bit(3, true);
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
