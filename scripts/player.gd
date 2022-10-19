extends KinematicBody2D

signal screen_shake_requested
signal blood_requested
signal weapon_pickup
signal display_pickup
signal display_out_of_ammo
signal zoom_in
signal zoom_out
signal player_has_fallen

var notifier = preload("res://scenes/notifier.tscn");

onready var sprite = $character;
onready var gun = $weapon;
onready var cc_timer = $cc_timer;

var flipped_collision_array := [Vector2(1.153, -19.406), Vector2(15.324, -11.565),
								Vector2(15.229, 2.038), Vector2(10.832, 6.114),
								Vector2(2.948, 19.987), Vector2(-9.238, 19.987),
								Vector2(-15.053, 13.902), Vector2(-14.151, -13.454),
								Vector2(-9.71, -19.122)];
var collision_array := [];
var speed = 1050;
var velocity = Vector2();
var type = "shotgun";
var STATE := "IDLE";
var is_shopping := false;
var health := 2000;
var rot;
var alive := true;
var once := true;
var scent_array := [];
var knockedback := false;
var knockback_dir := Vector2();
var can_move := true;
var can_flip := true;
var can_shoot := true;

func _ready():
	$scent_timeout_timer.paused = true;
	collision_array = $collision.get_polygon();
	global.weapon_in_hand = type;
	gun.type_assign(type);
	gun.ammo_assign(type);
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
			gun.type_assign(type);
			emit_signal("display_pickup", global.weapon_name[type]);
			global.weapon_in_hand = type;
	if event.is_action_pressed("player_ability"):
		pass
	if event.is_action_pressed("player_ability_2"):
		pass
	if event.is_action_pressed("backdoor"):
		position = $"..".end_room.position - $"..".end_room.size;

# warning-ignore:unused_argument
func _physics_process(delta):
	velocity = Vector2();
	if alive:
		if health<=0:
			alive = false;
			health = 0;
			gun.hide();
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
					if get_angle_to(get_global_mouse_position())>1.57 or get_angle_to(get_global_mouse_position())<-1.57:
						if velocity.x == 1:
							sprite.play("run", true);
						else:
							sprite.play("run");
					else:
						if velocity.x == 1:
							sprite.play("run");
						else:
							sprite.play("run", true);
				else:
					sprite.play("idle");
				velocity = velocity*speed;
				if velocity != Vector2(0, 0):
					speed += 3;
				else:
					speed = 1050;
				speed = clamp(speed, 1050, 1050);
			# warning-ignore:return_value_discarded
				move_and_slide(velocity);
			if can_shoot:
				if(Input.is_action_pressed("player_shoot")):
					if STATE == "IDLE":
						sprite.stop();
					if($weapon/bullet_cooldown.get_time_left() == 0 and gun.ammo > 0):
						gun.shoot();
					elif gun.ammo <= 0:
						gun.ammo = 0;
						emit_signal("display_out_of_ammo");
			if can_flip:
				rot = get_angle_to(get_global_mouse_position());
				if rot>1.57 or rot<-1.57:
					sprite.flip_h = true;
					$weapon/Sprite.flip_v = true;
					$collision.set_polygon(flipped_collision_array);
				else:
					sprite.flip_h = false;
					$weapon/Sprite.flip_v = false;
					$collision.set_polygon(collision_array);
				gun.rotation = rot;
				gun_adjust();
			if knockedback:
# warning-ignore:return_value_discarded
				move_and_collide(knockback_dir*speed*delta);

func gun_adjust():
	if($weapon/Sprite.is_flipped_v()):
		$weapon/Sprite.position = Vector2(global.weapon_x[type].x, -global.weapon_x[type].y);
		$weapon/collision.position = Vector2(global.weapon_x[type].x, -global.weapon_x[type].y);
	elif(!$weapon/Sprite.is_flipped_v()):
		$weapon/Sprite.position = global.weapon_x[type];
		$weapon/collision.position = global.weapon_x[type];

func damage(amount):
	emit_signal("screen_shake_requested", 12, 10, 0.2);#0, 1, 1);
	#if health < global.health[global.level]/2:
	emit_signal("blood_requested");
	if alive:
		health -= amount;

func _on_character_animation_finished():
	if sprite.get_animation() == "death":
		$collision.disabled = true;
		hide();
		set_physics_process(false);
		set_process_input(false);
		emit_signal("player_has_fallen");

func save():
	var save_dict = {
		"name": get_name(),
		"health" : health
	};
	return save_dict;

func _on_scent_timer_timeout():
	$scent_timeout_timer.paused = false;
	scent_array.append(global_position);

func _on_scent_timeout_timer_timeout():
	scent_array.remove(0);

func knockback(k_damage, k_dir, k_duration):#shake_frequency, shake_amplitude, shake_duration):
	can_move = false;
	can_shoot = false;
	can_flip = false;
	knockedback = true;
	knockback_dir = k_dir;
	cc_timer.start(k_duration);
	damage(k_damage);#shake_frequency, shake_amplitude, shake_duration);

func _on_cc_timer_timeout():
	knockedback = false;
	can_move = true;
	can_flip = true;
	can_shoot = true;
	STATE = 'IDLE';
