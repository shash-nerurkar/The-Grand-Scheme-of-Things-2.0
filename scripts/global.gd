extends Node

var SFX_nodes := [];

var biome_name := {"gemcave": "Patthar ki duniya",
				   "green_dungeon": "crack den vibes"};

var biome := ["gemcave", "green_dungeon"];

var biome_enemy := {"green_dungeon": {"MINION": 'gabhrain',
									  "ASSASSIN": 'gondurr',
									  "BIG": 'hordor',
									  "TWOSTAGE_MELEE": 'corth'},
					"gemcave": {"MINION": 'vodok',
								"BIG": 'lloyd',
								"ASSASSIN": 'slugpine',
								"BURST": 'bryn',
								"MELEE": 'badhril'}};

var spawn_num := {"MINION": 4,
				  "BIG": 1,
				  "ASSASSIN": 2,
				  "BURST": 3,
				  "MELEE": 3,
				  "TWOSTAGE_MELEE": 1};

var biome_tip = {"green_dungeon": ["The corrupted knight does massive damage. Don't get too close to him."],
				 "gemcave": ["The slugpine are deceptively heavy. Pick them out early in the room to avoid getting chain-locked in crowd control."]};

var biome_obstacle_coll_array = {"green_dungeon": [Vector2(30, 83), Vector2(160, 83), Vector2(160, 158), Vector2(30, 158)],
								 "gemcave": [Vector2(30, 83), Vector2(160, 83), Vector2(160, 158), Vector2(30, 158)]};

var biome_detail_texture_info = {"green_dungeon": [1],
								 "gemcave": [1]};

var biome_detail_coll_info = {"green_dungeon": [4, 
												[Vector2(75, 80), Vector2(118, 80), Vector2(118, 95), Vector2(75, 95)], 
												[Vector2(65, 60), Vector2(122, 60), Vector2(122, 85), Vector2(65, 85)],
												[Vector2(80, 80), Vector2(112, 80), Vector2(112, 90), Vector2(80, 90)], 
												[Vector2(80, 80), Vector2(112, 80), Vector2(112, 90), Vector2(80, 90)]],
							  "gemcave": [4, 
										  [Vector2(75, 80), Vector2(118, 80), Vector2(118, 95), Vector2(75, 95)], 
										  [Vector2(65, 60), Vector2(122, 60), Vector2(122, 85), Vector2(65, 85)],
										  [Vector2(80, 80), Vector2(112, 80), Vector2(112, 90), Vector2(80, 90)], 
										  [Vector2(80, 80), Vector2(112, 80), Vector2(112, 90), Vector2(80, 90)]]};

var biome_special_tile := {"green_dungeon": ["wall_bottom_left_top_", "wall_bottom_right_top_", 
											 "wall_front_bot_bottom_left_top_", "wall_front_bot_bottom_right_top_"],
						   "gemcave": []};

var enemy_info := {"vodok": "shoots 2 bullets, which do high damage if hit together",
				   "lloyd": "fires a massive laser",
				   "badhril": "dashes horn-first",
				   "slugpine": "jumps onto the player",
				   "bryn": "shoots multiple bullets in quick succession",
				   "gabhrain": "belches vomit at the player",
				   "gondurr": "runs into the player and explodes",
				   "hordor": "his bullets slow the character",
				   "corth": "He has two types of attacks, one of which is short ranged, but does massive damage"};

var room_front_tile_texture_container = {};

var room_size_class := {Vector2(-1, -1): "0",
						Vector2(-1,  0): "1",
						Vector2( 0, -1): "2",
						Vector2( 0,  0): "3",
						Vector2( 1,  0): "4",
						Vector2( 0,  1): "5",
						Vector2( 0,  2): "6",
						Vector2( 2,  0): "7",
						Vector2( 3,  3): "8"};

var room_size := {"0": Vector2(-1, -1),
				  "1": Vector2(-1,  0),
				  "2": Vector2( 0, -1),
				  "3": Vector2( 0,  0),
				  "4": Vector2( 1,  0),
				  "5": Vector2( 0,  1),
				  "6": Vector2( 0,  2),
				  "7": Vector2( 2,  0),
				  "8": Vector2( 3,  3)};


