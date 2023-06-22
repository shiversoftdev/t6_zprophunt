GameEngine()
{
	level endon("end_game");
	//level thread alfredoo_prevention();
	flag_wait( "start_zombie_round_logic" );
	level.teambased = true;
	level.hns_seekers = [];
	if( getDvar("mapname") == "zm_prison" )
	{
		bool = false;
		b_everyone_alive = 0;
		while ( isDefined( b_everyone_alive ) && !b_everyone_alive )
		{
			b_everyone_alive = 1;
			a_players = getplayers();
			_a192 = a_players;
			_k192 = getFirstArrayKey( _a192 );
			while ( isDefined( _k192 ) )
			{
				player = _a192[ _k192 ];
				if ( isDefined( player.afterlife ) && player.afterlife )
				{
					b_everyone_alive = 0;
					wait 0.05;
					break;
				}
				else
				{
					_k192 = getNextArrayKey( _a192, _k192 );
				}
			}
		}
		wait 3;
		foreach( player in level.players )
		{
			player.lives = 0;
			player notify( "stop_player_out_of_playable_area_monitor" );
		}
	}
	modelstoadd = [];
	foreach( model in getEntArray("script_model", "classname") )
	{
		if( isSubstr( model.model, "p6_zm_hr_mahjong_tile" ) )
			continue;
		modelstoadd = add_to_array( modelstoadd, model.model, 0 );
	}
	modelstoadd = AddExtraMapModels( modelstoadd );
	modelstoadd = BlackListClear( modelstoadd );
	AddSubMenu("Set Model", 0 );
	foreach( model in modelstoadd)
	{
		precachemodel( model );
		AddOption( model, ::void_handler, 1, model);
	}
	CloseSubMenu();
	AddOption("Suicide", ::void_handler, 0);
	AddOption("First Person", ::void_handler, 3);
	AddSubmenu("Game Settings", 4);
		AddOption("Allow Seekers Respawn", ::void_handler, 4);
		AddOption("Disable Suicide", ::void_handler, 5);
		AddOption("Disable Prop Detector", ::void_handler, 6);
	CloseSubMenu();
	//AddOption("Third Person", ::void_handler, 2);
	level.SENTINEL_INITIALIZED = true;
	foreach( player in level.players)
	{
		player thread deadopsview();
	}
	_zm_arena_openalldoors();
	foreach( door in getentarray( "afterlife_door", "script_noteworthy" ))
	{
		door thread maps/mp/zombies/_zm_blockers::door_opened( 0 );
		wait .005;
	}
	foreach( debri in getentarray( "zombie_debris", "targetname" ))
	{
		debri.zombie_cost = 0;
		debri notify( "trigger", level.players[0], 1 ); 
		wait .005;
	}
	setmatchtalkflag( "EveryoneHearsEveryone", 1);
	setmatchflag( "disableIngameMenu", 1 );
	level.zombie_vars["spectators_respawn"] = 0;
	setDvar("player_lastStandBleedoutTime", 1);
	setDvar("g_ai","0");
	flag_clear("spawn_zombies");
	foreach( player in level.players )
		player.isseeker = false;
	level thread watch_game_over_monitor();
	foreach( player in level.players )
		player thread WaitForHiderDeath();
	wait 5;
	foreach( player in level.players)
	{
		player iprintlnbold("Welcome to Prop Hunt by SeriousHD-");
		player thread informationBar();
	}
	wait 2;
	foreach(player in level.players)
		player EnableInvulnerability();
	for( i = 45; i > 0; i--)
	{
		foreach( player in level.players)
			player iprintlnbold("You have "+i+" to hide!");
		wait 1;	
	}
	foreach(player in level.players)
		player DisableInvulnerability();
	victim = level.players[ randomintrange(0, level.players.size) ];
	victim dodamage( 999, victim.origin );
	wait 1;
	foreach( player in level.players)
	{
		if( player != victim )
			player setMoveSpeedScale( .5 );
		player iprintln( "Hunter Released.." );
	}	
	wait 1;
	level thread EndGameTimer();
}

