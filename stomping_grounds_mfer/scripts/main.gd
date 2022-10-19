extends Node

var level := 0;
var player_current_gold := 0;
var player_nodepath;
onready var pixelstan = $pixelstan;

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		if pixelstan.player.alive:
			$pixelstan.savegame();
		else:
			var dir = Directory.new();
			dir.remove("user://savegame.save");

func save():
	var save_dict = {
		"name" : "global",
		"level" : level,
		"player_current_gold" : player_current_gold,
		"player_nodepath": player_nodepath
	};
	return save_dict;

func load_main():
	var save_game = File.new();
	if not save_game.file_exists("user://savegame.save"):
		return;
	save_game.open("user://savegame.save", File.READ);
	var node_data = parse_json(save_game.get_line());
	for j in node_data.keys():
		if j != "name":
			set(j, node_data[j]);
	save_game.close();
