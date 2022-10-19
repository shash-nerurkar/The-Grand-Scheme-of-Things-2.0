extends ColorRect

var type;
var string;

func _on_TextureButton_pressed():
	match type:
		'enemy':
			$"../../../Panel/VBoxContainer/Sprite".show();
			$"../../../Panel/VBoxContainer/Sprite".get_texture().set_frames(global.idle_frames[string][0]);
			for i in range(global.idle_frames[string][0]):
				$"../../../Panel/VBoxContainer/Sprite".get_texture().set_frame_texture(i, load("res://art/enemies/" + string + "/idle/" + String(i+1) + ".png"));
			if $"../../../..".enemy_array[string]:
				$"../../../Panel/VBoxContainer/Sprite".modulate = Color(1, 1, 1);
				$"../../../Panel/VBoxContainer/Info".set_text(global.enemy_info[string]);
				$"../../../Panel/VBoxContainer/GridContainer/Type".set_text("TYPE\n" + String(global.enemy_class[string]));
				$"../../../Panel/VBoxContainer/GridContainer/Health".set_text("HEALTH\n" + String(global.enemy_health[string]));
				$"../../../Panel/VBoxContainer/GridContainer/Damage".set_text("DAMAGE\n" + String(global.enemy_damage[string]));
				$"../../../Panel/VBoxContainer/GridContainer/Attack_speed".set_text("ATTACK SPEED\n" + String(global.enemy_shoot_cooldown[string]));
			else:
				$"../../../Panel/VBoxContainer/Sprite".modulate = Color(0, 0, 0);
				$"../../../Panel/VBoxContainer/Info".set_text("???");
				$"../../../Panel/VBoxContainer/GridContainer/Type".set_text("TYPE\n???");
				$"../../../Panel/VBoxContainer/GridContainer/Health".set_text("HEALTH\n???");
				$"../../../Panel/VBoxContainer/GridContainer/Damage".set_text("DAMAGE\n???");
				$"../../../Panel/VBoxContainer/GridContainer/Attack_speed".set_text("ATTACK SPEED\n???");
		'weapon':
			$"../../../Panel/VBoxContainer/Sprite".show();
			$"../../../Panel/VBoxContainer/Sprite".get_texture().set_frames(1);
			$"../../../Panel/VBoxContainer/Sprite".get_texture().set_frame_texture(0, load("res://art/weapons/" + string + ".png"));
			if $"../../../..".weapons_array[string]:
				$"../../../Panel/VBoxContainer/Sprite".modulate = Color(1, 1, 1);
				$"../../../Panel/VBoxContainer/Info".set_text(global.weapon_info[string]);
				$"../../../Panel/VBoxContainer/GridContainer/Type".set_text("DAMAGE\n" + String(global.weapon_damage[string]));
				$"../../../Panel/VBoxContainer/GridContainer/Health".set_text("FIRERATE\n" + String(global.weapon_firerate[string]));
				$"../../../Panel/VBoxContainer/GridContainer/Damage".set_text("CRITICAL CHANCE\n" + String(global.weapon_crit[string]));
				$"../../../Panel/VBoxContainer/GridContainer/Attack_speed".set_text("ACCURACY\n" + String(global.weapon_accuracy[string]));
			else:
				$"../../../Panel/VBoxContainer/Sprite".modulate = Color(0, 0, 0);
				$"../../../Panel/VBoxContainer/Info".set_text("???");
				$"../../../Panel/VBoxContainer/GridContainer/Type".set_text("DAMAGE\n???");
				$"../../../Panel/VBoxContainer/GridContainer/Health".set_text("FIRERATE\n???");
				$"../../../Panel/VBoxContainer/GridContainer/Damage".set_text("CRITICAL CHANCE\n???");
				$"../../../Panel/VBoxContainer/GridContainer/Attack_speed".set_text("ACCURACY\n???");