Seekerify()
{
	self.isSeeker = true;
	self CameraActivate(false);
	arrayremovevalue(level.hns_alive, self );
	if ( self.sessionstate == "spectator" )
	{
		if ( isDefined( self.spectate_hud ) )
			self.spectate_hud destroy();
		self [[ level.spawnplayer ]]();
	}
	while( self.sessionstate == "spectator" )
		wait .1;
	self.team = "axis";
	self SetTeam( "axis" );
	self.pers["team"] ="axis";
	level.hns_seekers = add_to_array(level.hns_seekers, self, 0 );
	level notify("Seeker_released");
	self takeallweapons();
	self.isSeeker = true;
	self setclientuivisibilityflag( "hud_visible", 0 );
	self giveWeapon( "ray_gun_zm" );
	self switchtoweapon( "ray_gun_zm" );
	self notify( "stop_player_out_of_playable_area_monitor" );
	perks1 = strtok("specialty_additionalprimaryweapon,specialty_armorpiercing,specialty_armorvest,specialty_bulletaccuracy,specialty_bulletdamage,specialty_bulletflinch,specialty_bulletpenetration,specialty_deadshot,specialty_delayexplosive,specialty_detectexplosive,specialty_disarmexplosive,specialty_earnmoremomentum,specialty_explosivedamage,specialty_extraammo,specialty_fallheight,specialty_fastads,specialty_fastequipmentuse,specialty_fastladderclimb,specialty_fastmantle,specialty_fastmeleerecovery,specialty_fastreload,specialty_fasttoss,specialty_fastweaponswitch,specialty_finalstand,specialty_fireproof,specialty_flakjacket,specialty_flashprotection,specialty_gpsjammer,specialty_grenadepulldeath,specialty_healthregen,specialty_holdbreath,specialty_immunecounteruav,specialty_immuneemp,specialty_immunemms,specialty_immunenvthermal,specialty_immunerangefinder,specialty_killstreak,specialty_longersprint,specialty_loudenemies,specialty_marksman,specialty_movefaster,specialty_nomotionsensor,specialty_noname,specialty_nottargetedbyairsupport,specialty_nokillstreakreticle,specialty_nottargettedbysentry,specialty_pin_back,specialty_pistoldeath,specialty_proximityprotection,specialty_quickrevive,specialty_quieter,specialty_reconnaissance,specialty_rof,specialty_scavenger,specialty_showenemyequipment,specialty_stunprotection,specialty_shellshock,specialty_sprintrecovery,specialty_showonradar,specialty_stalker,specialty_twogrenades,specialty_twoprimaries,specialty_unlimitedsprint", ",");
	foreach( perk in perks1 )
		self unsetperk( perk );	
	perks = strtok("specialty_armorpiercing,specialty_armorvest,specialty_bulletaccuracy,specialty_bulletdamage,specialty_bulletflinch,specialty_bulletpenetration,specialty_deadshot,specialty_extraammo,specialty_fallheight,specialty_fastads,specialty_fastequipmentuse,specialty_fastladderclimb,specialty_fastmantle,specialty_fastmeleerecovery,specialty_fastreload,specialty_fasttoss,specialty_fastweaponswitch,specialty_gpsjammer,specialty_holdbreath,specialty_immunecounteruav,specialty_immuneemp,specialty_immunemms,specialty_immunenvthermal,specialty_immunerangefinder,specialty_killstreak,specialty_longersprint,specialty_loudenemies,specialty_marksman,specialty_movefaster,specialty_nomotionsensor,specialty_noname,specialty_nottargetedbyairsupport,specialty_nokillstreakreticle,specialty_nottargettedbysentry,specialty_pin_back,specialty_proximityprotection,specialty_quickrevive,specialty_quieter,specialty_reconnaissance,specialty_rof,specialty_scavenger,specialty_showenemyequipment,specialty_sprintrecovery,specialty_showonradar,specialty_stalker,specialty_twogrenades,specialty_twoprimaries,specialty_unlimitedsprint", ",");
	foreach( perk in perks )
		self setperk( perk );
	self notify( "stop_player_out_of_playable_area_monitor" );
	self iprintlnbold("Kill the Props!");
	self thread seeker_shoot_logic();
	self thread Prop_Detector();
	self thread seeker_health_replenish_logic();
	while( self.sessionstate != "spectator" )
		wait 1;
	if( level._norespawnallowed )
	{
		self thread Seekerify();
		return;
	}
	self allowspectateallteams( 0 );
	self allowspectateteam( "freelook", 1 );
	self allowspectateteam( "none", 1 );
	self allowspectateteam( "localplayers", 1 );
}

allowspectateallteams( allow )
{
	_a114 = level.teams;
	_k114 = getFirstArrayKey( _a114 );
	while ( isDefined( _k114 ) )
	{
		team = _a114[ _k114 ];
		self allowspectateteam( team, allow );
		_k114 = getNextArrayKey( _a114, _k114 );
	}
}

seeker_shoot_logic()
{
	self notify("new_shoot_logic");
	self endon("new_shoot_logic");
	while( 1 )
	{
		self waittill("weapon_fired", weapon);
		self dodamage( ( 7 ), self.origin );
		self RadiusDamage( self GetNormalTrace(), 25, 50, 50, self );
	}
}

seeker_health_replenish_logic()
{
	self notify("new_health_log");
	self endon("new_health_log");
	while( 1 )
	{
		self waittill("player_give_hp", amount);
		self.health += amount;
		if( self.maxhealth < self.health )
			self.health = self.maxhealth;
	}
}

hider_givehealth_logic()
{
	self endon("spawned_player");
	while( 1 )
	{
		self waittill( "damage", amount, attacker, dir, point, mod );
			if(isPlayer(attacker))
				attacker notify("player_give_hp", amount);
	}
}

