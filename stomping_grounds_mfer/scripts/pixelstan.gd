extends Node2D

var minion = preload("res://scenes/enemy/minion_enemy.tscn");
var big = preload("res://scenes/enemy/big_enemy.tscn");
var burst = preload("res://scenes/enemy/moveshoot_enemy.tscn");
var melee = preload("res://scenes/enemy/melee_enemy.tscn");
var twostage_melee = preload("res://scenes/enemy/twostage_melee_enemy.tscn");
var assassin = preload("res://scenes/enemy/assassin_enemy.tscn");
var Room = preload("res://scenes/room.tscn");
var door = preload("res://scenes/door.tscn");
var weapons = preload("res://scenes/weapon.tscn");

onready var Map = $tiles;
onready var obstacles = $obstacles;
onready var detail = $obstacles/detail;
onready var room_container = $room_container;
onready var music_player = $music;
onready var main = $"..";
onready var HUD = $HUD;
onready var camera = $camera;
onready var loading = $loading;
onready var shopkeeper = $obstacles/detail/shopkeeper;

var total_coins = 20;
var tile_size = 64;
var num_rooms = 10;
var min_size = 10;
var unit = 3;
var hspread = 400;
var player = null;
var path;
var start_room = null;
var end_room = null;
var current_room = null;
var toggler = 0;
var room_pos_x := [];
var room_pos_y := [];
var full_rect = Rect2();
var room_status := [];
var room_sizes := [];
var player_position_x;
var player_position_y;
var texture_order := ["wall_top", "wall_top_left", "wall_top_right", "wall_top_left_corner", "wall_top_right_corner", "wall_top_top",
					  "wall_front_plain_", "wall_front_anim1_", "wall_front_anim2_", "wall_front_anim3_", "wall_front_anim4_", "wall_front_anim5_", 
					  "wall_front_anim6_", "wall_bottom_left_", "wall_bottom_right_",
					  "floor_tile_1", "floor_tile_2", "floor_tile_3", "corridor_tilesheet",
					  "wall_front_bot_plain_", "wall_front_bot_anim1_", "wall_front_bot_anim2_", "wall_front_bot_anim3_", "wall_front_bot_anim4_", "wall_front_bot_anim5_", 
					  "wall_front_bot_anim6_", "wall_front_bot_bottom_left_", "wall_front_bot_bottom_right_"];
var biome;
var player_weapon_sounds;

func _ready():
	randomize();
	main.load_main();
	for child in get_children():
		if child.get_name() == player:
			break;
		elif child.get_index() == get_child_count() - 1:
			if main.player_nodepath == null:
				main.player_nodepath = global.player_nodepath;
			detail.add_child(load(main.player_nodepath).instance());
	loadgame();
	player = detail.get_node("player");
	player_weapon_sounds = player.weapon.sound;
	connect_signals();
	player.set_physics_process(false);
	player.set_process_input(false);
	if not HUD.archive.weapons_array[player.type]:
		HUD.archive_popup('weapon');
		HUD.archive.weapons_array[player.type] = true;
	prepare_level();
	set_physics_process(false);

# warning-ignore:unused_argument
func _physics_process(delta):
	update();
	if !player.alive:
		prepare_end();
		set_physics_process(false);
	HUD.update(player, main.player_current_gold);
	for room in room_container.get_children():
		if player.global_position.x > room.position.x - room.size.x/2 and player.global_position.x < room.position.x + room.size.x/2 and player.global_position.y > room.position.y - room.size.y/2 and player.global_position.y < room.position.y + room.size.y/2:
			if not room_status[room_container.get_children().find(room)] and room != start_room and room != end_room and current_room == null:
				room.activate();
				current_room = room;
			elif room == end_room:
				new_level();
			else:
				$HUD/minimap.get_child($HUD/minimap.get_child_count()-1).rect_position = $HUD/minimap.get_child(room_container.get_children().find(room)).rect_position;
				$HUD/minimap.get_child($HUD/minimap.get_child_count()-1).rect_size = $HUD/minimap.get_child(room_container.get_children().find(room)).rect_size;  
	if current_room == null:
		camera.position = player.position;

func prepare_level():
	var save_game = File.new();
	if not save_game.file_exists("user://savegame.save"):
		biome = global.biome[randi() % global.biome.size()];
	if save_game.file_exists("user://savegame.save"):
		old_rooms();
	else:
		make_rooms();
	HUD.set_process(true);
	initialize();
	loading.start(5.5);
	yield(loading, "timeout");
	Map.update_bitmask_region();
	music_player.play();
	connect_rooms();
	HUD.set_process(false);
	HUD.transition.hide();
	var room_positions := [];                          #CONVERTING COORDINATES INTO VECTOR2 BCOZ JSON SUCKS
	for i in room_pos_x.size():
		room_positions.append(Vector2(room_pos_x[i], room_pos_y[i]));
	HUD.draw_minimap(full_rect.size, room_positions, room_sizes, biome);
	if save_game.file_exists("user://savegame.save"):
		player.position = Vector2(player_position_x, player_position_y);
		for room in room_container.get_children():
			if room_status[room_container.get_children().find(room)] or room == start_room:
				show_miniroom_connections(room);
	else:
		player.position = start_room.position;
		player_position_x = start_room.position.x;
		player_position_y = start_room.position.y;
		HUD.minimap.get_child(room_container.get_children().find(start_room)).show();
		show_miniroom_connections(start_room);
	
	HUD.minimap.get_child(room_container.get_children().find(start_room)).modulate = Color(0, 1, 0);
	set_physics_process(true);
	HUD.show_notifier(String(main.level/5 + 1) + " - " + String(main.level % 5 + 1), Color(1, 1, 1));
	yield(get_tree().create_timer(1.5), "timeout");
	player.set_physics_process(true);
	player.set_process_input(true);

