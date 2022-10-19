extends Area2D

signal pulse_timeout
signal start_interact_notifier
signal stop_interact_notifier
signal complete_combine
signal cant_be_combined

onready var bullet = preload("res://scenes/player_bullet.tscn");
onready var sparks = preload("res://scenes/weapon_sparks.tscn");

onready var weapon = $Sprite;
onready var bullet_cooldown = $bullet_cooldown;
onready var muzzle = $muzzle;
onready var collision = $collision;
onready var pulse_timer := $pulse;
onready var label = $name;
onready var pixelstan = $"../../../..";
onready var sound = $sound;

var weapon_string;
var body_on_top = null;
var dmg;
var crit_chance;
var did_it_crit := 0;
var inaccuracy;
var ammo := 0;
var player;
var disp_clause := true;
var sound_on_shoot;
var sound_on_pickup;
#var sound_on_combine;

func type_assign(type):
	sound_on_shoot = load("res://sounds/on_weapon_shoot/" + type + ".wav");
	sound_on_pickup = load("res://sounds/on_weapon_pickup/" + type + ".wav");
	weapon_string = type;
	$name.set_text(global.weapon_name[type]);
	var texture = load("res://art/weapons/" + type +  ".png");
	weapon.set_texture(texture);
	weapon.get_texture().set_flags(2);
	var shape = RectangleShape2D.new();
	shape.set_extents(Vector2(texture.get_width(), texture.get_height())/2);
	collision.set_shape(shape);
	muzzle.position = Vector2(global.weapon_muzzle_x[type], 0);
	weapon.position = global.weapon_x[type];
	$name.rect_position = Vector2(-197 + weapon.position.x, -40);
	collision.position = global.weapon_x[type];
	dmg = global.weapon_damage[type];
	crit_chance = global.weapon_crit[type];
	inaccuracy = global.weapon_accuracy[type];
	bullet_cooldown.set_wait_time(global.weapon_firerate[type]);

func ammo_assign(type):
	ammo = global.weapon_ammo[type] + (randi() % global.weapon_ammo[type]/4); 

func ammo_swap(a):
	ammo = a; 

func shoot():
	match weapon_string:
		"pistol":
			shoot_single();
		"machine_gun":
			shoot_single();
		"gatling_gun":
			shoot_single();
		"musket":
			shoot_single();
		"shotgun":
			shoot_cone();

func shoot_single():
	sound.set_stream(sound_on_shoot);
	sound.play();
	var s = sparks.instance();
	s.position = muzzle.position;
	add_child(s);
	s.emitting = true;
	weapon.global_rotation = global_rotation;
	bullet_cooldown.start();
	var b = bullet.instance();
	ammo -= 1;
	did_it_crit = randi() % 2;
	b.damage = dmg + did_it_crit*dmg;
	b.add_to_group(String(get_instance_id()) + "bullet");
	pixelstan.detail.add_child(b);
	var inaccuracy_amount = inaccuracy*(randf()-1);
	weapon.global_rotation += inaccuracy_amount;
	b.start_pos(rotation + inaccuracy_amount*2, muzzle.global_position);

func shoot_cone():
	sound.set_stream(sound_on_shoot);
	sound.play();
	var s = sparks.instance();
	s.position = muzzle.position;
	add_child(s);
	s.emitting = true;
	weapon.global_rotation = global_rotation;
	bullet_cooldown.start();
	ammo -= 1;
	for a in [-0.2, -0.1, 0, 0.1, 0.2]:
		var b = bullet.instance();
		did_it_crit = randi() % 2;
		b.damage = dmg + did_it_crit*dmg*0.5;
		b.add_to_group(String(get_instance_id()) + "bullet");
		pixelstan.detail.add_child(b);
		var inaccuracy_amount = inaccuracy*(randf()-1);
		weapon.global_rotation += inaccuracy_amount;
		b.start_pos(rotation + a + inaccuracy_amount*2, muzzle.global_position);

