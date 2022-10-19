extends Control

var element = preload("res://scenes//archive_element.tscn");

var enemy_array := {"vodok": false,
					"lloyd": false,
					"badhril": false,
					"bryn": false,
					"slugpine": false,
					"gabhrain": false,
					"gondurr": false,
					"hordor": false,
					"corth": false};

var boss_array := {};

var realm_array := {};

var weapons_array := {"pistol": false,
					  "shotgun": false,
					  "machine_gun": false,
					  "gatling_gun": false,
					  "musket": false};

func _on_enemies_pressed():
	$GridContainer/enemies/exclamation.hide();
	$GridContainer.hide();
	$HBoxContainer/ScrollContainer/GridContainer.get_children().clear();
	for enemy in enemy_array.keys():
		var s = element.instance();
		s.type = 'enemy';
		s.string = enemy;
		s.rect_min_size = Vector2(140, 160);
		s.get_child(0).rect_min_size = Vector2(110, 140);
		s.get_child(0).rect_position = Vector2(15, 10);
		s.get_child(0).texture_normal = load("res://art/enemies/" + enemy + "/idle/1.png");
		if not enemy_array[enemy]: s.get_child(0).modulate = Color(0, 0, 0);
		$HBoxContainer/ScrollContainer/GridContainer.add_child(s);
	$HBoxContainer.show();

func _on_armory_pressed():
	$GridContainer/armory/exclamation.hide();
	$GridContainer.hide();
	$HBoxContainer.show();
	for weapon in weapons_array.keys():
		var s = element.instance();
		s.type = 'weapon';
		s.string = weapon;
		s.rect_min_size = Vector2(160, 100);
		s.get_child(0).rect_min_size = Vector2(140, 80);
		s.get_child(0).rect_position = Vector2(10, 10);
		s.get_child(0).texture_normal = load("res://art/weapons/" + weapon + ".png");
		if not weapons_array[weapon]: s.get_child(0).modulate = Color(0, 0, 0);
		$HBoxContainer/ScrollContainer/GridContainer.add_child(s);

func _on_bosses_pressed():
	$GridContainer/bosses/exclamation.hide();
	$GridContainer.hide();
	var i = 0;
	for boss in boss_array.keys():
		var e = element.instance();
		var sf = SpriteFrames.new();
		sf.add_animation("idle");
		var j = 0;
		for i in range(enemy_array[i]):
			var texture = load("res://art/enemies/" + boss + "/idle/" + i + ".png");
			sf.add_frame("idle", texture, j);
			j += 1;
		i += 1; 
		e.get_child(0).set_sprite_frames(sf);
		e.get_child(1).set_text(boss);
		e.get_child(2).queue_free();

func _on_levels_pressed():
	$GridContainer/levels/exclamation.hide();
	$GridContainer.hide();
	for realm in realm_array:
		var e = element.instance();
		e.get_child(3).set_texture(load("res://art/realm_pictures/" + realm + ".png"));
		e.get_child(1).set_text(realm);
		e.get_child(0).queue_free();

func _on_back_button_pressed():
	if $GridContainer.visible:
		$GridContainer.hide();
		$back_button.hide();
		$panel.play("close");
	elif $HBoxContainer.visible:
		for child in $HBoxContainer/ScrollContainer/GridContainer.get_children():
			child.queue_free();
		$HBoxContainer/Panel/VBoxContainer/Sprite.hide();
		$HBoxContainer/Panel/VBoxContainer/Info.set_text("");
		for child in $HBoxContainer/Panel/VBoxContainer/GridContainer.get_children():
			child.set_text("");
		$HBoxContainer.hide();
		$GridContainer.show();

func _on_AnimatedSprite_animation_finished():
	if $panel.get_animation() == "open":
		$GridContainer.show();
		$back_button.show();
	if $panel.get_animation() == "close":
		hide();

func save():
	var save_dict = {
		"name": get_name(),
		"weapons_array": weapons_array,
		"enemy_array": enemy_array
	};
	return save_dict;
