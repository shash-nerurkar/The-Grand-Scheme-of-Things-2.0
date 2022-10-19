extends CanvasLayer

var mini = preload("res://scenes/minimap_room.tscn");
var notifier = preload("res://scenes/notifier.tscn");

signal leave_shop

onready var health_bar = $player_hp;
onready var pause_panel = $pause_panel;
onready var blood_container = $blood_container;
onready var loading_bar = $trans/loading_text/loading_bar;
onready var minimap = $minimap;
onready var minimap_name = $minimap_label;
onready var corridor_container = $corridor_container;
onready var minimap_label = $minimap_label;
onready var pixelstan = $"..";
onready var a1_indicator = $ability_1_indicator;
onready var a2_indicator = $ability_2_indicator;
onready var archive = $archive;
onready var transition = $trans;
onready var tip = $trans/loading_text/tip;
onready var shop_panel = $shop_panel;

var is_paused = false;
var conversion_const := 0.0;
var player;
var enemy_array := [];
var offs;
var wave_number = 1;
var is_zooming_out := false;
var corridor_positions := [];

func _ready():
	OS.window_fullscreen = true;
	set_process(false);

func initialize(biome):
	shop_panel.get("custom_styles/panel").set_texture(load("res://art/shopkeeper/" + biome + "/panel.png"));
	tip.set_text(global.biome_tip[biome][randi()%global.biome_tip[biome].size()]);
	a1_indicator.max_value = player.a1_cooldown;
	a2_indicator.max_value = player.a2_cooldown;

func _input(event):
	if event.is_action_pressed("pause_toggle"):
		is_paused = not is_paused;
		get_tree().set_pause(is_paused);
		pause_panel.set_visible(is_paused);

# warning-ignore:unused_argument
func _process(delta):
	loading_bar.set_value(loading_bar.max_value - $"../loading".time_left);

func clear_minimap():
	for miniroom in minimap.get_children():
		miniroom.queue_free();
	for minicorr in corridor_container.get_children():
		minicorr.queue_free();
	corridor_positions.clear();

func draw_minimap(rect_size, room_pos, room_sizes, biome):
	minimap.rect_size = rect_size/40;
	minimap.rect_position = Vector2(1024, 600) - (rect_size/40 + rect_size/1000);
	minimap_name.text = global.biome_name[biome];
	minimap_name.rect_position = Vector2(1024, 600) - Vector2(rect_size.x/80 + rect_size.x/2000, rect_size.y/40 + rect_size.y/1000) - Vector2(110, -3);
	for i in room_pos.size():
		var m = mini.instance();
		minimap.add_child(m);
		m.rect_size = (global.room_size[room_sizes[i]]*pixelstan.unit + Vector2(pixelstan.min_size, pixelstan.min_size))*pixelstan.tile_size/25;  
		m.hide();
		m.rect_position = room_pos[i]/50 - m.rect_size/2 + minimap.rect_size/2;
	var p = preload("res://scenes/minimap_player.tscn").instance();
	minimap.add_child(p);
	minimap.get_child(pixelstan.room_container.get_children().find(pixelstan.start_room)).show();

func draw_minimap_corridors(rect_size, pos):
	var m = mini.instance();
	corridor_container.add_child(m);
	m.rect_size = Vector2(pixelstan.tile_size/25, pixelstan.tile_size/25);  
	m.modulate.a = 0;
	m.rect_position = pos/50 - m.rect_size/2 + rect_size/80 + minimap.rect_position; 
	corridor_positions.append(m.rect_position);

func show_minimap_corridor(rect_size, pos):
	var mini_pos = pos/50 - Vector2(pixelstan.tile_size/50, pixelstan.tile_size/50) + rect_size/80 + minimap.rect_position;
	if corridor_positions.find(mini_pos) != -1:
		corridor_container.get_child(corridor_positions.find(mini_pos)).modulate.a = 1;
	else:
		var m = mini.instance();
		corridor_container.add_child(m);
		m.rect_size = Vector2(pixelstan.tile_size/25, pixelstan.tile_size/25);  
		m.rect_position = pos/50 - m.rect_size/2 + rect_size/80 + minimap.rect_position; 
		corridor_positions.append(m.rect_position);

