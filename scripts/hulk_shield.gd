extends KinematicBody2D

onready var ability_nodes_container = $"..";

var health = 6;
var throwable := false;
var debris_texture;

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func damage(amount, k_dir, k_duration):
	health -= amount;
	if health <= 0:
		throwable = false;
		$collision.set_deferred("disabled", true);
		$sprite.play("broken");
	elif health <= 3:
		$sprite.play("break_1");

func _on_sprite_animation_finished():
	if $sprite.get_animation() == "broken":
		var shield_debris = Sprite.new();
		shield_debris.set_texture(debris_texture);
		shield_debris.flip_h = $sprite.flip_h;
		shield_debris.global_position = $sprite.global_position;
		ability_nodes_container.add_child(shield_debris);
		health = 6;
