extends Control

signal prompt_answered

onready var q_clip = $panel/VBoxContainer/HBoxContainer/VBoxContainer2/abilties/Q_clip;
onready var e_clip = $panel/VBoxContainer/HBoxContainer/VBoxContainer2/abilties/E_clip;
onready var hp =$panel/VBoxContainer/HBoxContainer/VBoxContainer/stats/health_points;
onready var sprite = $panel/VBoxContainer/HBoxContainer/VBoxContainer/sprite;
onready var gp = $panel/VBoxContainer/HBoxContainer/VBoxContainer/stats/god_points;
onready var character_info = $panel/VBoxContainer/HBoxContainer/VBoxContainer2/info;
onready var q_info = $panel/VBoxContainer/HBoxContainer/VBoxContainer2/abilties/Q_desc;
onready var e_info = $panel/VBoxContainer/HBoxContainer/VBoxContainer2/abilties/E_desc;
onready var oogc = $oogc;
onready var panel_oogc_label = $panel/VBoxContainer/HBoxContainer2/oogc;
onready var select_button = $panel/VBoxContainer/HBoxContainer/VBoxContainer/select_button;
onready var select_button_label = $panel/VBoxContainer/HBoxContainer/VBoxContainer/select_button/Label;
onready var character_buy_prompt = $prompt;

var balance;
var select_button_status;
var prompt_flag;

var char_key := 0;

var char_status := {"1": true,
					"2": false,
					"3": true};

var char_cost = {1: 200,
				2: 0,
				3: 100};

var char_code = {1: "bounty_hunter",
				 2: "detective",
				 3: "hulk"};

var nm = {1: "Bounty Hunter",
		  2: "Detective",
		  3: "Hulk"};

var info = {1: "Claudia has roamed the lands solo. She has only one drive; money. Armed with explosives and a military-grade hookshot, she can weave in and out of the battle like a bee.",
			2: "Infamy likes to take the calculated way. He escaped the facility and they still haven't found out.",
			3: "Disazter is a rage-fuelled humanoid. He lays waste and debris on the battlefield."};

var health = {1: "Bounty Hunter",
			  2: "Detective",
			  3: "Hulk"};

var god_points = {1: "Bounty Hunter",
				  2: "Detective",
				  3: "Hulk"};

var Q = {1: "Claudia shoots her hook. If it hits the wall, she is pulled towards it. If it misses, it reels back to her",
		 2: "Infamy tiptoes into the room, to set up his traps. He also analyses the enemies; he can see their health and the rate at which they attack.",
		 3: "Disazter slams the ground, forcing the bedrock to surface."};

var E = {1: "Claudia throws a grenade. When out of combat, she can pull up the grenade selection interface by holding the key. Each grenade has its own use.",
		 2: "Infamy has traps that he can lay around the room. These traps deal more damage the faster they trigger.",
		 3: "Disazter kicks the floor, pulling out a rock, and hurls it at the enemy. If the bedrock shield is his way, he hurls it instead, dealing massive damage."};

var frame = {1: ["res://art/bounty_hunter/idle/bounty_hunter_1.png",
				 "res://art/bounty_hunter/idle/bounty_hunter_2.png",
				 "res://art/bounty_hunter/idle/bounty_hunter_3.png"],
			 2: ["res://art/hooded_figure/idle/hooded_figure1.png",
				 "res://art/hooded_figure/idle/hooded_figure2.png",
				 "res://art/hooded_figure/idle/hooded_figure3.png",
				 "res://art/hooded_figure/idle/hooded_figure4.png"],
			 3: ["res://art/hulk/idle/hulk_1.png",
				 "res://art/hulk/idle/hulk_2.png",
				 "res://art/hulk/idle/hulk_3.png",
				 "res://art/hulk/idle/hulk_4.png",
				 "res://art/hulk/idle/hulk_5.png"]};

func _ready():
	loadgame();
	character_buy_prompt.get_node("yes").connect("pressed", self, "on_prompt_yes_pressed");
	character_buy_prompt.get_node("no").connect("pressed", self, "on_prompt_no_pressed");
	oogc.set_text(String(balance));
	$transition/AnimationPlayer.play("fade_in");

