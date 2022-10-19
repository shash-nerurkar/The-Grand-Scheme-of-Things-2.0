extends Panel

onready var HUD = $"..";

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		hide();

# warning-ignore:unused_argument
func _on_music_slider_value_changed(value):
	if $VBoxContainer/GridContainer/music_slider.value-20 == -20:
		HUD.pixelstan.music_player.volume_db = -80;
	else:
		HUD.pixelstan.music_player.volume_db = $VBoxContainer/GridContainer/music_slider.value - 20;

func _on_back_button_pressed():
	hide();
	HUD.pause_panel.show();

# warning-ignore:unused_argument
func _on_sfx_slider_value_changed(value):
	if HUD.pixelstan.player_weapon_sounds == null:
		return;
	if $VBoxContainer/GridContainer/sfx_slider.value-20 == -20:
		HUD.pixelstan.player_weapon_sounds.volume_db = -80;
	else:
		HUD.pixelstan.player_weapon_sounds.volume_db = $VBoxContainer/GridContainer/sfx_slider.value - 20;

