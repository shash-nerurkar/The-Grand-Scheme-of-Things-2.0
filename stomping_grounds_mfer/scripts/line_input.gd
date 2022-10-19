extends HBoxContainer

signal change_button_pressed

var valid := true;
var control_name;

func initialize(action_name, k):
	control_name = action_name;
	$Action.text = action_name.capitalize();
	$ChangeButton/Key.text = OS.get_scancode_string(k);

func update_key(scancode):
	if scancode == KEY_ASCIITILDE:
		valid = false;
		$ChangeButton.texture_normal = load("res://art/buttons/invalid_frame.png");
		$ChangeButton.texture_pressed = load("res://art/buttons/invalid_frame_pressed.png");
		$ChangeButton/Key.text = "~";
	else:
		valid = true;
		$ChangeButton.texture_normal = load("res://art/buttons/frame.png");
		$ChangeButton.texture_pressed = load("res://art/buttons/frame_pressed.png");
		$ChangeButton/Key.text = OS.get_scancode_string(scancode);

func _on_ChangeButton_pressed():
	emit_signal('change_button_pressed');

func _on_ChangeButton_button_down():
	$ChangeButton/Key.rect_position = Vector2(29, 17);

func _on_ChangeButton_button_up():
	$ChangeButton/Key.rect_position = Vector2(29, 13);

func fetch_key():
	return $ChangeButton/Key.text;

func fetch_control_name():
	return control_name;