func update_info():
	panel_oogc_label.set_text("BAL:" + String(balance));
	oogc.set_text(String(balance));
	$panel/VBoxContainer/HBoxContainer2/name.set_text(nm[char_key]);
	if char_status[String(char_key)]:
		select_button_label.set_text("SELECT");
		select_button.disabled = false;
		select_button_status = "SELECT";
	else:
		select_button_label.set_text("COST:" + String(char_cost[char_key]));
		select_button.disabled = false if char_cost[char_key] <= balance else true;
		select_button_status = "BUY";
	var texture = AnimatedTexture.new();
	texture.set_frames(frame[char_key].size()*2);
	texture.set_fps(10);
	for i in range(frame[char_key].size()):
		texture.set_frame_texture(i, load(frame[char_key][i]));
	for i in range(frame[char_key].size()-1, -1, -1):
		texture.set_frame_texture((frame[char_key].size()*2)-1-i, load(frame[char_key][i]));
	sprite.set_texture(texture);
	hp.set_text(health[char_key]);
	gp.set_text(god_points[char_key]);
	character_info.set_text(info[char_key]);
	q_info.set_text("Q:" + Q[char_key]);
	q_clip.set_stream(load("res://clips/" + char_code[char_key] + "_q.ogv"));
	e_info.set_text("E:" + E[char_key]);
	e_clip.set_stream(load("res://clips/" + char_code[char_key] + "_e.ogv"));

func _on_back_button_pressed():
	$panel.hide();

func _on_select_button_pressed():
	if select_button_status == "SELECT":
		match char_key:
			1: global.player_nodepath = "res://scenes/characters/bounty_hunter.tscn";
			2: global.player_nodepath = "res://scenes/characters/detective.tscn";
			3: global.player_nodepath = "res://scenes/characters/hulk.tscn";
		savegame();
		$transition.show();
		$transition/AnimationPlayer.play("fade_out");
	elif select_button_status == "BUY":
		character_buy_prompt.show();
		character_buy_prompt.get_node("Label").set_text("Are you sure you want to buy this character?\nCURRENT BALANCE:" + String(balance) + "  FINAL BALANCE:" + String(balance - char_cost[char_key]));
	yield(self, "prompt_answered");
	if prompt_flag:
		balance -= char_cost[char_key];
		char_status[String(char_key)] = true;
		character_buy_prompt.hide();
		update_info();
	else:
		character_buy_prompt.hide();

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_in":
		$transition.hide();
	if anim_name == "fade_out":
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://scenes/main.tscn");

func _on_bounty_hunter_pressed():
	char_key = 1;
	update_info();
	$panel.show();

func _on_hooded_figure_pressed():
	char_key = 2;
	update_info();
	$panel.show();

func _on_hulk_pressed():
	char_key = 3;
	update_info();
	$panel.show();

func _on_Q_clip_mouse_entered():
	q_clip.set_stream_position(0);
	q_clip.play();
	e_clip.hide();

func _on_Q_clip_mouse_exited():
	q_clip.stop();
	e_clip.show();

func _on_E_clip_mouse_entered():
	e_clip.set_stream_position(0);
	e_clip.play();
	q_clip.hide();

func _on_E_clip_mouse_exited():
	e_clip.stop();
	q_clip.show();

func on_prompt_yes_pressed():
	prompt_flag = true;
	emit_signal("prompt_answered");

func on_prompt_no_pressed():
	prompt_flag = false;
	emit_signal("prompt_answered");

func savegame():
	var save_game = File.new();
	save_game.open("user://outofgamesave.save", File.WRITE);
	var node_data = save();
	save_game.store_line(to_json(node_data));
	save_game.close();

func loadgame():
	var save_game = File.new();
	if not save_game.file_exists("user://outofgamesave.save"):
		return;
	save_game.open("user://outofgamesave.save", File.READ);
	var node_data = parse_json(save_game.get_line());
	for j in node_data.keys():
		set(j, node_data[j]);
	save_game.close();

func save():
	var save_dict = {
		"name": get_name(),
		"balance": balance,
		"char_status": char_status
	};
	return save_dict;
