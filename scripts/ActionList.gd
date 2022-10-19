extends Control

const InputLine = preload("res://scenes/line_input.tscn");

func add_input_line(action_name, key):
	var line = InputLine.instance();
	line.initialize(action_name, key);
	add_child(line);
	return line;
