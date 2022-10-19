extends TextureRect

var alpha;

func flash_screen(a):
	alpha = a;
	$alpha.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, alpha), 0.2, Tween.TRANS_QUINT, Tween.EASE_IN); 
	$alpha.start();

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_alpha_tween_completed(object, key):
	$alpha2.interpolate_property(self, "modulate", Color(1, 1, 1, alpha), Color(1, 1, 1, 0), 1, Tween.TRANS_BOUNCE, Tween.EASE_IN); 
	$alpha2.start();

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_alpha2_tween_completed(object, key):
	queue_free();