func new_level():
	HUD.transition.show();
	main.level+=1;
	player.set_process_input(false);                             #STOP RUNNING
	player.set_physics_process(false);
	cleanup();
	set_physics_process(false);
	if main.level%5 == 0:
		biome = global.biome[randi() % global.biome.size()];
	make_rooms();
	HUD.set_process(true);
	initialize();
	loading.start(5.5);
	yield(loading, "timeout");
	Map.update_bitmask_region();
	music_player.play();
	connect_rooms();
	HUD.set_process(false);
	HUD.transition.hide();
	var room_positions := [];                          #CONVERTING COORDINATES INTO VECTOR2 BCOZ JSON SUCKS
	for i in room_pos_x.size():
		room_positions.append(Vector2(room_pos_x[i], room_pos_y[i]));
	HUD.draw_minimap(full_rect.size, room_positions, room_sizes, biome);
	player.position = start_room.position;
	player_position_x = start_room.position.x;
	player_position_y = start_room.position.y;
	HUD.minimap.get_child(room_container.get_children().find(start_room)).show();
	HUD.minimap.get_child(room_container.get_children().find(start_room)).modulate = Color(0, 1, 0);
	show_miniroom_connections(start_room);
	set_physics_process(true);
	HUD.show_notifier(String(main.level/5 + 1) + " - " + String(main.level % 5 + 1), Color(1, 1, 1));
	yield(get_tree().create_timer(1.5), "timeout");
	player.set_physics_process(true);
	player.set_process_input(true);

func old_rooms():
	var room_positions := [];                          #CONVERTING COORDINATES INTO VECTOR2 BCOZ JSON SUCKS
	for i in room_pos_x.size():
		room_positions.append(Vector2(room_pos_x[i], room_pos_y[i]));
	
	for i in room_positions.size():             #PRINT OLD ROOMS
		var r = Room.instance();
		var w = min_size + global.room_size.get(room_sizes[i]).x*unit;
		var h = min_size + global.room_size.get(room_sizes[i]).y*unit;
		r.make_room(room_positions[i], Vector2(w, h) * tile_size);
		r.mode = RigidBody2D.MODE_STATIC;
		room_container.add_child(r);
		global.room_front_tile_texture_container[r.get_instance_id()] = 2 + randi()%3;
	yield(get_tree().create_timer(2), "timeout");
	
	path = find_mst(room_positions);
	yield(get_tree().create_timer(1), "timeout");
	
	make_map();

func make_rooms():
# warning-ignore:unused_variable
	for i in range(num_rooms):                            #SPAWNS ROOMS AT (0, 0)
		var r = Room.instance();
		var c = global.room_size[str(randi() % 9)];
		var w = min_size + c.x*unit;
		var h = min_size + c.y*unit;
		r.make_room(Vector2(rand_range(-hspread, hspread), 0), Vector2(w, h) * tile_size);
		room_container.add_child(r);
		global.room_front_tile_texture_container[r.get_instance_id()] = 2 + randi()%3;
	yield(get_tree().create_timer(2), "timeout");
	
	var room_positions = [];
	room_status.clear();
	room_sizes.clear();
	room_pos_x.clear();
	room_pos_y.clear();
	
	for room in room_container.get_children():                        #TURNS ROOMS STATIC, ADDING VALUES TO SAVEPOINT NODES
		room_sizes.append(global.room_size_class[Vector2( ( (room.size.x/tile_size) - min_size )/unit, ( (room.size.y/tile_size) - min_size )/unit )]); 
		room_pos_x.append(room.position.x);
		room_pos_y.append(room.position.y);
		room_status.append(false);
		room.mode = RigidBody2D.MODE_STATIC;
		room_positions.append(room.position);
	yield(get_tree().create_timer(2), "timeout");
	
	path = find_mst(room_positions);
	yield(get_tree().create_timer(1), "timeout");
	
	make_map();