watch_game_over_monitor()
{
	level.hns_gameended = false;
	bool = false;
	otherbool = false;
	level.hns_alive = array_copy( level.players );
	level waittill( "Seeker_released" );
	while( !level.hns_gameended )
	{
		wait 1;
		if(level.hns_alive.size == 0)
			break;
		bool = false;
		foreach( player in level.hns_seekers)
		{
			if( player.sessionstate != "spectator" )
			{
				bool = true;
				break;
			}
		}
		if( bool )
			continue;
		break;
	}
	level.hns_gameended = true;
	foreach( player in level.players)
	{
		player sCleanupMenu();
		player freezecontrols( 1 );
		if( level.hns_alive.size == 0 )
			player.egt = player drawText("HUNTERS WIN!", "objective", 2, "CENTER", "TOP", 0, 50, (1,0,0), 1, 0, 6);
		else
			player.egt = player drawText("PROPS WIN!", "objective", 2, "CENTER", "TOP", 0, 50, (0,1,0), 1, 0, 6);
	}
	wait 4;
	foreach( player in level.players )
		player.egt destroy();
	level notify("end_game");
}

WaitForHiderDeath()
{
	wait 5;
	if( isDefined( getent( "the_bus", "targetname" ) ) )
		getent( "the_bus", "targetname" ) delete();
	self setclientuivisibilityflag( "hud_visible", 0 );
	self disableUsability();
	self disableweapons();
	self notify( "stop_player_out_of_playable_area_monitor" );
	perks = strtok("specialty_armorpiercing,specialty_armorvest,specialty_bulletaccuracy,specialty_bulletdamage,specialty_bulletflinch,specialty_bulletpenetration,specialty_deadshot,specialty_extraammo,specialty_fallheight,specialty_fastads,specialty_fastequipmentuse,specialty_fastladderclimb,specialty_fastmantle,specialty_fastmeleerecovery,specialty_fastreload,specialty_fasttoss,specialty_fastweaponswitch,specialty_gpsjammer,specialty_holdbreath,specialty_immunecounteruav,specialty_immuneemp,specialty_immunemms,specialty_immunenvthermal,specialty_immunerangefinder,specialty_killstreak,specialty_longersprint,specialty_loudenemies,specialty_marksman,specialty_movefaster,specialty_nomotionsensor,specialty_noname,specialty_nottargetedbyairsupport,specialty_nokillstreakreticle,specialty_nottargettedbysentry,specialty_pin_back,specialty_proximityprotection,specialty_quickrevive,specialty_quieter,specialty_reconnaissance,specialty_rof,specialty_scavenger,specialty_showenemyequipment,specialty_sprintrecovery,specialty_showonradar,specialty_stalker,specialty_twogrenades,specialty_twoprimaries,specialty_unlimitedsprint", ",");
	self.maxhealth = 75;
	self.health = 75;
	foreach( perk in perks )
		self setperk( perk );
	self notify( "pers_flopper_lost" );
	self.pers_num_flopper_damages = 0;
	while( self.sessionstate != "spectator" )
		wait 1;
	sCleanupMenu();
	self thread Seekerify();
}