# warning-ignore:shadowed_variable
func update(player, gold_amount):
	health_bar.set_value(player.health);
	$ammo/Label.set_text(String(player.weapon.ammo));
	$gold/Label.set_text(String(gold_amount));
	a1_indicator.value = player.a1_timer.time_left;
	a2_indicator.value = player.a2_timer.time_left;

func _on_player_blood_requested():
	var blood = preload("res://scenes/blood.tscn").instance();
	blood_container.add_child(blood);
	if blood_container.get_child_count() <= 4:
		blood.flash_screen(blood_container.get_child_count()*0.15);
	else:
		blood.queue_free();

func _on_player_hide_pickup():
	$pickup_frame.hide_pickup_notifier();

func _on_player_display_out_of_ammo():
	if $ammo/Label/Timer.get_time_left() <= 0.1:
		$ammo/Label/AnimationPlayer.play("label mod");
		$ammo/Label/Timer.start();

func _on_shopkeeper_start_interact_notifier():
	$interact_notifier/Label.set_text(OS.get_scancode_string($control_config/InputMapper.profile_custom['player_interact']));
	$interact_notifier.set_text(" Interact");
	$interact_notifier.show();
	$interact_notifier/AnimationPlayer.play("blink");

func _on_shopkeeper_stop_interact_notifier():
	$interact_notifier.hide();

func _on_weapon_start_interact_notifier(weapon_string):
	$interact_notifier/Label.set_text(OS.get_scancode_string($control_config/InputMapper.profile_custom['player_interact']));
	$interact_notifier.set_text(" Pickup");
	$interact_notifier.show();
	$interact_notifier/AnimationPlayer.play("blink");
	$pickup_frame.show_pickup_notifier(weapon_string);
	if global.is_combo.has(player.type) and global.is_combo.has(weapon_string):
		return;
	elif global.is_combo.has(player.type):
		var key;
		if weapon_string == global.revert_weapon[player.type][0] or weapon_string == global.revert_weapon[player.type][1]:
			return;
		if global.tier_combo[global.weapon_tier[weapon_string]].has(global.weapon_tier[global.revert_weapon[player.type][0]]):
			if global.weapon_tier[weapon_string] > global.weapon_tier[global.revert_weapon[player.type][0]]:
				key = [weapon_string, global.revert_weapon[player.type][0]];
			else:
				key = [global.revert_weapon[player.type][0], weapon_string];
			$combination_info/weapon_combo_panel/GridContainer/Destroyed.set_texture(load("res://art/weapons/" + global.revert_weapon[player.type][1] + ".png"));
			$combination_info/weapon_combo_panel/GridContainer/Consumed.set_texture(load("res://art/weapons/" + global.revert_weapon[player.type][0] + ".png"));
		else:
			if global.weapon_tier[weapon_string] > global.weapon_tier[global.revert_weapon[player.type][1]]:
				key = [weapon_string, global.revert_weapon[player.type][1]];
			else:
				key = [global.revert_weapon[player.type][1], weapon_string];
			$combination_info/weapon_combo_panel/GridContainer/Destroyed.set_texture(load("res://art/weapons/" + global.revert_weapon[player.type][0] + ".png"));
			$combination_info/weapon_combo_panel/GridContainer/Consumed.set_texture(load("res://art/weapons/" + global.revert_weapon[player.type][1] + ".png"));
		$combination_info/weapon_combo_panel/GridContainer/Current.set_texture(load("res://art/weapons/" + player.type + ".png"));
		$combination_info/weapon_combo_panel/GridContainer/Current_floor.set_texture(load("res://art/weapons/" + weapon_string + ".png"));
		$combination_info/weapon_combo_panel/GridContainer/After.set_texture(load("res://art/weapons/" + global.prod_weapon[key] + ".png"));
		if not $archive.weapons_array[global.prod_weapon[key]]:
			archive_popup('weapon');
			$archive.weapons_array[global.prod_weapon[key]] = true;
		$combination_info.show();
	elif global.is_combo.has(weapon_string):
		var key;
		if player.type == global.revert_weapon[weapon_string][0] or player.type == global.revert_weapon[weapon_string][1]:
			return;
		if global.tier_combo[global.weapon_tier[player.type]].has(global.weapon_tier[global.revert_weapon[weapon_string][0]]):
			if global.weapon_tier[player.type] > global.weapon_tier[global.revert_weapon[weapon_string][0]]:
				key = [player.type, global.revert_weapon[weapon_string][0]];
			else:
				key = [global.revert_weapon[weapon_string][0], player.type];
			$combination_info/weapon_combo_panel/GridContainer/Destroyed.set_texture(load("res://art/weapons/" + global.revert_weapon[weapon_string][1] + ".png"));
			$combination_info/weapon_combo_panel/GridContainer/Consumed.set_texture(load("res://art/weapons/" + global.revert_weapon[weapon_string][0] + ".png"));
		else:
			if global.weapon_tier[player.type] > global.weapon_tier[global.revert_weapon[weapon_string][1]]:
				key = [player.type, global.revert_weapon[weapon_string][1]];
			else:
				key = [global.revert_weapon[weapon_string][1], player.type];
			$combination_info/weapon_combo_panel/GridContainer/Destroyed.set_texture(load("res://art/weapons/" + global.revert_weapon[weapon_string][0] + ".png"));
			$combination_info/weapon_combo_panel/GridContainer/Consumed.set_texture(load("res://art/weapons/" + global.revert_weapon[weapon_string][1] + ".png"));
		$combination_info/weapon_combo_panel/GridContainer/Current.set_texture(load("res://art/weapons/" + player.type + ".png"));
		$combination_info/weapon_combo_panel/GridContainer/Current_floor.set_texture(load("res://art/weapons/" + weapon_string + ".png"));
		$combination_info/weapon_combo_panel/GridContainer/After.set_texture(load("res://art/weapons/" + global.prod_weapon[key] + ".png"));
		if not $archive.weapons_array[global.prod_weapon[key]]:
			archive_popup('weapon');
			$archive.weapons_array[global.prod_weapon[key]] = true;
		$combination_info.show();
	else:
		if global.tier_combo[global.weapon_tier[player.type]].has(global.weapon_tier[weapon_string]):
			var key;
			if global.weapon_tier[player.type] > global.weapon_tier[weapon_string]:
				key = [player.type, weapon_string];
			else:
				key = [weapon_string, player.type];
			$combination_info/weapon_combo_panel/GridContainer/Current.set_texture(load("res://art/weapons/" + player.type + ".png"));
			$combination_info/weapon_combo_panel/GridContainer/Current_floor.set_texture(load("res://art/weapons/" + weapon_string + ".png"));
			$combination_info/weapon_combo_panel/GridContainer/After.set_texture(load("res://art/weapons/" + global.prod_weapon[key] + ".png"));
			if not $archive.weapons_array[global.prod_weapon[key]]:
				archive_popup('weapon');
				$archive.weapons_array[global.prod_weapon[key]] = true;
			$combination_info/weapon_combo_panel/GridContainer/Destroyed.set_texture(null);
			$combination_info.show();
		else:
			return;