func make_map():
	Map.clear();        
	for room in room_container.get_children():                       
		var r = Rect2(room.position - room.size, room.get_node("CollisionShape2D").shape.extents*2);
		full_rect = full_rect.merge(r);
	var topleft = Map.world_to_map(full_rect.position);                   #spawns wall tiles over the entire world
	var bottomright = Map.world_to_map(full_rect.end);
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, 0);
	
	var corridors = [];
	for room in room_container.get_children():                         
		var s = (room.size/tile_size).floor();
		var ul = (room.position / tile_size).floor() - s;
		for x in range(2, s.x*2 - 1):                            #setting floor tiles
			for y in range(2, s.y*2 - 1):
				Map.set_cell(ul.x + x, ul.y + y, 15 + randi()%3);
		var positions = obstacle_position_selection(room, s);
		for pos in positions:                                #setting obstacles
			obstacles.set_cell(pos.x, pos.y, randi() % 2);
			
		for x in range(3, s.x*2 - 2):                           #setting detail tiles
			for y in range(3, s.y*2 - 2):
				var res = true;
				for i in range(-2, 3, 1):
					for j in range(-2, 3, 1):
						if obstacles.get_cell(ul.x + x + i, ul.y + y + j) != -1:
							res = false;
				if res and randf() > 0.9:
					detail.set_cell(ul.x + x, ul.y + y, randi() % 11);
		var p = path.get_closest_point(room.position);
		for conn in path.get_point_connections(p):                       #finding attached paths
			if not conn in corridors:
				var start = path.get_point_position(p);
				var end = path.get_point_position(conn);
				carve_path(start, end);
		corridors.append(p);
		
	for room in room_container.get_children():                         #spawning doors and border tiles
		var s = (room.size/tile_size).floor();
		var ul = (room.position / tile_size).floor() - s;
		var br = (room.position / tile_size).floor() + s;
		for x in range(2, s.x*2-1):
			if Map.get_cell(ul.x + x, ul.y + 1) == 0 or Map.get_cell(ul.x + x, ul.y + 1) == 1 or Map.get_cell(ul.x + x, ul.y + 1) == 2:
				if x == 2:
					set_front_tiles(ul.x + x, ul.y + 1, "normal", "corner_left", room.get_instance_id());
				elif x == s.x*2-2:
					set_front_tiles(ul.x + x, ul.y + 1, "normal", "corner_right", room.get_instance_id());
				else:
					set_front_tiles(ul.x + x, ul.y + 1, "normal", "normal", room.get_instance_id());
			if Map.get_cell(ul.x + x, ul.y + 1) == 15 or Map.get_cell(ul.x + x, ul.y + 1) == 16 or Map.get_cell(ul.x + x, ul.y + 1) == 17 or Map.get_cell(ul.x + x, ul.y + 1) == 18:
				set_front_tiles(ul.x + x - 1, ul.y + 1, "corner_tiles", "bottom_right", room.get_instance_id());
				spawn_door(ul.x + x, ul.y + 1, room, "front");
				set_front_tiles(ul.x + x + 1, ul.y + 1, "corner_tiles", "bottom_left", room.get_instance_id());
			if Map.get_cell(ul.x + x, br.y - 1) == 15 or Map.get_cell(ul.x + x, br.y - 1) == 16 or Map.get_cell(ul.x + x, br.y - 1) == 17 or Map.get_cell(ul.x + x, br.y - 1) == 18:
				Map.set_cell(ul.x + x - 1, br.y - 1, 4);
				spawn_door(ul.x + x, br.y - 1, room, "front");
				Map.set_cell(ul.x + x + 1, br.y - 1, 3);
			elif Map.get_cell(ul.x + x + 1, br.y - 1) != 18 and Map.get_cell(ul.x + x - 1, br.y - 1) != 18:
				 Map.set_cell(ul.x + x, br.y - 1, 5);
		for y in range(1, s.y*2 - 1):
			if Map.get_cell(ul.x + 1, ul.y + y) == 15 or Map.get_cell(ul.x + 1, ul.y + y) == 16 or Map.get_cell(ul.x + 1, ul.y + y) == 17 or Map.get_cell(ul.x + 1, ul.y + y) == 18:
				set_front_tiles(ul.x + 1, ul.y + y - 1, "corner_tiles", "bottom_right", room.get_instance_id());
				spawn_door(ul.x + 1, ul.y + y, room, "side");
				Map.set_cell(ul.x + 1, ul.y + y + 1, 4);
			elif Map.get_cell(ul.x + 1, ul.y + y - 1) != 17 and Map.get_cell(ul.x + 1, ul.y + y + 1) != 17 and Map.get_cell(ul.x + 1, ul.y + y + 2) != 17:
				Map.set_cell(ul.x + 1, ul.y + y, 2);
			
			if Map.get_cell(br.x - 1, ul.y + y) == 15 or Map.get_cell(br.x - 1, ul.y + y) == 16 or Map.get_cell(br.x - 1, ul.y + y) == 17 or Map.get_cell(br.x - 1, ul.y + y) == 18:
				set_front_tiles(br.x - 1, ul.y + y - 1, "corner_tiles", "bottom_left", room.get_instance_id());
				spawn_door(br.x - 1, ul.y + y, room, "side");
				Map.set_cell(br.x - 1, ul.y + y + 1, 3);
			elif Map.get_cell(br.x - 1, ul.y + y - 1) != 17 and Map.get_cell(br.x - 1, ul.y + y + 1) != 17 and Map.get_cell(br.x - 1, ul.y + y + 2) != 17:
				Map.set_cell(br.x - 1, ul.y + y, 1);
	 
	for i in room_container.get_child_count():                        #spawning weapons and enemies
		if not room_status[i]:
		# warning-ignore:unused_variable
			for z in range(randi() % 3 + 3):
				var w_pos = Vector2((randf()+0.1) * room_container.get_child(i).size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * room_container.get_child(i).size.y/2 * (pow(-1, randi() % 2)));
				spawn_weapon(room_container.get_child(i), w_pos);
			#for j in get_tree().get_nodes_in_group(String(room_container.get_child(i).get_instance_id()) + "weapon"):
			#	for k in get_tree().get_nodes_in_group(String(room_container.get_child(i).get_instance_id()) + "weapon"):
			#		if j!=k and j.position.distance_to(k.position) < 1000:
			#			j.position = room_container.get_child(i).global_position + reposition_weapon(j, room_container.get_child(i));
			
			for cls in global.biome_enemy[biome].keys():
				var number_of_spawns = 1#global.spawn_num[cls] + clamp(room_container.get_child(i).size.x/192-3, -global.spawn_num[cls], room_container.get_child(i).size.x/192-3);
# warning-ignore:unused_variable
				for z in range(number_of_spawns):
					var e_pos =  Vector2((randf()+0.1) * room_container.get_child(i).size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * room_container.get_child(i).size.y/2 * (pow(-1, randi() % 2)));
					spawn_enemy(room_container.get_child(i), e_pos, cls);          
	
	var obstacle_center = Vector2();
	for pos in global.biome_obstacle_coll_array[biome]:
		obstacle_center += pos;
	obstacle_center /= global.biome_obstacle_coll_array[biome].size();
	
	for room in room_container.get_children():              
		var positions = obstacle_position_selection(room, (room.size/tile_size).floor());
		for pos in positions:                                #setting obstacles
			var p = obstacles.map_to_world(pos) + obstacle_center;
			p = Map.world_to_map(p);
			for i in range(-2, 1, 1):
				for j in range(-1, 1, 1):
					if obstacles.get_cell(p.x, p.y) == 0 and Map.get_cell(p.x + i, p.y + j) == 18:
						Map.set_cell(p.x + i, p.y + j, 15 + randi()%3);
	 
	find_start_room();                             
	find_end_room();