BlackListClear( models )
{
	arrayremovevalue( models, "p6_zm_pswitch_old_lever");
	arrayremovevalue( models, "tag_origin");
	arrayremovevalue( models, "zm_collision_perks1");
	arrayremovevalue( models, "zombie_sign_please_wait");
	arrayremovevalue( models, "p6_zm_bu_hedge_gate");
	arrayremovevalue( models, "p6_zm_bu_sign_tunnel_lunger");
	arrayremovevalue( models, "p6_zm_bu_sign_tunnel_consumption");
	arrayremovevalue( models, "p6_zm_bu_sign_tunnel_bone");
	arrayremovevalue( models, "p6_zm_bu_sign_tunnel_ground");
	arrayremovevalue( models, "p6_zm_bu_sign_tunnel_dry");
	arrayremovevalue( models, "p6_zm_bu_bulb_puzzle_machine");
	arrayremovevalue( models, "p6_zm_bu_chalk");
	arrayremovevalue( models, "p6_zm_bu_booze");
	arrayremovevalue( models, "p6_zm_bu_sq_vaccume_tube");
	arrayremovevalue( models, "p6_zm_buildable_sq_meteor");
	arrayremovevalue( models, "p6_zm_buildable_sq_electric_box");
	arrayremovevalue( models, "p6_zm_buildable_tramplesteam_flag");
	arrayremovevalue( models, "p6_zm_buildable_turbine_rudder");
	arrayremovevalue( models, "p6_zm_buildable_turbine_fan");
	arrayremovevalue( models, "zombie_pickup_perk_bottle");
	arrayremovevalue( models, "p6_zm_nuked_rocket_cam");
	arrayremovevalue( models, "mp_nuked_townsign_counter");
	arrayremovevalue( models, "collision_wall_128x128x10_standard");
	arrayremovevalue( models, "collision_player_256x256x10");
	arrayremovevalue( models, "collision_player_512x512x10");
	arrayremovevalue( models, "collision_wall_64x64x10_standard");
	arrayremovevalue( models, "fxanim_gp_shirt01_mod");
	arrayremovevalue( models, "fxanim_gp_tanktop_mod");
	arrayremovevalue( models, "fxanim_gp_dress_mod");
	arrayremovevalue( models, "fxanim_gp_pant01_mod");
	arrayremovevalue( models, "fxanim_gp_shirt_grey_mod");
	arrayremovevalue( models, "fxanim_gp_roaches_mod");
	arrayremovevalue( models, "fxanim_zom_curtains_yellow_b_mod");
	arrayremovevalue( models, "fxanim_zom_nuketown_cabinets_brwn_mod");
	arrayremovevalue( models, "fxanim_zom_nuketown_cabinets_red_mod");
	arrayremovevalue( models, "fxanim_zom_nuketown_shutters02_mod");
	arrayremovevalue( models, "fxanim_gp_cloth_sheet_med01_mod");
	arrayremovevalue( models, "fxanim_zom_nuketown_cabinets_brwn02_mod");
	arrayremovevalue( models, "fxanim_gp_wirespark_long_mod");
	arrayremovevalue( models, "fxanim_gp_wirespark_med_mod");
	arrayremovevalue( models, "p_rus_clock_green_sechand");
	arrayremovevalue( models, "p_rus_clock_green_minhand");
	arrayremovevalue( models, "p_rus_clock_green_hourhand");
	arrayremovevalue( models, "t6_wpn_zmb_perk_bottle_doubletap_world");
	arrayremovevalue( models, "t6_wpn_zmb_perk_bottle_jugg_world");
	arrayremovevalue( models, "t6_wpn_zmb_perk_bottle_revive_world");
	arrayremovevalue( models, "t6_wpn_zmb_perk_bottle_sleight_world");
	arrayremovevalue( models, "zombie_x2_icon");
	arrayremovevalue( models, "p6_anim_zm_hr_elevator_freight");
	arrayremovevalue( models, "p6_anim_zm_hr_elevator_common");
	arrayremovevalue( models, "p6_zm_pswitch_lever_handel");
	arrayremovevalue( models, "t6_wpn_slipgun_world");
	arrayremovevalue( models, "p6_zm_hr_lion_statue_ball");
	arrayremovevalue( models, "t6_zmb_buildable_slipgun_extinguisher");
	arrayremovevalue( models, "t6_zmb_buildable_slipgun_cooker");
	arrayremovevalue( models, "t6_zmb_buildable_slipgun_foot");
	arrayremovevalue( models, "t6_zmb_buildable_slipgun_throttle");
	arrayremovevalue( models, "p_cub_door01_wood_fullsize");
	arrayremovevalue( models, "p6_zm_core_reactor_top");
	arrayremovevalue( models, "p6_door_metal_no_decal_left");
	arrayremovevalue( models, "veh_t6_civ_bus_driver");
	arrayremovevalue( models, "zombie_carpenter");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dmg1_world");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dmg2_world");
	arrayremovevalue( models, "p6_zm_buildable_jetgun_handles");
	arrayremovevalue( models, "p6_zm_buildable_jetgun_guages");
	arrayremovevalue( models, "p6_zm_buildable_turret_ammo");
	arrayremovevalue( models, "storefront_door02_window");
	arrayremovevalue( models, "p6_zm_al_cell_door_collmap");
	arrayremovevalue( models, "p6_zm_al_cell_isolation");
	arrayremovevalue( models, "fxanim_zom_al_trap_fan_mod");
	arrayremovevalue( models, "p6_zm_al_gondola");
	arrayremovevalue( models, "p6_zm_al_gondola_gate");
	arrayremovevalue( models, "p6_zm_al_gondola_door");
	arrayremovevalue( models, "p6_zm_al_dream_catcher_off");
	if( getDvar("mapname") == "zm_prison" )
		arrayremovevalue( models, "zombie_teddybear");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dlc2_dmg0_view");
	arrayremovevalue( models, "p6_zm_al_packasplat_iv");
	arrayremovevalue( models, "p6_zm_al_audio_headset_icon");
	arrayremovevalue( models, "collision_wall_256x256x10_standard");
	arrayremovevalue( models, "collision_clip_64x64x256");
	arrayremovevalue( models, "t6_wpn_pistol_b2023r_world");
	arrayremovevalue( models, "p6_zm_buildable_pswitch_hand");
	arrayremovevalue( models, "p6_zm_buildable_pswitch_lever");
	arrayremovevalue( models, "t6_wpn_zmb_jet_gun_world");
	arrayremovevalue( models, "t6_wpn_zmb_shield_world");
	arrayremovevalue( models, "collision_geo_32x32x10_standard");
	arrayremovevalue( models, "collision_wall_512x512x10_standard");
	arrayremovevalue( models, "collision_player_256x256x256");
	arrayremovevalue( models, "collision_player_32x32x128");
	arrayremovevalue( models, "veh_t6_civ_bus_zombie");
	arrayremovevalue( models, "collision_ai_64x64x10");
	arrayremovevalue( models, "collision_geo_256x256x256_standard");
	arrayremovevalue( models, "collision_geo_64x64x256_standard");
	arrayremovevalue( models, "collision_geo_128x128x128_standard");
	arrayremovevalue( models, "p6_zm_al_blood_check_list");
	arrayremovevalue( models, "p6_zm_al_door_frame_single_right_grn");
	arrayremovevalue( models, "p6_anim_zm_al_dock_fence_door");
	arrayremovevalue( models, "p6_zm_al_wall_trap_handle");
	arrayremovevalue( models, "p6_zm_al_wall_trap_control_red");
	arrayremovevalue( models, "p6_zm_al_fence_door");
	arrayremovevalue( models, "p6_zm_al_fence_gate");
	arrayremovevalue( models, "p6_zm_al_gondola_frame_light_red");
	arrayremovevalue( models, "p6_anim_zm_al_citadel_numbers");
	arrayremovevalue( models, "p6_zm_al_wall_trap_control");
	arrayremovevalue( models, "p6_zm_al_sporkcalibur_poster");
	arrayremovevalue( models, "t6_wpn_zmb_spoon_world");
	arrayremovevalue( models, "collision_geo_64x64x64_standard");
	arrayremovevalue( models, "collision_geo_32x32x128_standard");
	arrayremovevalue( models, "collision_geo_128x128x10128_standard");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dlc2_shackles");
	arrayremovevalue( models, "p6_zm_al_key");
	arrayremovevalue( models, "fxanim_zom_al_gondola_chains_mod");
	arrayremovevalue( models, "p6_zm_tm_elm_plinth_top_fire");
	arrayremovevalue( models, "p6_zm_tm_elm_plinth_top_wind");
	arrayremovevalue( models, "p6_zm_tm_elm_plinth_top_ice");
	arrayremovevalue( models, "p6_zm_tm_elm_plinth_top_lightning");
	arrayremovevalue( models, "p6_zm_tm_elm_divider");
	arrayremovevalue( models, "zombie_zapper_handle");
	arrayremovevalue( models, "t6_wpn_zmb_staff_air_world");
	arrayremovevalue( models, "t6_wpn_zmb_staff_fire_world");
	arrayremovevalue( models, "t6_wpn_zmb_staff_water_world");
	arrayremovevalue( models, "t6_wpn_zmb_staff_bolt_world");
	arrayremovevalue( models, "t6_wpn_zmb_staff_world");
	arrayremovevalue( models, "veh_t6_dlc_zm_robot_foot_hatch");
	arrayremovevalue( models, "p6_zm_tm_wind_ceiling_ring_1");
	arrayremovevalue( models, "p6_zm_tm_wind_ceiling_ring_2");
	arrayremovevalue( models, "p6_zm_tm_wind_ceiling_ring_3");
	arrayremovevalue( models, "p6_zm_tm_wind_ceiling_ring_4");
	arrayremovevalue( models, "p6_zm_tm_rotary_switch");
	arrayremovevalue( models, "p6_zm_tm_challenge_box");
	arrayremovevalue( models, "p6_zm_tm_soul_box");
	arrayremovevalue( models, "p6_zm_tm_medallion");
	arrayremovevalue( models, "veh_t6_dlc_zm_zeppelin");
	arrayremovevalue( models, "p6_zm_tm_tablet_muddy");
	arrayremovevalue( models, "veh_t6_dlc_mkiv_tank");
	arrayremovevalue( models, "fxanim_zom_tomb_generator_pump_mod");
	arrayremovevalue( models, "veh_t6_dlc_zm_quadrotor");
	arrayremovevalue( models, "veh_t6_dlc_zm_robot_2");
	arrayremovevalue( models, "collision_geo_128x128x10_slick");
	arrayremovevalue( models, "collision_geo_64x64x128_slick");
	arrayremovevalue( models, "collision_geo_256x256x10_standard");
	arrayremovevalue( models, "p6_zm_bu_rock_strata_column_01");
	arrayremovevalue( models, "p6_zm_bu_rock_strata_01");
	arrayremovevalue( models, "collision_geo_64x64x10_slick");
	arrayremovevalue( models, "collision_geo_64x64x10_standard");
	arrayremovevalue( models, "p6_zm_bu_rock_strata_04");
	arrayremovevalue( models, "p6_zm_buildable_pswitch_lever_handed");
	arrayremovevalue( models, "p6_zm_bu_sloth_blocker_medium");
	arrayremovevalue( models, "collision_geo_128x128x10_standard");
	arrayremovevalue( models, "fxanim_zom_buried_orbs_mod");
	arrayremovevalue( models, "collision_player_wall_256x256x10");
	arrayremovevalue( models, "collision_player_wall_512x512x10");
	arrayremovevalue( models, "collision_geo_512x512x10_standard");
	arrayremovevalue( models, "collision_geo_ramp_standard");
	arrayremovevalue( models, "collision_player_wall_512x512x512");
	arrayremovevalue( models, "collision_geo_64x64x128_standard");
	arrayremovevalue( models, "collision_player_wall_128x128x10");
	arrayremovevalue( models, "collision_player_wall_32x32x10");
	arrayremovevalue( models, "veh_t6_dlc_zm_quad_piece_body");
	arrayremovevalue( models, "veh_t6_dlc_zm_quad_piece_brain");
	arrayremovevalue( models, "veh_t6_dlc_zm_quad_piece_engine");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dlc4_top");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dlc4_door");
	arrayremovevalue( models, "t6_wpn_zmb_shield_dlc4_bracket");
	arrayremovevalue( models, "collision_geo_512x512x512_standard");
	arrayremovevalue( models, "collision_wall_32x32x10_standard");
	arrayremovevalue( models, "collision_player_512x512x512");
	arrayremovevalue( models, "");
	return models;
}