func on_pickup_signal():
	if body_on_top == "player":
		var temp = weapon_string;
		type_assign(player.type);
		var temp_ammo = ammo;
		ammo_swap(player.weapon.ammo);
		player.type = temp;
		player.weapon.type_assign(temp);
		player.weapon.ammo_swap(temp_ammo);
		global_position = player.global_position;
		disp_clause = false;
		$name.hide();
		player.get_node("weapon_label").set_text(global.weapon_name[player.type]);
		player.get_node("weapon_label").show();
		sound.set_stream(sound_on_pickup);
		sound.play();
		yield(get_tree().create_timer(1), "timeout");
		player.get_node("weapon_label").hide();

func on_combine_signal():
	if body_on_top == "player":
		if global.is_combo.has(player.type) and global.is_combo.has(weapon_string):
			emit_signal("cant_be_combined");
		elif global.is_combo.has(player.type):
			var key;
			if weapon_string == global.revert_weapon[player.type][0] or weapon_string == global.revert_weapon[player.type][1]:
				emit_signal("cant_be_combined");
				return;
			if global.tier_combo[global.weapon_tier[weapon_string]].has(global.weapon_tier[global.revert_weapon[player.type][0]]):
				if global.weapon_tier[weapon_string] > global.weapon_tier[global.revert_weapon[player.type][0]]:
					key = [weapon_string, global.revert_weapon[player.type][0]];
				else:
					key = [global.revert_weapon[player.type][0], weapon_string];
			else:
				if global.weapon_tier[weapon_string] > global.weapon_tier[global.revert_weapon[player.type][1]]:
					key = [weapon_string, global.revert_weapon[player.type][1]];
				else:
					key = [global.revert_weapon[player.type][1], weapon_string];
			player.type = global.prod_weapon[key];
			player.weapon.ammo_assign(global.prod_weapon[key]);
			emit_signal("complete_combine");
			queue_free();
		elif global.is_combo.has(weapon_string):
			var key;
			if player.type == global.revert_weapon[weapon_string][0] or player.type == global.revert_weapon[weapon_string][1]:
				emit_signal("cant_be_combined");
				return;
			if global.tier_combo[global.weapon_tier[player.type]].has(global.weapon_tier[global.revert_weapon[weapon_string][0]]):
				if global.weapon_tier[player.type] > global.weapon_tier[global.revert_weapon[weapon_string][0]]:
					key = [player.type, global.revert_weapon[weapon_string][0]];
				else:
					key = [global.revert_weapon[weapon_string][0], player.type];
			else:
				if global.weapon_tier[player.type] > global.weapon_tier[global.revert_weapon[weapon_string][1]]:
					key = [player.type, global.revert_weapon[weapon_string][1]];
				else:
					key = [global.revert_weapon[weapon_string][1], player.type];
			player.type = global.prod_weapon[key];
			player.weapon.ammo_assign(global.prod_weapon[key]);
			emit_signal("complete_combine");
			queue_free();
		else:
			if global.tier_combo[global.weapon_tier[player.type]].has(global.weapon_tier[weapon_string]):
				var key;
				if global.weapon_tier[player.type] > global.weapon_tier[weapon_string]:
					key = [player.type, weapon_string];
				else:
					key = [weapon_string, player.type];
				player.type = global.prod_weapon[key];
				player.weapon.ammo_assign(global.prod_weapon[key]);
				emit_signal("complete_combine");
				queue_free();
			else:
				emit_signal("cant_be_combined");

# warning-ignore:unused_argument
func _on_weapon_body_entered(body):
	if body.is_in_group("player"):
		body_on_top = "player";
		global.weapon_to_pickup = true;
		emit_signal("start_interact_notifier", weapon_string);
		if disp_clause:
			$name.show();
		disp_clause = true;

# warning-ignore:unused_argument
func _on_weapon_body_exited(body):
	if body.is_in_group("player"):
		body_on_top = null;
		global.weapon_to_pickup = false;
		emit_signal("stop_interact_notifier");
		$name.hide();

func emit_pulse_timeout():
	emit_signal("pulse_timeout");

func save():
	var save_dict = {
		"name": get_name(),
		"weapon_string" : weapon_string,
		"ammo" : ammo
	};
	return save_dict;

func set_all(json_var):
	$"..".type = json_var["weapon_string"];
	type_assign(json_var["weapon_string"]);
	ammo = json_var["ammo"];