func carve_path(cave1_world, cave2_world):
	var room_positions := [];                          #CONVERTING COORDINATES INTO VECTOR2 BCOZ JSON SUCKS
	for i in room_pos_x.size():
		room_positions.append(Vector2(room_pos_x[i], room_pos_y[i]));               
	var cave1_adj = (room_container.get_child(room_positions.find(cave1_world)).size/tile_size).floor();
	var cave2_adj = (room_container.get_child(room_positions.find(cave2_world)).size/tile_size).floor();
	var cave1 = Map.world_to_map(cave1_world);
	var cave2 = Map.world_to_map(cave2_world);
	var x_diff = sign(cave2.x - cave1.x);
	var y_diff = sign(cave2.y - cave1.y);
	if x_diff == 0: x_diff = (pow(-1, randi() % 2));
	if y_diff == 0: y_diff = (pow(-1, randi() % 2));
	
	for x in range(cave1.x, cave2.x, x_diff):                #horizontal part of path
		if cave2.y == cave1.y - cave1_adj.y + 1 or cave1.y == cave2.y - cave2_adj.y + 1:
			if y_diff<0:
				if (Map.get_cell(x, cave2.y) == 0 or Map.get_cell(x, cave2.y) == 1 or Map.get_cell(x, cave2.y) == 2):
					set_front_tiles(x, cave2.y, "corridor", "normal", 0);
				Map.set_cell(x, cave2.y+1, 18);
				if (Map.get_cell(x, cave2.y+2) == 0 or Map.get_cell(x, cave2.y+2) == 1 or Map.get_cell(x, cave2.y+2) == 2):
					Map.set_cell(x, cave2.y+2, 5);
				HUD.draw_minimap_corridors(full_rect.size, Map.map_to_world(Vector2(x, cave2.y+1)));
			else:
				if (Map.get_cell(x, cave2.y-2) == 0 or Map.get_cell(x, cave2.y-2) == 1 or Map.get_cell(x, cave2.y-2) == 2):
					set_front_tiles(x, cave2.y-2, "corridor", "normal", 0);
				Map.set_cell(x, cave2.y-1, 18);
				if (Map.get_cell(x, cave2.y) == 0 or Map.get_cell(x, cave2.y) == 1 or Map.get_cell(x, cave2.y) == 2):
					Map.set_cell(x, cave2.y, 5);
				HUD.draw_minimap_corridors(full_rect.size, Map.map_to_world(Vector2(x, cave2.y-1)));
		else:
			if (Map.get_cell(x, cave2.y-1) == 0 or Map.get_cell(x, cave2.y-1) == 1 or Map.get_cell(x, cave2.y-1) == 2):
				set_front_tiles(x, cave2.y-1, "corridor", "normal", 0);
			Map.set_cell(x, cave2.y, 18);
			if (Map.get_cell(x, cave2.y+1) == 0 or Map.get_cell(x, cave2.y+1) == 1 or Map.get_cell(x, cave2.y+1) == 2):
				Map.set_cell(x, cave2.y+1, 5);
			HUD.draw_minimap_corridors(full_rect.size, Map.map_to_world(Vector2(x, cave2.y)));
	
	for y in range(cave1.y, cave2.y, y_diff):                #vertical part of path
		if cave2.x == cave1.x - cave1_adj.x + 1 or cave1.x == cave2.x - cave2_adj.x + 1:
			if x_diff<0:
				if Map.get_cell(cave1.x-2, y) == 0 or Map.get_cell(cave1.x-2, y) == 1 or Map.get_cell(cave1.x-2, y) == 2:
					Map.set_cell(cave1.x-2, y, 2);
				Map.set_cell(cave1.x-1, y, 18);
				if Map.get_cell(cave1.x, y) == 0 or Map.get_cell(cave1.x, y) == 1 or Map.get_cell(cave1.x, y) == 2:
					Map.set_cell(cave1.x, y, 1);
				HUD.draw_minimap_corridors(full_rect.size, Map.map_to_world(Vector2(cave1.x-1, y)));
			else:
				if Map.get_cell(cave1.x, y) == 0 or Map.get_cell(cave1.x, y) == 1 or Map.get_cell(cave1.x, y) == 2:
					Map.set_cell(cave1.x, y, 2);
				Map.set_cell(cave1.x+1, y, 18);
				if Map.get_cell(cave1.x+1, y) == 0 or Map.get_cell(cave1.x+1, y) == 1 or Map.get_cell(cave1.x+1, y) == 2:
					Map.set_cell(cave1.x+1, y, 1);
				HUD.draw_minimap_corridors(full_rect.size, Map.map_to_world(Vector2(cave1.x+1, y)));
		else:
			if Map.get_cell(cave1.x-1, y) == 0 or Map.get_cell(cave1.x-1, y) == 1 or Map.get_cell(cave1.x-1, y) == 2:
				Map.set_cell(cave1.x-1, y, 2);
			Map.set_cell(cave1.x, y, 18);
			if Map.get_cell(cave1.x+1, y) == 0 or Map.get_cell(cave1.x+1, y) == 1 or Map.get_cell(cave1.x+1, y) == 2:
				Map.set_cell(cave1.x+1, y, 1);
			HUD.draw_minimap_corridors(full_rect.size, Map.map_to_world(Vector2(cave1.x, y)));
	
	for y in range(cave1.y, cave2.y, y_diff):                     #corner tiles
		if y_diff < 0:
			if (Map.get_cell(cave1.x-1, y-1) == 15 or Map.get_cell(cave1.x-1, y-1) == 16 or Map.get_cell(cave1.x-1, y-1) == 17) and (Map.get_cell(cave1.x-1, y+1) == 0 or Map.get_cell(cave1.x-1, y+1) == 1 or Map.get_cell(cave1.x-1, y+1) == 2) and (Map.get_cell(cave1.x-2, y) == 0 or Map.get_cell(cave1.x-2, y) == 1 or Map.get_cell(cave1.x-2, y) == 2):
				Map.set_cell(cave1.x-1, y, 4);
			if (Map.get_cell(cave1.x+1, y-1) == 6 or Map.get_cell(cave1.x+1, y-1) == 7 or Map.get_cell(cave1.x+1, y-1) == 8) and (Map.get_cell(cave1.x+1, y+1) == 0 or Map.get_cell(cave1.x+1, y+1) == 1 or Map.get_cell(cave1.x+1, y+1) == 2) and (Map.get_cell(cave1.x+2, y) == 0 or Map.get_cell(cave1.x+2, y) == 1 or Map.get_cell(cave1.x+2, y) == 2):
				Map.set_cell(cave1.x+1, y, 3);
		else:
			if (Map.get_cell(cave1.x-1, y-1) == 0 or Map.get_cell(cave1.x-1, y-1) == 1 or Map.get_cell(cave1.x-1, y-1) == 2) and (Map.get_cell(cave1.x-1, y+1) == 15 or Map.get_cell(cave1.x-1, y+1) == 16 or Map.get_cell(cave1.x-1, y+1) == 17) and (Map.get_cell(cave1.x-2, y) == 0 or Map.get_cell(cave1.x-2, y) == 1 or Map.get_cell(cave1.x-2, y) == 2):
				set_front_tiles(cave1.x-1, y, "corner_tiles", "normal", 0);
			if (Map.get_cell(cave1.x+1, y-1) == 0 or Map.get_cell(cave1.x+1, y-1) == 1 or Map.get_cell(cave1.x+1, y-1) == 2) and (Map.get_cell(cave1.x+1, y+1) == 15 or Map.get_cell(cave1.x+1, y+1) == 16 or Map.get_cell(cave1.x+1, y+1) == 17) and (Map.get_cell(cave1.x+2, y) == 0 or Map.get_cell(cave1.x+2, y) == 1 or Map.get_cell(cave1.x+2, y) == 2):
				set_front_tiles(cave1.x+1, y, "corner_tiles", "normal", 0);