AddExtraMapModels( models )
{
	extras = [];
	if( getDvar("mapname") == "zm_buried" )
		extras = strtok("p6_anim_zm_magic_box_fake,p6_anim_zm_magic_box,p6_zm_work_bench,p6_anim_zm_buildable_view_tramplesteam,p6_anim_zm_buildable_turbine,t6_wpn_zmb_subwoofer,p6_anim_zm_buildable_tramplesteam,p6_anim_zm_hr_buildable_sq,fxanim_zom_buried_orbs_mod,p6_zm_bu_gallows,p6_zm_bu_guillotine,p6_zm_bu_end_game_machine,t6_wpn_zmb_chopper,zombie_teddybear,zombie_pickup_perk_bottle,p6_zm_bu_hedge_gate,p6_zm_buildable_turbine_fan,p6_zm_buildable_turbine_rudder,p6_zm_buildable_turbine_mannequin,p6_zm_buildable_tramplesteam_door,p6_zm_buildable_tramplesteam_bellows,p6_zm_buildable_tramplesteam_compressor,p6_zm_buildable_tramplesteam_flag,p6_zm_buildable_sq_electric_box,p6_zm_buildable_sq_meteor,p6_zm_buildable_sq_scaffolding,p6_zm_buildable_sq_transceiver,p6_zm_bu_sq_vaccume_tube,p6_zm_bu_sq_buildable_battery,p6_zm_bu_sq_crystal,p6_zm_bu_sq_satellite_dish,p6_zm_bu_sq_antenna,p6_zm_bu_sq_wire_spool,p6_zm_bu_booze,p6_zm_bu_sloth_candy_bowl,p6_zm_bu_chalk,p6_zm_bu_sloth_booze_jug",",");
	if( getDvar("mapname") == "zm_nuked" )
		extras = strtok("p6_anim_zm_magic_box_fake,p6_anim_zm_magic_box,zombie_wolf,p6_zm_nuked_chair_01,p6_zm_nuked_couch_02,p6_zm_door_white,p6_zm_door_brown,p6_zm_cratepile,defaultvehicle,fxanim_gp_shirt01_mod,fxanim_gp_tanktop_mod,fxanim_gp_dress_mod,fxanim_gp_pant01_mod,fxanim_gp_shirt_grey_mod,fxanim_gp_roaches_mod,fxanim_zom_nuketown_shutters_mod,fxanim_zom_curtains_yellow_a_mod,fxanim_zom_curtains_yellow_b_mod,fxanim_zom_curtains_yellow_c_mod,fxanim_zom_curtains_blue_a_mod,fxanim_zom_curtains_blue_c_mod,fxanim_zom_nuketown_cabinets_brwn_mod,fxanim_zom_nuketown_cabinets_red_mod,fxanim_zom_nuketown_shutters02_mod,fxanim_gp_cloth_sheet_med01_mod,fxanim_zom_nuketown_cabinets_brwn02_mod,fxanim_gp_roofvent_small_mod,fxanim_gp_wirespark_long_mod,fxanim_gp_wirespark_med_mod,mp_nuked_townsign_counter,dest_zm_nuked_male_01_d0,p_rus_clock_green_sechand,p_rus_clock_green_minhand,p_rus_clock_green_hourhand,p6_zm_nuked_clocktower_sec_hand,p6_zm_nuked_clocktower_min_hand,dest_zm_nuked_female_01_d0,dest_zm_nuked_female_02_d0,dest_zm_nuked_female_03_d0,dest_zm_nuked_male_02_d0,zombie_teddybear,t6_wpn_zmb_perk_bottle_doubletap_world,t6_wpn_zmb_perk_bottle_jugg_world,t6_wpn_zmb_perk_bottle_revive_world,t6_wpn_zmb_perk_bottle_sleight_world,zombie_bomb,zombie_skull,zombie_ammocan,zombie_x2_icon,zombie_firesale",",");
	if( getDvar("mapname") == "zm_highrise" )
		extras = strtok("p6_anim_zm_magic_box_fake,p6_anim_zm_magic_box,p6_zm_hr_luxury_door,p6_zm_nuked_couch_02,p6_zm_hr_lion_statue_ball,p6_anim_zm_hr_buildable_sq,p6_anim_zm_buildable_tramplesteam,zombie_teddybear,zombie_pickup_perk_bottle,p6_zm_buildable_tramplesteam_door,p6_zm_buildable_tramplesteam_bellows,p6_zm_buildable_tramplesteam_compressor,p6_zm_buildable_tramplesteam_flag,t6_zmb_buildable_slipgun_extinguisher,t6_zmb_buildable_slipgun_cooker,t6_zmb_buildable_slipgun_foot,t6_zmb_buildable_slipgun_throttle,p6_zm_buildable_sq_electric_box,p6_zm_buildable_sq_meteor,p6_zm_buildable_sq_scaffolding,p6_zm_buildable_sq_transceiver",",");
	if( getDvar("mapname") == "zm_transit" )
		extras = strtok("p6_anim_zm_magic_box_fake,p6_anim_zm_magic_box,p_rus_door_white_window_plain_left,p_rus_door_white_plain_right,storefront_door02_window,p_cub_door01_wood_fullsize,p6_zm_bank_vault_door,p6_zm_core_reactor_top,p6_door_metal_no_decal_left,p6_zm_window_dest_glass_big,p6_zm_garage_door_01,p6_zm_door_security_depot,veh_t6_civ_bus_zombie,p6_anim_zm_bus_driver,veh_t6_civ_movingtrk_cab_dead,veh_t6_civ_bus_zombie_roof_hatch,p6_anim_zm_buildable_turret,p6_anim_zm_buildable_etrap,p6_anim_zm_buildable_turbine,p6_anim_zm_buildable_sq,zombie_teddybear,p6_anim_zm_buildable_pap,zombie_sign_please_wait,ch_tombstone1,zombie_bomb,zombie_skull,zombie_ammocan,zombie_x2_icon,zombie_carpenter,t6_wpn_zmb_shield_dmg1_world,t6_wpn_zmb_shield_dmg2_world,p6_zm_screecher_hole,p6_zm_buildable_battery,t6_wpn_zmb_shield_dolly,t6_wpn_zmb_shield_door,p6_zm_buildable_pap_body,p6_zm_buildable_pap_table,p6_zm_buildable_turbine_fan,p6_zm_buildable_turbine_rudder,p6_zm_buildable_turbine_mannequin,p6_zm_buildable_turret_mower,p6_zm_buildable_turret_ammo,p6_zm_buildable_etrap_base,p6_zm_buildable_etrap_tvtube,p6_zm_buildable_jetgun_wires,p6_zm_buildable_jetgun_engine,p6_zm_buildable_jetgun_guages,p6_zm_buildable_jetgun_handles,p6_zm_buildable_sq_electric_box,p6_zm_buildable_sq_meteor,p6_zm_buildable_sq_scaffolding,p6_zm_buildable_sq_transceiver,p_glo_tools_chest_tall",",");
	if( getDvar("mapname") == "zm_prison" )
		extras = strtok("p6_anim_zm_al_magic_box,storefront_door02_window,p6_zm_al_cell_door_collmap,p6_zm_al_cell_isolation,p6_zm_al_large_generator,fxanim_zom_al_trap_fan_mod,p6_zm_al_gondola,p6_zm_al_gondola_gate,p6_zm_al_gondola_door,p6_zm_al_shock_box_off,p6_zm_al_cell_door,veh_t6_dlc_zombie_plane_whole,p6_zm_al_electric_chair,p6_zm_al_infirmary_case,p6_zm_al_industrial_dryer,p6_zm_al_clothes_pile_lrg,veh_t6_dlc_zombie_part_engine,p6_zm_al_dream_catcher_off,c_zom_wolf_head,zombie_bomb,zombie_skull,zombie_ammocan,zombie_x2_icon,zombie_firesale,zombie_teddybear,t6_wpn_zmb_shield_dlc2_dmg0_view,p6_zm_al_packasplat_suitcase,p6_zm_al_packasplat_engine,p6_zm_al_packasplat_iv,veh_t6_dlc_zombie_part_fuel,veh_t6_dlc_zombie_part_rigging,p6_anim_zm_al_packasplat,p6_zm_al_shock_box_on,p6_zm_al_audio_headset_icon,p6_zm_al_power_station_panels_03",",");
	if( getDvar("mapname") == "zm_tomb" )
		extras = strtok("p6_anim_zm_tm_magic_box,veh_t6_dlc_mkiv_tank,veh_t6_dlc_zm_biplane,fxanim_zom_tomb_portal_mod,p6_zm_tm_packapunch,fxanim_zom_tomb_generator_pump_mod,p6_zm_tm_wind_ceiling_ring_2,p6_zm_tm_wind_ceiling_ring_3,p6_zm_tm_wind_ceiling_ring_4,p6_zm_tm_wind_ceiling_ring_1,p6_zm_tm_challenge_box,p6_zm_tm_soul_box,veh_t6_dlc_zm_quadrotor,zombie_teddybear,veh_t6_dlc_zm_zeppelin,p6_zm_tm_gramophone,veh_t6_dlc_zm_robot_2",",");
	foreach( model in extras )
		models = add_to_array( models, model, 0 );
	return models;
}

