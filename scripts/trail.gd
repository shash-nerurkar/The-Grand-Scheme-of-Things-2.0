extends Sprite

var start_mod;

func init(pos, texture, scale, mod, fliph):
	global_position = pos;
	texture = texture;
	scale = scale;
	flip_h = fliph;
	$alpha.interpolate_property(self, "modulate", mod, Color(mod.r, mod.g, mod.b, 0), 1, Tween.TRANS_SINE, Tween.EASE_OUT);
	$alpha.start();
	$alpha.interpolate_property(self, "position", position, position-Vector2(10, 10), 1, Tween.TRANS_SINE, Tween.EASE_OUT);
	$alpha.start();

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_alpha_tween_completed(object, key):
	queue_free();
