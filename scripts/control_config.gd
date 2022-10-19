extends Control

var are_all_valid := true;

var control_names := {'player_up':        "Move up",
					  'player_left':      "Move left",
					  'player_down':      "Move down",
					  'player_right':     "Move right",
					  'player_interact':  "Interact /Pickup",
					  'player_ability':   "Ability 1",
					  'player_ability_2': "Ability 2",
					  'weapon_combine':   "Weapon Combine"};

var actions := {'Move up':          "player_up",
				'Move left':        "player_left",
				'Move down':        "player_down",
				'Move right':       "player_right",
				'Interact /Pickup': "player_interact",
				'Ability 1':        "player_ability",
				'Ability 2':        "player_ability_2",
				'Weapon Combine':   "weapon_combine"};

var default_profile = {
	'player_up': KEY_W,
	'player_left': KEY_A,
	'player_down': KEY_S,
	'player_right': KEY_D,
	'player_interact': KEY_TAB,
	'player_ability': KEY_Q,
	'player_ability_2': KEY_E,
	'weapon_combine': KEY_R};

func _on_InputMapper_init(input_profile):
	for input_action in input_profile.keys():
		var line = $VBoxContainer/Column/Scrollable/ActionList.add_input_line(control_names[input_action], input_profile[input_action]);
		line.connect('change_button_pressed', self, '_on_InputLine_change_button_pressed', [input_action, line]);

func _on_InputLine_change_button_pressed(action_name, line):
	set_process_input(false);
	$KeySelection.open();
	var key_scancode = yield($KeySelection, "key_selected");
	for l in $VBoxContainer/Column/Scrollable/ActionList.get_children():
		if OS.get_scancode_string(key_scancode) == l.fetch_key():
			l.update_key(KEY_ASCIITILDE);
			$InputMapper.change_action_key(actions[l.fetch_control_name()], $InputMapper.profile_custom[actions[line.fetch_control_name()]]);
	$InputMapper.change_action_key(action_name, key_scancode);
	line.update_key(key_scancode);
	set_process_input(true);

func _input(event):
	for child in $VBoxContainer/Column/Scrollable/ActionList.get_children():
		if !child.valid:
			are_all_valid = false;
			break;
		else:
			are_all_valid = true;
	if event.is_action_pressed("ui_cancel"):
		if are_all_valid:
			hide();
		else:
			$VBoxContainer/warning.modulate.a = 255;

func _on_restore_default_pressed():
	var keys := [KEY_W, KEY_A, KEY_S, KEY_D, KEY_TAB, KEY_Q, KEY_E, KEY_R];
	var i = 0;
	for l in $VBoxContainer/Column/Scrollable/ActionList.get_children():
		l.update_key(keys[i]);
		i += 1;
	for action in default_profile.keys():
		$InputMapper.change_action_key(action, default_profile[action]);

func _on_back_button_pressed():
	for child in $VBoxContainer/Column/Scrollable/ActionList.get_children():
		if !child.valid:
			are_all_valid = false;
			break;
		else:
			are_all_valid = true;
	if are_all_valid:
		$VBoxContainer/warning.modulate.a = 0;
		hide();
		$"../pause_panel".show();
	else:
		$VBoxContainer/warning.modulate.a = 255;