var enemy_list={0: 'vodok',
				1: 'badhril',
				2: 'bryn',
				3: 'slugpine',
				4: 'lloyd',
				5: 'gabhrain',
				6: 'gondurr',
				7: 'hordor',
				8: 'corth'};

#ENEMY BASE STATS
var enemy_class = {'vodok': 'MINION',
				   'lloyd': 'BIG',
				   'slugpine': 'ASSASSIN',
				   'badhril': 'MELEE',
				   'bryn': 'BURST',
				   'gabhrain': 'MINION',
				   'gondurr': 'ASSASSIN',
				   'hordor': 'BIG',
				   'corth': 'TWOSTAGE_MELEE'};

var enemy_scale = {'vodok': Vector2(1.5, 1.5),
				   'lloyd': Vector2(1.5, 1.5),
				   'slugpine': Vector2(.5, .5),
				   'badhril': Vector2(1.25, 1.25),
				   'bryn': Vector2(1, 1),
				   'gabhrain': Vector2(1.5, 1.5),
				   'gondurr': Vector2(2, 2),
				   'hordor': Vector2(2, 2),
				   'corth': Vector2(1.5, 1.5)};

var min_range = {'vodok': 200,
				 'lloyd': 1000,
				 'badhril': 200,
				 'bryn': 250,
				 'gabhrain': 200,
				 'hordor': 400,
				 'corth': 200};

var max_range = {'vodok': 900,
				 'lloyd': 1300,
				 'badhril': 200,
				 'bryn': 250,
				 'gabhrain': 900,
				 'hordor': 500,
				 'corth': 200};

var activation_range := {'vodok': 2500,
						 'lloyd': 1500,
						 'slugpine': 250,
						 'badhril': 500,
						 'bryn': 500,
						 'gabhrain': 2500,
						 'gondurr': 300,
						 'hordor': 900,
						 'corth': 700};

var enemy_range_2 := {'corth': 100};

var enemy_health = {'vodok': 20,
					'lloyd': 30,
					'slugpine': 7,
					'badhril': 25,
					'bryn': 9,
					'gabhrain': 30,
					'gondurr': 15,
					'hordor': 50,
					'corth': 40};

var enemy_shoot_cooldown = {'vodok': 4,
							'lloyd': 8,
							'slugpine': 3,
							'badhril': 2,
							'bryn': 1,
							'gabhrain': 5,
							'gondurr': .1,
							'hordor': 5,
							'corth': 3};

var enemy_damage = {'vodok': 8,
					'vodok_small': 3,
					'vodok_big': 5,
					'lloyd': 10,
					'slugpine': 2,
					'bryn': 2, 
					'badhril': 7,
					'gabhrain': 5,
					'gondurr': 15,
					'hordor': 3,
					'corth': 10};

var enemy_speed = {'vodok': 175,
				   'lloyd': 100,
				   'slugpine': 300,
				   'badhril': 225,
				   'bryn': 350,
				   'gabhrain': 125,
				   'gondurr': 250,
				   'hordor': 150,
				   'corth': 100};

var enemy_debuff_type := {'badhril'    : "knock_back",
						  'bryn'       : "none",
						  'corth'      : "knock_back",
						  'gabhrain'   : "none",
						  'ghot'       : "none",
						  'gondurr'    : "knock_back",
						  'hordor'     : "slow",
						  'lloyd'      : "none",
						  'slugpine'   : "knock_back",
						  'vodok_small': "none",
						  'vodok_big'  : "none"};

var enemy_debuff_amount := {'badhril'    : 0.0,
							'bryn'       : 0.0,
							'corth'      : 0.0,
							'gabhrain'   : 0.0,
							'ghot'       : 0.0,
							'gondurr'    : 0.0,
							'hordor'     : 0.2,
							'lloyd'      : 0.0,
							'slugpine'   : 0.0,
							'vodok_small': 0.0,
							'vodok_big'  : 0.0};

var enemy_debuff_duration := {'badhril'    : 0.0,
							  'bryn'       : 0.0,
							  'corth'      : 0.0,
							  'gabhrain'   : 0.0,
							  'ghot'       : 0.0,
							  'gondurr'    : 0.0,
							  'hordor'     : 3.0,
							  'lloyd'      : 0.0,
							  'slugpine'   : 0.0,
							  'vodok_small': 0.0,
							  'vodok_big'  : 0.0};

