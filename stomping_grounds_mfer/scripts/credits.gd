extends ColorRect

var val := 0.0;

func _ready():
	$transition/AnimationPlayer.play("fade_in");
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	if val < 860.0:
		val += 1;
		$ScrollContainer.set_v_scroll(val);
	else:
		$ScrollContainer/VBoxContainer/Label2.modulate.a = 255;
		$ScrollContainer.scroll_vertical_enabled = true;

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade_in":
		$transition.hide();
		set_physics_process(true);
	else:
		global.skip_trans = true;
	# warning-ignore:return_value_discarded
		get_tree().change_scene("res://scenes/main_menu.tscn");

func _on_back_button_pressed():
	$transition.show();
	$transition/AnimationPlayer.play("fade_out");
