extends Panel

var velocity := Vector2();
var STATE;

# warning-ignore:unused_argument
func _physics_process(delta): 
	match STATE:
		'up':
			rect_position = rect_position.linear_interpolate(Vector2(350, 515), 0.1);
		'down':
			rect_position = rect_position.linear_interpolate(Vector2(350, 615), 0.1);

func show_pickup_notifier(weapon_string):
	$GridContainer/Damage.set_text(String(global.weapon_damage[weapon_string]));
	$GridContainer/Attackspeed.set_text(String(global.weapon_firerate[weapon_string]));
	$GridContainer/Crit.set_text(String(global.weapon_crit[weapon_string]));
	$GridContainer/Inaccuracy.set_text(String(global.weapon_accuracy[weapon_string]));
	rect_position = Vector2(350, 615);
	STATE = 'up';

func hide_pickup_notifier():
	STATE = 'down';