alfredoo_prevention()
{
	level waittill("end_game");
	while( 1 )
	{
		if( sGetHost() useButtonPressed() )
			map_restart( 0 );
		wait .1;
	}
}

EndGameTimer()
{
	level thread tensionformusic();
	level.hns_sexy = drawSVT("TIME LEFT:", "objective", 2.0, "CENTER", "TOP", -35, 25, (1,0,0), 1, (0,0,0), 0, 4);
	level.hns_minutes = drawValue(20, "objective", 2.0, "CENTER", "TOP", 20, 25, (1,0,0), 1, (0,0,0), 0, 4);
	//level.hns_sexier = drawSVT(":", "objective", 2.0, "CENTER", "TOP", 0, 25, (1,0,0), 1, (0,0,0), 0, 4);
	level.hns_sec = drawValue(00, "objective", 2.0, "CENTER", "TOP", 40, 25, (1,0,0), 1, (0,0,0), 0, 4);
	min = 20;
	sec = 0;
	for( i = 9; i > -1 && !level.hns_gameended; i--)
	{
		level.hns_minutes setValue(i);
		for( j = 59; j > -1 && !level.hns_gameended; j--)
		{
			level.hns_sec setValue(j);		
			wait 1;
		}
	}
	level.hns_sexy destroy();
	level.hns_minutes destroy();
	level.hns_sec destroy();
	//level.hns_sexier destroy();
	level.hns_gameended = true;
}