var knockback_amount = {'slugpine': 3,
						'badhril': 2,
						'gondurr': 3,
						'corth': 2};

var knockback_duration = {'slugpine': 0.2,
						  'badhril': 0.1,
						  'gondurr': 0.1,
						  'corth': 0.1};

var dash_duration = {'badhril': 0.5};

var dash_speed = {'badhril': 400};


#OUTER COLLISION SHAPE STATS
var enemy_coll_shape = {'vodok': 'CAPSULE',
						'lloyd': 'CAPSULE',
						'slugpine': 'RECTANGLE',
						'badhril': 'CAPSULE',
						'bryn': 'CAPSULE',
						'gabhrain': 'CAPSULE',
						'gondurr': 'CAPSULE',
						'hordor': 'CIRCLE',
						'corth': 'CAPSULE'};

var enemy_coll_pos = {'vodok': Vector2(-3.4, .6),
					  'lloyd': Vector2(),
					  'slugpine': Vector2(-0.5, -2),
					  'badhril': Vector2(-4.2, -1.5),
					  'bryn': Vector2(0.3, -60),
					  'gabhrain': Vector2(0, 2.5),
					  'gondurr': Vector2(-2, -13.2),
					  'hordor': Vector2(1.6, -0.2),
					  'corth': Vector2(-6.6, -2.1)};

var enemy_flipped_coll_pos = {'vodok': Vector2(3.1, 0.9),
							  'lloyd': Vector2(),
							  'badhril': Vector2(3.8, 2.3),
							  'slugpine': Vector2(-0.5, -2),
							  'bryn': Vector2(-2.3, -60),
							  'gabhrain': Vector2(0, 2.5),
							  'gondurr': Vector2(0, -13.2),
							  'hordor': Vector2(-7.2, -6.2),
							  'corth': Vector2(6.3, -1.6)};

var enemy_coll_rot = {'vodok': 0,
					  'lloyd': 0,
					  'slugpine': 0,
					  'badhril': -65,
					  'bryn': -77.6,
					  'gabhrain': 0,
					  'gondurr': 0,
					  'hordor': 0,
					  'corth': 0};

var enemy_rad  = {'vodok': 4,
				  'lloyd': 8,
				  'badhril': 11.4,
				  'bryn': 10.2,
				  'gabhrain': 8,
				  'gondurr': 14.6,
				  'hordor': 21.5,
				  'corth': 22};

var enemy_height = {'vodok': 20,
					'lloyd': 20.5,
					'badhril': 22.9,
					'bryn': 15.1,
					'gabhrain': 12.6,
					'gondurr': 33.5,
					'corth': 30.3};

var enemy_extents = {'slugpine': Vector2(18.7, 6.1)};


#INNER COLLISION SHAPE STATS
var enemy_inner_coll_pos = {'vodok': Vector2(-3.2, 14),
							'lloyd': Vector2(-0.5, -0.4),
							'badhril': Vector2(-9.2, 15.4),
							'slugpine': Vector2(-0.7, 13.8),
							'bryn': Vector2(-0.5, 19.3),
							'gabhrain': Vector2(-0.16, 15.8),
							'gondurr': Vector2(0, 15),
							'hordor': Vector2(-13, 36),
							'corth': Vector2(-6, 36)};

var enemy_inner_flipped_coll_pos = {'vodok': Vector2(2.8, 14.3),
									'lloyd': Vector2(0.5, -0.4),
									'badhril': Vector2(8.9, 14.7),
									'slugpine': Vector2(-0.7, 13.8),
									'bryn': Vector2(-0.5, 19.3),
									'gabhrain': Vector2(-0.16, 15.8),
									'gondurr': Vector2(0, 15),
									'hordor': Vector2(12.4, 36.2),
									'corth': Vector2(6, 36)};


#MUZZLE POSITION
var muzzle_pos = {'vodok': Vector2(0.8, 6.1),
				  'bryn': Vector2(11.5, -35.7),
				  'gabhrain': Vector2()};

var muzzle_flipped_pos = {'vodok': Vector2(-1.8, 6.1),
						  'bryn': Vector2(-10.2, -35.7),
						  'gabhrain': Vector2()};


