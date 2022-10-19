extends Node

signal init(new_profile)

onready var action_list = $"../VBoxContainer/Column/Scrollable/ActionList";

var profile_custom = {
	'player_up': KEY_W,
	'player_left': KEY_A,
	'player_down': KEY_S,
	'player_right': KEY_D,
	'player_interact': KEY_TAB,
	'player_ability': KEY_Q,
	'player_ability_2': KEY_E,
	'weapon_combine': KEY_R};

func _ready():
	emit_signal('init', profile_custom);

func change_action_key(action_name, key_scancode):
	erase_action_events(action_name);

	var new_event = InputEventKey.new();
	new_event.set_scancode(key_scancode);
	InputMap.action_add_event(action_name, new_event);
	profile_custom[action_name] = key_scancode;

func erase_action_events(action_name):
	var input_events = InputMap.get_action_list(action_name);
	for event in input_events:
		InputMap.action_erase_event(action_name, event);

func save():
	var save_dict = {
		"name": get_name(),
		"player_up": profile_custom['player_up'],
		"player_left": profile_custom['player_left'],
		"player_down": profile_custom['player_down'],
		"player_right": profile_custom['player_right'],
		"player_interact": profile_custom['player_interact'],
		'player_ability': profile_custom['player_ability'],
		'player_ability_2': profile_custom['player_ability_2'],
		'weapon_combine': profile_custom['weapon_combine']
		};
	return save_dict;

func set_all(json_var):
	for i in json_var.keys():
		if i == "name":
			pass
		else:
			profile_custom[i] = json_var[i];
	for i in profile_custom.keys():
		change_action_key(i, profile_custom[i]);
	for line in action_list.get_children():
		line.update_key(profile_custom[$"..".actions[line.fetch_control_name()]]);