func set_front_tiles(x, y, room, type, room_id): 
	if room == "start_room" and type == "center":
		Map.set_cell(x, y-1, 12); #anim6, shopkeeper's special
		Map.set_cell(x, y, 25); 
	elif (room == "start_room" and (type == "corner_left" or type == "corner_right")) or (room == "boss_room" and (type == "corner_left" or type == "corner_right")) or (room == "summoning_room" and (type == "corner_left" or type == "corner_right")) or (room == "normal" and (type == "corner_left" or type == "corner_right")):
		Map.set_cell(x, y-1, 7, true if type == "corner_left" else false); #anim1, corner special
		Map.set_cell(x, y, 20, true if type == "corner_left" else false); 
	elif (room == "start_room" and type == "normal") or (room == "boss_room" and type == "normal") or (room == "summoning_room" and type == "normal") or (room == "normal" and type == "normal"):
		Map.set_cell(x, y-1, 6); #plain
		Map.set_cell(x, y, 19);
		if randf() > 0.5 and randf() <= 0.625 and global.room_front_tile_texture_container[room_id] and Map.get_cell(x-1, y) != 21 and Map.get_cell(x-1, y) != 22 and Map.get_cell(x-1, y) != 24 and Map.get_cell(x+1, y) != 21 and Map.get_cell(x+1, y) != 22 and Map.get_cell(x+1, y) != 24:
			global.room_front_tile_texture_container[room_id] -= 1; 
			Map.set_cell(x, y-1, 8); #anim2
			Map.set_cell(x, y, 21);  
		elif randf() > 0.625 and randf() <= 0.75 and global.room_front_tile_texture_container[room_id] and Map.get_cell(x-1, y) != 21 and Map.get_cell(x-1, y) != 22 and Map.get_cell(x-1, y) != 24 and Map.get_cell(x+1, y) != 21 and Map.get_cell(x+1, y) != 22 and Map.get_cell(x+1, y) != 24:
			global.room_front_tile_texture_container[room_id] -= 1; 
			Map.set_cell(x, y-1, 9); #anim3
			Map.set_cell(x, y, 22); 
		elif randf() > 0.75 and randf() <= 0.875: 
			Map.set_cell(x, y-1, 10); #anim4
			Map.set_cell(x, y, 23);  
		elif randf() > 0.875 and randf() <= 1 and global.room_front_tile_texture_container[room_id] and Map.get_cell(x-1, y) != 21 and Map.get_cell(x-1, y) != 22 and Map.get_cell(x-1, y) != 24 and Map.get_cell(x+1, y) != 21 and Map.get_cell(x+1, y) != 22 and Map.get_cell(x+1, y) != 24:
			global.room_front_tile_texture_container[room_id] -= 1; 
			Map.set_cell(x, y-1, 11); #anim5 
			Map.set_cell(x, y, 24);  
	elif (room == "boss_room" and type == "center") or (room == "summoning_room" and type == "center"):
		pass#Map.set_cell(x, y-1, 6); boss special
		#Map.set_cell(x, y, 6); 
	elif room == "corridor": 
		if toggler<2:
			toggler += 1;
			Map.set_cell(x, y-1, 6); #plain
			Map.set_cell(x, y, 19);
		else:
			toggler = 0;
			Map.set_cell(x, y-1, 10); #anim4
			Map.set_cell(x, y, 23);  
	elif room == "corner_tiles": 
		if type == "bottom_left": 
			if Map.get_cell(x, y-1) != 18:
				Map.set_cell(x, y-1, 13); #bottom left fixed torch 
			Map.set_cell(x, y, 26);  
		elif type == "bottom_right": 
			if Map.get_cell(x, y-1) != 18:
				Map.set_cell(x, y-1, 14); #bottom right fixed torch 
			Map.set_cell(x, y, 27);  