#HEALTH BAR AND COOLDOWN INDICATOR STATS
var health_bar_pos = {'vodok': Vector2(-11.9, -19.3),
					  'lloyd': Vector2(-18.2, -25.9),
					  'slugpine': Vector2(-15.8, -20.4),
					  'badhril': Vector2(-27.3, -25.4),
					  'bryn': Vector2(-21.2, -87),
					  'gabhrain': Vector2(-12.2, -22.6),
					  'gondurr': Vector2(-25, -51.8),
					  'hordor': Vector2(-28, -40),
					  'corth': Vector2(-34.4, -50.1)};

var health_bar_flipped_pos = {'vodok': Vector2(-6.3, -19.5),
							  'lloyd': Vector2(-17.3, -25.9),
							  'badhril': Vector2(-16.7, -25.4),
							  'slugpine': Vector2(-19.2, -20),
							  'bryn': Vector2(-16, -61.4),
							  'gabhrain': Vector2(-12.2, -22.6),
							  'gondurr': Vector2(-20.8, -51.8),
							  'hordor': Vector2(-24.7, -40),
							  'corth': Vector2(-25.3, -50.1)};

var health_bar_scale = {'vodok': Vector2(1, 1),
						'lloyd': Vector2(2, 1),
						'slugpine': Vector2(2, 1),
						'badhril': Vector2(2.5, 1),
						'bryn': Vector2(1.5, 1),
						'gabhrain': Vector2(1.3, 1),
						'gondurr': Vector2(2.5, 1),
						'hordor': Vector2(3, 1),
						'corth': Vector2(3.5, 1.5)};

var cd_indicator_pos = {'vodok': Vector2(-13.2, 13.5),
						'lloyd': Vector2(-17.7, 18),
						'slugpine': Vector2(-27.3, 6.3),
						'badhril': Vector2(-32.9, 10),
						'bryn': Vector2(-20, 15.5),
						'gabhrain': Vector2(-14.1, 13.5),
						'gondurr': Vector2(-19.3, 13.6),
						'hordor': Vector2(-26.8, 32.3),
						'corth': Vector2(-31.9, 28.9)};

var cd_indicator_flipped_pos = {'vodok': Vector2(-7, 13),
								'lloyd': Vector2(-16.7, 18),
								'badhril': Vector2(-16, 9.5),
								'slugpine': Vector2(-29.1, 6),
								'bryn': Vector2(-20, 15.5),
								'gabhrain': Vector2(-14.1, 13.5),
								'gondurr': Vector2(-20.7, 13.57),
								'hordor': Vector2(-0.8, 32),
								'corth': Vector2(-23.6, 28.7)};

var cd_indicator_scale = {'vodok': Vector2(0.05, 0.05),
						  'lloyd': Vector2(0.09, 0.09),
						  'slugpine': Vector2(0.14, 0.14),
						  'badhril': Vector2(0.12, 0.12),
						  'bryn': Vector2(0.1, 0.1),
						  'gabhrain': Vector2(0.07, 0.07),
						  'gondurr': Vector2(0.1, 0.1),
						  'hordor': Vector2(0.07, 0.07),
						  'corth': Vector2(0.14, 0.14)};


#MELEE WEAPON COLLISION STATS
var melee_coll_shape = {'badhril': 'CAPSULE',
						'slugpine': 'CAPSULE',
						'gondurr': 'CAPSULE'};

var melee_coll_pos = {'badhril': Vector2(38.4, 1),
					  'slugpine': Vector2(2.3, 2.2),
					  'gondurr': Vector2(-2, -13.2)};

var melee_flipped_coll_pos = {'badhril': Vector2(-38.4, 1),
							  'slugpine': Vector2(2.3, 2.2),
							  'gondurr': Vector2(0, -13.2)};

var melee_coll_rad = {'badhril': 7.6,
					  'slugpine': 9.9,
					  'gondurr': 14.6};

var melee_coll_height = {'badhril': 35,
						 'slugpine': 19.7,
						 'gondurr': 33.5};

var melee_coll_extents = {};

var melee_coll_rot = {'badhril': 0,
					  'slugpine': 0,
					  'gondurr': 0};

