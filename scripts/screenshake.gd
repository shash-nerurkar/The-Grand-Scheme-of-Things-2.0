extends Node

var amplitude;
var is_shaking;

onready var camera = $"..";

func _on_player_screen_shake_requested(amp, frequency, duration):
	if !is_shaking:
		amplitude = amp;
		is_shaking = true;
		$duration.wait_time = duration;
		$frequency.wait_time = 1/float(frequency);
		$duration.start();
		$frequency.start();
		new_shake();

func start(amp, frequency, duration):
	amplitude = amp;
	is_shaking = true;
	$duration.wait_time = duration;
	$frequency.wait_time = 1/float(frequency);
	$duration.start();
	$frequency.start();
	new_shake();

func new_shake():
	var rand = Vector2();
	rand.x = rand_range(-amplitude, amplitude);
	rand.y = rand_range(-amplitude, amplitude);
	$offset.interpolate_property(camera, "offset", camera.offset, rand, $frequency.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT);
	$offset.start();

func reset():
	$offset.interpolate_property(camera, "offset", camera.offset, Vector2(0, 0), $frequency.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT);
	$offset.start();

func _on_frequency_timeout():
	new_shake();

func _on_duration_timeout():
	$frequency.stop();
	reset();
	is_shaking = false;
	amplitude = 0;