func obstacle_position_selection(room, s):
	match biome:
		"green_dungeon":
			return [(room.position / tile_size).floor() - s/2, Vector2((room.position.x/tile_size) - s.x/2, (room.position.y/tile_size) + s.y/2).floor(),
					(room.position / tile_size).floor() + s/2, Vector2((room.position.x/tile_size) + s.x/2, (room.position.y/tile_size) - s.y/2).floor()];
		"gemcave":
			return [room.position];

func initialize():
	var p = Particles2D.new();
	p.amount = 20;
	p.lifetime = 20;
	p.local_coords = false;
	p.position = Vector2(0, -300);
	p.process_material = load("res://particles_material/" + biome + ".tres");
	p.texture = load("res://art/particles/" + biome + ".png");
	camera.add_child(p);
	
	player.initialize(biome);
	
	music_player.set_stream(load("res://music/" + biome + ".wav"));
	
	HUD.initialize(biome);
	
	attach_tiles();
	
	shopkeeper.initialize(biome);
	
	var d = door.instance();
	d.initialise(biome);

func attach_tiles():
	var rates = {0: [10, (0.5 + randf())*4],
				 1: [10, (0.5 + randf())*4],
				 2: [10, (0.5 + randf())*4],
				 3: [10, (0.5 + randf())*4],
				 4: [5, 0],
				 5: [10, (0.5 + randf())*4],
				 6: [5, 0],
				 7: [5, 0],
				 8: [5, 0]};
	
	for i in range(global.biome_detail_coll_info[biome][0]):
		var coll = ConvexPolygonShape2D.new();
		coll.set_points(global.biome_detail_coll_info[biome][i+1]);
		detail.tile_set.tile_set_shapes(i, [coll]);
	for i in range(global.biome_detail_coll_info[biome][0], 11, 1):
		detail.tile_set.tile_set_z_index(i, -1);
	for i in range(global.biome_detail_texture_info[biome][0]):
		var s = AnimatedTexture.new();
		s.set_frames(5);
		s.set_fps(7);
		for j in range(5):
			s.set_frame_texture(j, load("res://art/tileset/" + biome + "/detail_anim1_" + String(j+1) + ".png"));
		detail.tile_set.tile_set_texture(i, s);
	for i in range(global.biome_detail_texture_info[biome][0], 11, 1):
		detail.tile_set.tile_set_texture(i, load("res://art/tileset/" + biome + "/detail_" + String(i) + ".png"));
	
	obstacles.tile_set.tile_set_texture(0, load("res://art/tileset/" + biome + "/obstacle.png"));
	var coll = ConvexPolygonShape2D.new();
	coll.set_points(global.biome_obstacle_coll_array[biome]);
	obstacles.tile_set.tile_set_shapes(0, [coll]);
	
	coll = ConvexPolygonShape2D.new();
	coll.set_points([Vector2(0, 0), Vector2(64, 0), Vector2(64, 64), Vector2(0, 64)]);
	for i in range(6):
		Map.tile_set.tile_set_texture(i, load("res://art/tileset/" + biome + "/" + texture_order[i] + ".png"));
		Map.tile_set.tile_set_z_index(i, 1);
		Map.tile_set.tile_set_shapes(i, [coll]);
	for i in range(6, 15, 1):
		var s = AnimatedTexture.new();
		s.set_frames(5);
		s.set_fps(rates[(i-6)][0]);
		s.set_frame_delay(0, rates[(i-6)][1]);
		for j in range(5):
			s.set_frame_texture(j, load("res://art/tileset/" + biome + "/" + texture_order[i] + String(j+1) + ".png"));
		Map.tile_set.tile_set_texture(i, s);
		Map.tile_set.tile_set_shapes(i, [coll]);
	
	for i in range(15, 19, 1):
		Map.tile_set.tile_set_texture(i, load("res://art/tileset/" + biome + "/" + texture_order[i] + ".png"));
		Map.tile_set.tile_set_z_index(i, -1);
	
	coll = ConvexPolygonShape2D.new();
	coll.set_points([Vector2(0, 0), Vector2(64, 0), Vector2(64, 28), Vector2(0, 28)]);
	for i in range(19, 28, 1):
		var s = AnimatedTexture.new();
		s.set_frames(5);
		s.set_fps(rates[(i-19)][0]);
		s.set_frame_delay(0, rates[(i-19)][1]);
		for j in range(5):
			s.set_frame_texture(j, load("res://art/tileset/" + biome + "/" + texture_order[i] + String(j+1) + ".png"));
		Map.tile_set.tile_set_texture(i, s);
		Map.tile_set.tile_set_shapes(i, [coll]);
	
	#for i in range(28, 32, 1):
	#	var s = AnimatedTexture.new();
	#	s.set_frames(5);
	#	s.set_fps(5);
	#	s.set_frame_delay(0, 0);
	#	for j in range(5):
	#		s.set_frame_texture(j, load("res://art/tileset/" + biome + "/" + global.biome_special_tile[biome][i-28] + String(j+1) + ".png"));
	#	Map.tile_set.tile_set_texture(i, s);
	#	Map.tile_set.tile_set_shapes(i, [coll]);