var melee_coll_1st_shape = {'corth': 'CIRCLE'};

var melee_coll_1st_pos = {'corth': Vector2(1, 3)};

var melee_flipped_coll_1st_pos = {'corth': Vector2(0, 3)};

var melee_coll_1st_rad = {'corth': 63.5};

var melee_coll_1st_height = {};

var melee_coll_1st_extents = {};

var melee_coll_1st_rot = {'corth': 0};

var melee_coll_2nd_shape = {'corth': 'CAPSULE'};

var melee_coll_2nd_pos = {'corth': Vector2(70, 3.4)};

var melee_flipped_coll_2nd_pos = {'corth': Vector2(-70, 3.4)};

var melee_coll_2nd_rad = {'corth': 45.2};

var melee_coll_2nd_height = {'corth': 61.1};

var melee_coll_2nd_extents = {};

var melee_coll_2nd_rot = {'corth': 90};


#LASER STATS
var laser_pos = {'lloyd': Vector2(27.9, 0.8)};

var laser_flipped_pos = {'lloyd': Vector2(-29, 1.4)};


#BULLET STATS
var enemy_bullet_scale = {};

var enemy_bullet_coll_shape= {'bryn': 'CAPSULE',
							  'vodok_big': 'CAPSULE',
							  'vodok_small': 'CAPSULE',
							  'gabhrain': 'CIRCLE',
							  'hordor': 'CIRCLE'};

var enemy_bullet_coll_pos = {'bryn': Vector2(-10, 4.2),
							 'vodok_big': Vector2(0.1, 1.4),
							 'vodok_small': Vector2(0.1, 1.4),
							 'gabhrain': Vector2(0, 0.5),
							 'hordor': Vector2(0, 0.5)};

var enemy_bullet_coll_rad = {'bryn': 4.3,
							 'vodok_big': 2.9,
							 'vodok_small': 2.9,
							 'gabhrain': 4,
							 'hordor': 27};

var enemy_bullet_coll_height = {'bryn': 28.7,
								'vodok_big': 10.1,
								'vodok_small': 3.9,};

var enemy_bullet_coll_extents = {};


#ENEMY CATEGORIES
var bezier_enemy = ['slugpine'];

var flying_enemy = ['bryn', 'hordor'];

var dash_enemy = ['badhril', 'gondurr'];

var scent_enemy = [];


#ENEMY ANIMATION FRAMES AND FRAMERATES
var idle_frames := {'badhril' : [6, 6],
					'bryn' : [7, 6],
					'corth' : [5, 5],
					'gabhrain' : [8, 8],
					'ghot' : [],
					'gondurr' : [4, 5],
					'hordor' : [7, 5],
					'lloyd' : [2, 4],
					'slugpine' : [1, 5],
					'vodok' : [2, 4]};

var happy_frames := {'badhril' : [4, 5],
					 'bryn' : [7, 7],
					 'corth' : [2, 3],
					 'gabhrain' : [8, 8],
					 'ghot' : [],
					 'gondurr' : [4, 5],
					 'hordor' : [5, 5],
					 'lloyd' : [3, 4],
					 'slugpine' : [3, 5],
					 'vodok' : [2, 5]};

var run_frames := {'badhril' : [8, 12],
				   'bryn' : [7, 6],
				   'corth' : [10, 8],
				   'gabhrain' : [8, 7],
				   'ghot' : [],
				   'gondurr' : [11, 15],
				   'hordor' : [6, 7],
				   'lloyd' : [6, 7],
				   'slugpine' : [6, 5],
				   'vodok' : [6, 8]};

var spawn_frames := {'badhril' : [17, 15],
					 'bryn' : [7, 10],
					 'corth' : [25, 15],
					 'gabhrain' : [24, 15],
					 'ghot' : [],
					 'gondurr' : [25, 15],
					 'hordor' : [24, 20],
					 'lloyd' : [16, 15],
					 'slugpine' : [1, 5],
					 'vodok' : [15, 15]};

var death_frames := {'badhril' : [5, 8],
					 'bryn' : [8, 13],
					 'corth' : [17, 10],
					 'gabhrain' : [12, 10],
					 'ghot' : [],
					 'gondurr' : [15, 20],
					 'hordor' : [8, 12],
					 'lloyd' : [7, 8],
					 'slugpine' : [7, 10],
					 'vodok' : [14, 10]};