Prop_Detector()
{
	self notify("h27823948");
	self endon("h27823948");
	zone = self maps/mp/zombies/_zm_zonemgr::get_player_zone();
	count = 0;
	while( 1 )
	{
		while( isDefined( zone) && zone == self maps/mp/zombies/_zm_zonemgr::get_player_zone() )
			wait 1;
		zone = self maps/mp/zombies/_zm_zonemgr::get_player_zone();
		count = 0;
		foreach( player in level.hns_alive )
			if( player maps/mp/zombies/_zm_zonemgr::get_player_zone() == zone )
				count++;
		self iprintln("There are ^1"+count+" ^7props in this zone");
		wait 10;
	}
	
}

informationBar()
{
	self endon("spawned_player");
	while( 1 )
	{
		self iprintln("Press ^2[{+actionslot 1}] to open Menu");
		self iprintln("Use the DPAD to scroll up and down");
		self iprintln("Use [{+usereload}] to select and [{+melee}] to go back.");
		wait 25;
	}
}

SafeCleanOnDisconnect()
{
	self waittill("disconnect");
	arrayremovevalue(level.hns_alive, self );
	arrayremovevalue(level.hns_seekers, self );
}

deadopsview()
{
	self endon("spawned_player");
	birdsEyeCamera = spawn("script_model", self.origin + (0,0,200), 1);
	birdsEyeCamera setModel("tag_origin");
	birdsEyeCamera.angles = self.angles;
	self CameraSetLookAt(self);
	self CameraSetPosition(birdsEyeCamera);
	self CameraActivate(true);
	self.modellock = false;
	target = undefined;
	trace = undefined;
	while(1)
	{
		target =  self.origin + (0,0,200) - ( AnglesToForward( self getplayerangles() ) * 200 );
		if( SightTracePassed( target, self.origin, false, birdsEyeCamera ) )
			birdsEyeCamera.origin = target;
		else
		{
			trace = BulletTrace( self.origin, target, false, birdsEyeCamera );
			target = trace[ "position" ] - ( ( trace[ "position" ] - self.origin ) * .25 );
			birdsEyeCamera.origin = target;
		}
		if( self.modellock || sGetBool( 3 ) )
		{
			while( self.modellock || sGetBool( 3 ) )
				wait .1;
			self CameraActivate(true);
		}
		wait 0.05;
	}
}