func show_miniroom_connections(room):
	var room_positions := [];                          #CONVERTING COORDINATES INTO VECTOR2 BCOZ JSON SUCKS
	for i in room_pos_x.size():
		room_positions.append(Vector2(room_pos_x[i], room_pos_y[i]));
	$HUD/minimap.get_child(room_container.get_children().find(room)).show();
	$HUD/minimap.get_child(room_container.get_children().find(room)).modulate = Color(0, 0.5, 0.5);
	var p = path.get_closest_point(room.position);
	for conn in path.get_point_connections(p):                       #finding attached rooms of explored room
		$HUD/minimap.get_child(room_positions.find(path.get_point_position(conn))).show();
		var room1tpos;
		var room2tpos;
		if room_positions.find(room.position) < room_positions.find(path.get_point_position(conn)):
			room1tpos = Map.world_to_map(room.position);
			room2tpos = Map.world_to_map(path.get_point_position(conn));
		else:
			room1tpos = Map.world_to_map(path.get_point_position(conn));
			room2tpos = Map.world_to_map(room.position);
		for x in range(room1tpos.x, room2tpos.x, sign(room2tpos.x - room1tpos.x)):
			HUD.show_minimap_corridor(full_rect.size, Map.map_to_world(Vector2(x, room2tpos.y)));
		for y in range(room1tpos.y, room2tpos.y, sign(room2tpos.y - room1tpos.y)):     
			HUD.show_minimap_corridor(full_rect.size, Map.map_to_world(Vector2(room1tpos.x, y)));

func find_start_room():
	var min_x = INF
	for room in room_container.get_children():
		if room.position.x < min_x:
			start_room = room;
			min_x = room.position.x;
	for weapon in get_tree().get_nodes_in_group(String(start_room.get_instance_id()) + "weapon"):
		weapon.queue_free();
	for enemy in get_tree().get_nodes_in_group(String(start_room.get_instance_id()) + "enemy"):
		enemy.queue_free();
	shopkeeper.position = start_room.position - Vector2(0, 100);# - start_room.size + Map.map_to_world(Vector2(2, 2));
	#set_front_tiles(Map.world_to_map(shopkeeper.position).x, Map.world_to_map(shopkeeper.position).y, "start_room", "center", start_room.get_instance_id());

func find_end_room():
	var max_x = -INF
	for room in room_container.get_children():
		if room.position.x > max_x:
			end_room = room;
			max_x = room.position.x;
	for weapon in get_tree().get_nodes_in_group(String(start_room.get_instance_id()) + "weapon"):
		weapon.queue_free();
	for enemy in get_tree().get_nodes_in_group(String(start_room.get_instance_id()) + "enemy"):
		enemy.queue_free();

func spawn_weapon(room, w_pos):
	var pos = obstacles.world_to_map(w_pos);
	var res = true;
	for i in range(-1, 2, 1):
		for j in range(-1, 2, 1):
			if obstacles.get_cell(pos.x + i, pos.y + j) != -1:
				res = false;
	if res:
		var w = weapons.instance();
		detail.add_child(w);
		w.add_to_group(String(room.get_instance_id()) + "weapon");
		var type = global.weapon_string[(randi() %  4) + 1];
		w.set_z_index(2);
		w.type_assign(type);
		w.ammo_assign(type);
		player.connect("weapon_pickup", w, "on_pickup_signal");
		player.connect("weapon_combine", w, "on_combine_signal");
		w.connect("start_interact_notifier", HUD, "_on_weapon_start_interact_notifier");
		w.connect("stop_interact_notifier", HUD, "_on_stop_interact_notifier");
		w.connect("cant_be_combined", player, "cant_be_combined");
		w.connect("complete_combine", player, "complete_combine");
		w.position = room.global_position + w_pos;
	else:
		w_pos = Vector2((randf()+0.1) * room.size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * room.size.y/2 * (pow(-1, randi() % 2)));
		spawn_weapon(room, w_pos);

func spawn_enemy(room, e_pos, cls):
	var pos = obstacles.world_to_map(e_pos);
	var res = true;
	for i in range(-1, 2, 1):
		for j in range(-1, 2, 1):
			if obstacles.get_cell(pos.x + i, pos.y + j) != -1:
				res = false;
	if res:
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
		detail.add_child(a);
		a.add_to_group(String(room.get_instance_id()) + "enemy");
		a.init(global.biome_enemy[biome][cls], e_pos + room.global_position);
		a.timer.paused = true;
		a.connect("release_coins", room, "coin_release");
		a.connect("clear_arrays", room, "arrays_clear");
		room.enemy_array.append(a);
		room.number_of_spawns += 1;
	else:
		e_pos = Vector2((randf()+0.1) * room.size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * room.size.y/2 * (pow(-1, randi() % 2)));
		spawn_enemy(room, e_pos, cls);

func reposition_weapon(wpn, room):
	var allowed = false;
	var w_pos;
	while(not allowed):
		w_pos = Vector2((randf()+0.1) * room.size.x/2 * (pow(-1, randi() % 2)), (randf()+0.1) * room.size.y/2 * (pow(-1, randi() % 2)));
		for i in get_tree().get_nodes_in_group(String(room.get_instance_id()) + "weapon"):
			if wpn!=i and (room.position + w_pos).distance_to(i.position) >= 1000:
				continue;
			elif i == room.weapon_container.get_child(room.weapon_container.get_child_count() - 1):
				allowed = true;
	return w_pos;

func connect_signals():
# warning-ignore:return_value_discarded
	shopkeeper.connect("start_interact_notifier", HUD, "_on_shopkeeper_start_interact_notifier");
# warning-ignore:return_value_discarded
	shopkeeper.connect("stop_interact_notifier", HUD, "_on_shopkeeper_stop_interact_notifier");
# warning-ignore:return_value_discarded
	HUD.connect("leave_shop", self, "_on_player_zoom_out");
# warning-ignore:return_value_discarded
	player.connect("zoom_in", self, "_on_player_zoom_in");