var laser_frames := {'lloyd' : [4, 8]};

var laser_2_frames := {'lloyd' : [17, 12]};

var shoot_frames := {'bryn' : [8, 6],
					 'gabhrain' : [8, 10],
					 'ghot' : [],
					 'hordor' : [2, 5]};

var shoot_2_frames := {};

var reload_frames := {'vodok' : [6, 10]};

var attack_frames := {'badhril' : [2, 2],
					  'gondurr' : [11, 15],
					  'slugpine' : [16, 25]};

var attack_2_frames := {'badhril' : [7, 23]};

var attack_1st_frames := {'corth' : [8, 10]};

var attack_2nd_frames := {'corth' : [7, 10]};


#PLAYER WEAPON STATS
var weapon_info := {"pistol": "simple sidearm",
					"shotgun": "fires bullets in a cone",
					"machine_gun": "highest firerate but inaccurate",
					"musket": "very high damage but fires slowly",
					"gatling_gun": "more balanced rate of firing and damage"};

var weapon_string = {1: "pistol", 
					 2: "shotgun",
					 3: "musket",
					 4: "machine_gun",
					 5: "gatling_gun"};

var weapon_tier = {"machine_gun": 1,
				   "pistol": 0,
				   "shotgun": 1};

var tier_combo = {4: [0,1],
				  3: [0,1],
				  2: [0,1],
				  1: [4,3,2,0],
				  0: [4,3,2,1]};

var is_combo = ["gatling_gun", "musket"];

var weapon_damage = {"pistol": 3, 
					 "machine_gun": 2, 
					 "shotgun": 2, 
					 "musket": 6,
					 "gatling_gun": 3};

var weapon_firerate = {"pistol": 0.5, 
					   "machine_gun": 0.15, 
					   "shotgun": 0.7,
					   "musket": 0.9,
					   "gatling_gun": 0.20};

var weapon_crit = {"pistol": 0.3, 
				   "shotgun": 0.2, 
				   "musket": 0.7,
				   "machine_gun": 0.15,
				   "gatling_gun": 0.2};

var weapon_ammo = {"pistol": 24, 
				   "machine_gun": 80,
				   "gatling_gun": 70, 
				   "shotgun": 800, 
				   "musket": 12};

var weapon_accuracy = {"pistol": 0.05, 
					   "shotgun": 0, 
					   "musket": 0.01,
					   "machine_gun": 0.08,
					   "gatling_gun": 0.1};

var weapon_weight = {"pistol": 0, 
					 "shotgun": 10, 
					 "musket": 5,
					 "machine_gun": 40,
					 "gatling_gun": 20};

var weapon_x = {"pistol": Vector2(4.196, 3.542),
				"gatling_gun": Vector2(23.226, 1.436),
				"shotgun": Vector2(14.337, 4.792),
				"m4a1": Vector2(13.126, 5.605),
				"musket": Vector2(34.539, 12.7),
				"machine_gun": Vector2(23.005, 3.087),};

var weapon_muzzle_x = {"pistol": 19.42,
					   "gatling_gun": 76.111,
					   "shotgun": 41.781,
					   "m4a1": 106.578,
					   "musket": 104.174,
					   "machine_gun": 81.396};

var weapon_name = {"pistol": ".45mm",
				   "shotgun": "Pump-action",
				   "musket": "Musket",
				   "machine_gun": "Machine-gun",
				   "gatling_gun": "Gatling-gun",};

var weapon_code = {".45mm": "pistol",
				   "Pump-action": "shotgun",
				   "Musket": "musket",
				   "Machine-gun": "machine_gun",
				   "Gatling-gun": "gatling_gun"};

var revert_weapon = {"gatling_gun": ["machine_gun", "pistol"],
					 "musket": ["shotgun", "pistol"]};

var prod_weapon = {["machine_gun", "pistol"]: "gatling_gun",
				   ["shotgun", "pistol"]: "musket"};

#MISCELLANEOUS PLAYER FLAGS
var weapon_to_pickup := false;

var can_shop := false;

var weapon_in_hand;

var skip_trans := false

var player_nodepath;
