extends Control

signal button_pressed

var scene_to_load;
var prompt_flag := false;

func _ready():
	#OS.window_fullscreen = true;
	var save_game = File.new();
	$Menu/buttons/loadgame.disabled = false if save_game.file_exists("user://savegame.save") else true;
	if global.skip_trans: 
		global.skip_trans = false;
		$ini_tr.queue_free();
		$transition/AnimationPlayer.play("fade_in");
		$background_music.play();
		$Light2D.show();

func on_Button_pressed(stl):
	set_process_input(false);
	match stl:
		"newgame":
			scene_to_load = "res://scenes/character_selection.tscn";
			var save_game = File.new();
			if save_game.file_exists("user://savegame.save"):
				$overwrite_prompt.show();
				$overwrite_prompt/Label.set_text("Are you sure you want to over-write your old save file?");
				yield(self, "button_pressed");
				if prompt_flag:
					var dir = Directory.new();
					dir.remove("user://savegame.save");
					$overwrite_prompt.hide();
				else:
					$overwrite_prompt.hide();
					return;
		"loadgame":
			scene_to_load = "res://scenes/main.tscn";
		"credits":
			scene_to_load = "res://scenes/credits.tscn";
		"exit":
			$overwrite_prompt.show();
			$overwrite_prompt/Label.set_text("Are you sure you want to quit, you quitter?");
			yield(self, "button_pressed");
			if prompt_flag:
				get_tree().quit();
			else:
				$overwrite_prompt.hide();
				return;
	$transition/AnimationPlayer.play("fade_out");
	$guns/machinegun.set_occluder_light_mask(0);
	$guns/shotgun.set_occluder_light_mask(0);
	$stabber/LightOccluder2D.set_occluder_light_mask(0);
	$barrel/LightOccluder2D.set_occluder_light_mask(0);
	$lantern/LightOccluder2D.set_occluder_light_mask(0);

# warning-ignore:unused_argument
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_in":
		for button in $Menu/buttons.get_children():
			button.connect("pressed", self, "on_Button_pressed", [button.get_name()]);
	elif anim_name == "fade_out":
	# warning-ignore:return_value_discarded
		get_tree().change_scene(scene_to_load);

func _on_overwrite_yes_pressed():
	prompt_flag = true;
	emit_signal("button_pressed");

func _on_overwrite_no_pressed():
	prompt_flag = false;
	emit_signal("button_pressed");

func _on_ini_tr_done():
	$transition/AnimationPlayer.play("fade_in");
	$Light2D.show();
	$background_music.play();