func _on_stop_interact_notifier():
	$pickup_frame.hide_pickup_notifier();
	$interact_notifier.hide();
	$combination_info.hide();
	$combination_info/weapon_combo_panel.hide();

func _on_combination_info_toggled(button_pressed):
# warning-ignore:standalone_ternary
	$combination_info/weapon_combo_panel.show() if button_pressed else $combination_info/weapon_combo_panel.hide();

func _on_control_config_pressed():
	$control_config.show();
	pause_panel.hide();

func _on_sound_settings_pressed():
	$sound_settings.show();
	pause_panel.hide();

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "blur":
		$blur.hide();
		setup_shop_panel();

func _on_back_button_pressed():
	player.set_process_input(true);
	$shop_panel.hide();
	$textbox.show();
	$blur/AnimationPlayer.play("blur_out");
	$textbox/Label.set_text("FRAN: Anything else?");

func _on_yes_pressed():
	player.set_process_input(false);
	$textbox.hide();
	$blur.show();
	$blur/AnimationPlayer.play("blur");

func _on_no_pressed():
	if is_zooming_out:
		is_zooming_out = false;
	else:
		$textbox.hide();
		emit_signal("leave_shop");
		is_zooming_out = true;

func enter_shop():
	$textbox.visible = true;
	$textbox/Label.set_text("FRAN: Name your price.");
	$minimap.hide();
	$minimap_label.hide();
	for minicorr in $corridor_container.get_children():
		minicorr.hide();
	$player_hp.hide();
	$ammo.hide();
	$interact_notifier.hide();
	a1_indicator.hide();
	a2_indicator.hide();