tensionformusic()
{
	map = getDvar("mapname");
	while( 1 )
	{
		if( map == "zm_prison" )
		{
			level thread maps/mp/zombies/_zm_audio::sndmusicstingerevent( "tension_high" );
			wait 90;
		}
		else if( map == "zm_nuked" )
		{
			level thread sndmuseggplay( spawn( "script_origin", ( 0, 1, 0 ) ), "zmb_nuked_song_3", 80 );
			wait 80;
			level thread sndmuseggplay( spawn( "script_origin", ( 0, 1, 0 ) ), "zmb_nuked_song_1", 88 );
			wait 88;
		}
		else if( map == "zm_buried" )
		{
			level thread maps/mp/zombies/_zm_audio::change_zombie_music( "last_life" );
			wait 30;
		}
		else if( map == "zm_transit" )
		{
			flag_set( "ambush_round");
			break;
		}
		else if( map == "zm_highrise" )
		{
			level thread sndmuseggplay( spawn( "script_origin", ( 0, 1, 0 ) ), "mus_zmb_secret_song", 190 );
			wait 190;
		}
		else if( map == "zm_tomb" )
		{
			level thread sndmuseggplay( spawn( "script_origin", ( 0, 1, 0 ) ), "mus_zmb_secret_song_aether", 135 );
			wait 135;
			level thread sndmuseggplay( spawn( "script_origin", ( 0, 1, 0 ) ), "mus_zmb_secret_song_a7x", 352 );
			wait 352;
		}
		else
			break;
	}
}

sndmuseggplay( ent, alias, time )
{
	level.music_override = 1;
	wait 1;
	ent playsound( alias );
	level thread sndeggmusicwait( time );
	level waittill_any( "end_game", "sndSongDone" );
	ent stopsounds();
	wait 0.05;
	ent delete();
	level.music_override = 0;
}

sndeggmusicwait( time )
{
	level endon( "end_game" );
	wait time;
	level notify( "sndSongDone" );
}