# warning-ignore:return_value_discarded
	player.connect("zoom_out", self, "_on_player_zoom_out");
# warning-ignore:return_value_discarded	
	player.connect("blood_requested", HUD, "_on_player_blood_requested");
# warning-ignore:return_value_discarded
	player.connect("display_out_of_ammo", HUD, "_on_player_display_out_of_ammo");
# warning-ignore:return_value_discarded
	player.connect("hide_pickup", HUD, "_on_player_hide_pickup");
# warning-ignore:return_value_discarded
	player.connect("screen_shake_requested", camera.get_node("screenshake"), "_on_player_screen_shake_requested");
# warning-ignore:return_value_discarded
	player.connect("player_has_fallen", HUD, "show_end_game_panel");
# warning-ignore:return_value_discarded
	$HUD/end_game/VBoxContainer/HBoxContainer/try_again.connect("pressed", self, "restart_game");
# warning-ignore:return_value_discarded
	$HUD/end_game/VBoxContainer/HBoxContainer/quit.connect("pressed", self, "end_game");
	
	HUD.player = player;

func connect_rooms():
	for room in room_container.get_children():
		room.player = player;
		room.connect("new_archive_entry", HUD, "archive_popup");
		if room != start_room and room != end_room:
			for child in get_tree().get_nodes_in_group(String(room.get_instance_id()) + "weapon"):
				child.player = player;
			for child in get_tree().get_nodes_in_group(String(room.get_instance_id()) + "enemy"):
				child.player = player;

func restart_game():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://scenes/character_selection.tscn");

func end_game():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://scenes/main_menu.tscn");

func prepare_end():
	if current_room != null:
		current_room.set_process(false);
		for enemy in detail.get_children():
			enemy.STATE_LOCK = false;
			enemy.STATE = "CELEBRATE";
	HUD.set_process_input(false);
	player.set_process_input(false);
	HUD.show_notifier("String(level/5 + 1) + ' - ' + String(level % 5 + 1)", Color(1, 0, 0));
	$HUD/player_hp.hide();
	$HUD/gold.hide();
	$HUD/ammo.hide();

func find_mst(nodes):
# warning-ignore:shadowed_variable
	var path = AStar2D.new();
	path.add_point(path.get_available_point_id(), nodes.pop_front());
	while nodes:
		var min_dist = INF;
		var min_p = null;
		var p = null;
		for p1 in path.get_points():
			p1 = path.get_point_position(p1);
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2);
					min_p = p2;
					p = p1;
		var n = path.get_available_point_id();
		path.add_point(n, min_p);
		path.connect_points(path.get_closest_point(p), n);
		nodes.erase(min_p);
	return path;

func cleanup():
	var topleft = Map.world_to_map(full_rect.position);               #CLEARING WORLD TILES
	var bottomright = Map.world_to_map(full_rect.end);
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, -1);
			detail.set_cell(x, y, -1);
			obstacles.set_cell(x, y, -1);
	for room in room_container.get_children():                        #CLEARING ROOM CONTAINER
		global.room_front_tile_texture_container.erase(room.get_instance_id());
		for i in get_tree().get_nodes_in_group(String(room.get_instance_id()) + "weapon"):
			i.queue_free();
		for i in get_tree().get_nodes_in_group(String(room.get_instance_id()) + "coin"):
			i.queue_free();
		room.queue_free();
	HUD.clear_minimap();                               #CLEARING THE MINIMAP

func save():
	var save_dict = {
		"name": get_name(),
		"room_pos_x": room_pos_x,
		"room_pos_y": room_pos_y,
		"room_status": room_status,
		"player_position_x": player_position_x,
		"player_position_y": player_position_y,
		"room_sizes": room_sizes,
		"biome": biome
	};
	return save_dict;

func _on_player_zoom_in():
	HUD.enter_shop();
	camera.get_node("zoom").interpolate_property(camera, "zoom", Vector2(1, 1), Vector2(0.5, 0.5), 0.7, Tween.TRANS_EXPO, Tween.EASE_OUT); 
	camera.get_node("zoom").start();
	player.set_physics_process(false);

func _on_player_zoom_out():
	HUD.leave_shop();
	player.is_shopping = false;
	camera.get_node("zoom").interpolate_property(camera, "zoom", Vector2(0.5, 0.5), Vector2(1, 1), 0.7, Tween.TRANS_EXPO, Tween.EASE_OUT); 
	camera.get_node("zoom").start();
	player.set_physics_process(true);

func spawn_door(x, y, room, angle):
	var d = door.instance();
	room.door_container.add_child(d);
	d.init(Map.map_to_world(Vector2(x, y)) + Vector2(tile_size/2, tile_size/2), angle);

func savegame():
	var save_game = File.new();
	save_game.open("user://savegame.save", File.WRITE);
	var save_nodes = [];
	save_nodes.append(main);
	for s in get_tree().get_nodes_in_group("persist"):
		save_nodes.append(s);
	for node in save_nodes:
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name);
			continue;
		var node_data = node.call("save");
		save_game.store_line(to_json(node_data));
	save_game.close();

func loadgame():
	var save_game = File.new();
	if not save_game.file_exists("user://savegame.save"):
		return;
	var save_nodes = get_tree().get_nodes_in_group("persist");
	var i = 0;
	save_game.open("user://savegame.save", File.READ);
	var node_data = parse_json(save_game.get_line());
	while save_game.get_position() < save_game.get_len():
		node_data = parse_json(save_game.get_line());
		if node_data["name"] == "InputMapper" or node_data["name"] == "weapon":
			save_nodes[i].set_all(node_data);
		else:
			for j in node_data.keys():
				save_nodes[i].set(j, node_data[j]);
		i += 1;
	save_game.close();