func leave_shop():
	$textbox.visible = false;
	$minimap.show();
	$minimap_label.show();
	for minicorr in $corridor_container.get_children():
		minicorr.show();
	$player_hp.show();
	$ammo.show();
	$interact_notifier.hide();
	a1_indicator.show();
	a2_indicator.show();

func setup_shop_panel():
	$shop_panel.show();
	var i = 1;
	for wpn in ["gatling_gun", "m4a1", "shotgun", "musket", "pistol", "machine_gun"]:
		var button = get_node("shop_panel/VBoxContainer/GridContainer/item" + String(i));
		button.texture_normal = load("res://art/weapons/display/%s.png" % wpn);
		button.texture_hover = load("res://art/weapons/display/%s"% wpn + "_on_hover.png");
		button.texture_pressed = load("res://art/weapons/display/%s"% wpn + "_on_click.png");
		i += 1;

func show_end_game_panel():
	var dir = Directory.new();
	dir.remove("user://savegame.save");
	$end_game.show();

func _on_exit_pressed():
	$"..".savegame();
	get_tree().quit();

func show_notifier(text, mod):
	var n = notifier.instance();
	add_child(n);
	n.set_text(text);
	n.get("custom_fonts/font").set_size(56);
	n.modulate = mod;
	n.rect_position = Vector2(512, 300) - n.rect_size/2;
	n.get_node("Timer").start(1);

func _on_archive_pressed():
	$archive.show();
	$archive/panel.play("open");

func _on_archive_popup_pressed():
	is_paused = not is_paused;
	get_tree().set_pause(is_paused);
	pause_panel.set_visible(is_paused);
	$archive_popup.hide();
	$archive.show();
	$archive/panel.play("open");

func archive_popup(type):
	$archive_popup.show();
	$archive_popup/AnimationPlayer.play("archive_popup_blink");
	match type:
		'enemy':
			$archive/GridContainer/enemies/exclamation.show();
		'weapon':
			$archive/GridContainer/armory/exclamation.show();

func _on_back_pressed():
	is_paused = not is_paused;
	get_tree().set_pause(is_paused);
	pause_panel.set_visible(is_paused);

func on_room_activation(room):
	minimap.hide();
	for minicorr in corridor_container.get_children():
		minicorr.hide();
	minimap_label.hide();
	minimap.get_child(pixelstan.room_container.get_children().find(room)).show();

func on_room_cleared(room):
	minimap.show();
	for minicorr in corridor_container.get_children():
		minicorr.show();
	minimap_label.show();
	minimap.get_child(pixelstan.room_container.get_children().find(room)).modulate = Color(0, 0.5, 0.5);
	show_notifier("ROOM CLEARED", Color(0, 1, 0));
	var room_positions := [];                                                   #CONVERTING COORDINATES INTO VECTOR2 BCOZ JSON SUCKS
	for i in pixelstan.room_pos_x.size():
		room_positions.append(Vector2(pixelstan.room_pos_x[i], pixelstan.room_pos_y[i]));
	var p = pixelstan.path.get_closest_point(room.position);
	for conn in pixelstan.path.get_point_connections(p):
		minimap.get_child(room_positions.find(pixelstan.path.get_point_position(conn))).show();
		var room2tpos;
		var room1tpos;
		if room_positions.find(room.position) < room_positions.find(pixelstan.path.get_point_position(conn)):
			room2tpos = $"../tiles".world_to_map(pixelstan.path.get_point_position(conn));
			room1tpos = $"../tiles".world_to_map(room.position);
		else:
			room2tpos = $"../tiles".world_to_map(room.position);
			room1tpos = $"../tiles".world_to_map(pixelstan.path.get_point_position(conn));
		for x in range(room1tpos.x, room2tpos.x, sign(room2tpos.x - room1tpos.x)):
			show_minimap_corridor(pixelstan.full_rect.size, $"../tiles".map_to_world(Vector2(x, room2tpos.y)));
		for y in range(room1tpos.y, room2tpos.y, sign(room2tpos.y - room1tpos.y)):            
			show_minimap_corridor(pixelstan.full_rect.size, $"../tiles".map_to_world(Vector2(room1tpos.x, y)));
