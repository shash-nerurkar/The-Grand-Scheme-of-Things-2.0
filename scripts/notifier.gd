extends Label

var velocity = Vector2(0, -50);
var current_val := 0;
var editable := true;
var type;
var crit;

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_alpha_tween_completed(object, key):
	if key == "modulate":
		queue_free();

func _on_Timer_timeout():
	editable = false;
	$alpha.interpolate_property(self, "rect_position", rect_position, rect_position + Vector2(0, -10), 0.7, Tween.TRANS_SINE, Tween.EASE_IN); 
	$alpha.start();
	$alpha.interpolate_property(self, "modulate", modulate, Color(modulate.r, modulate.g, modulate.b, 0), 0.7, Tween.TRANS_QUINT, Tween.EASE_IN); 
	$alpha.start();

func initialize(pos):
	rect_position = pos;
	get("custom_fonts/font").set_size(16);
	rect_scale = Vector2(0.5, 0.5);

func set_info(t):
	type = t;
	match t:
		'stun':
			set_text("STUNNED!");
			modulate = Color(1, 1, 0, 1);
		'slow':
			set_text("SLOWED!");
			modulate = Color(1, 1, 0, 1);
		'knock_back':
			set_text("KNOCKED BACK!");
			modulate = Color(1, 1, 0, 1);
		'knock_up':
			set_text("KNOCKED UP!");
			modulate = Color(1, 1, 0, 1);
		"armor_reduction":
			set_text("ARMOR REDUCED!");
			modulate = Color(0.5, 0.5, 0.5, 1);
		"poison":
			set_text("POISONED!");
			modulate = Color(0, 1, 0, 1);
	$Timer.start(0.5);

func set_val(amount, did_it_crit):
	type = 'damage';
	current_val += amount;
	crit = did_it_crit;
	$Timer.start();
	if crit:
		set_text(String(current_val) + "!");
		modulate = Color(1, 0, 0, 1);
	else:
		set_text(String(current_val));
		modulate = Color(1, 1, 1, 1);
	$alpha.interpolate_property(self, "rect_scale", Vector2(0.2, 0.2), Vector2(0.7, 0.7), 0.4, Tween.TRANS_BACK, Tween.EASE_OUT); 
	$alpha.start();
