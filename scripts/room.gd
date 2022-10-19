extends RigidBody2D

signal new_archive_entry

onready var door_container = $door_container;
onready var dead_body_container = $dead_body_container;
onready var spawn_timer = $spawn_timer;
onready var pixelstan = $"../..";

var minion = preload("res://scenes/enemy/minion_enemy.tscn");
var big = preload("res://scenes/enemy/big_enemy.tscn");
var burst = preload("res://scenes/enemy/moveshoot_enemy.tscn");
var melee = preload("res://scenes/enemy/melee_enemy.tscn");
var assassin = preload("res://scenes/enemy/assassin_enemy.tscn");
var twostage_melee = preload("res://scenes/enemy/twostage_melee_enemy.tscn");

var coin = preload("res://scenes/coin.tscn");
var dead_body = preload("res://scenes/dead_body.tscn");

var size;
var player = null;
var weak_ref_array := [];
var enemy_array := [];
var number_of_spawns := 0;
var total_coins := 50;
var spawning_time := 0;
var spawning_rate := 3;

func _ready():
	set_process(false);

# warning-ignore:unused_argument
func _process(delta):
	for i in range(number_of_spawns):
		for j in range(number_of_spawns):
			if(weakref(player).get_ref() and player.alive):
				if enemy_array[i].position.distance_to(player.position) < enemy_array[j].position.distance_to(player.position):
					var temp2 = enemy_array[i];
					enemy_array[i] = enemy_array[j];
					enemy_array[j] = temp2;
	var temp = player.position;
	var length = clamp(enemy_array.size(), 0, 3);
	for i in range(length):
		temp += enemy_array[i].position;
	temp /= length+1;
	var magnitude = clamp(temp.distance_to(player.position), 0, 100);
	temp = (temp - player.position).normalized();
	if(weakref(player).get_ref()):
		pixelstan.camera.position = player.position + temp*magnitude;

func coin_release(pos):
	var no_of_coins = randi() % 10;
	total_coins -= no_of_coins;
	for i in no_of_coins:
		var c = coin.instance();
		c.player = player;
		pixelstan.detail.add_child(c);
		c.add_to_group(String(self.get_instance_id()) + "coin");
		c.initiate(pos);

func make_room(pos, _size):
	position = pos;
	size = _size;
	var s = RectangleShape2D.new();
	s.extents = size;
	$CollisionShape2D.shape = s;

# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_room_body_shape_entered(body_id, body, body_shape, local_shape):
	var direction_of_trav = position - body.position;
	direction_of_trav = direction_of_trav.normalized();
	add_central_force(direction_of_trav * 300 * (randf()+1));
	yield(get_tree().create_timer(.1), "timeout");
	applied_force = Vector2();

func activate():
	pixelstan.HUD.on_room_activation(self);
	for enemy in get_tree().get_nodes_in_group(String(self.get_instance_id()) + "enemy"):
		if not pixelstan.HUD.archive.enemy_array[enemy.enemy]:
			emit_signal("new_archive_entry", 'enemy');
			pixelstan.HUD.archive.enemy_array[enemy.enemy] = true;
		enemy.show();
		enemy.sprite.play("spawn");
	for door in door_container.get_children():
		door.close();
	for weapon in get_tree().get_nodes_in_group(String(self.get_instance_id()) + "weapon"):
		if not pixelstan.HUD.archive.weapons_array[weapon.weapon_string]:
			emit_signal("new_archive_entry", 'weapon');
			pixelstan.HUD.archive.weapons_array[weapon.weapon_string] = true;
	set_process(true);
	if spawning_time > spawning_rate:
		spawn_timer.start(spawning_rate);

func cleared():
	pixelstan.HUD.on_room_cleared(self);
	pixelstan.room_status[$"..".get_children().find(self)] = true;
	pixelstan.player_position_x = position.x;
	pixelstan.player_position_y = position.y;
	for door in door_container.get_children():
		door.open();
	pixelstan.current_room = null;
	set_process(false);

func arrays_clear(enemy):
	var d = dead_body.instance();
	d.global_position = enemy.global_position;
	d.scale = enemy.scale;
	d.flip_h = enemy.sprite.flip_h;
	d.set_texture(load('res://art/enemies/' + enemy.enemy + '/death/death.png'));
	d.z_index = -30;
	dead_body_container.add_child(d);
	enemy_array.erase(enemy);
	number_of_spawns -= 1;
	if get_tree().get_nodes_in_group(String(self.get_instance_id()) + "enemy").size() == 1 and spawn_timer.is_stopped():
		cleared();

func _on_spawn_timer_timeout():
	spawning_time -= spawning_rate;
# warning-ignore:unused_variable
	for cls in global.biome_enemy[pixelstan.biome].keys():
		var number_of_spawns = global.spawn_num[cls] + clamp(size.x/192-3, -global.spawn_num[cls], size.x/192-3);
		for z in range(number_of_spawns):
			var e_pos =  Vector2((randf()+0.1) * size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * size.y/2 * (pow(-1, randi() % 2)));
			spawn_enemy(e_pos, cls);
	if spawning_time > 0:
		spawn_timer.start(spawning_rate);

func spawn_enemy(e_pos, cls):
	if  $"../..".obstacles.get_cellv(e_pos) == -1:
		var a;
		match cls:
			"MINION":
				a = minion.instance();
			"BIG":
				a = big.instance();
			"ASSASSIN":
				a = assassin.instance();
			"BURST": 
				a = burst.instance();
			"MELEE":
				a = melee.instance();
			"TWOSTAGE_MELEE":
				a = twostage_melee.instance();
		pixelstan.detail.add_child(a);
		a.add_to_group(String(self.get_instance_id()) + "enemy");
		a.init(global.biome_enemy[pixelstan.biome][cls], e_pos + global_position);
		a.timer.paused = true;
		a.player = player;
		a.connect("release_coins", self, "coin_release");
		a.connect("clear_arrays", self, "arrays_clear");
		enemy_array.append(a);
		number_of_spawns += 1;
		a.sprite.play("%s_spawn" % a.enemy);
	else:
		e_pos = Vector2((randf()+0.1) * size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * size.y/2 * (pow(-1, randi() % 2)));
		spawn_enemy(e_pos, cls);
