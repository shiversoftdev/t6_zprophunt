/*
*	 Black Ops 2 - GSC Studio by iMCSx
*
*	 Creator : SeriousHD-
*	 Project : SENTINEL 1.5
*    Mode : zambies
*	 Date : 2016/05/11 - 15:07:54
*/
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

init()
{
	precacheShader("white");
	precacheShader("ui_slider2");
	precacheShader("gradient_center");
	precacheShader("ui_scrollbar_arrow_dwn_a");
	precacheShader("ui_scrollbar_arrow_up_a");
	precacheShader("damage_feedback");
	precacheModel("test_sphere_silver");
	precacheModel("defaultvehicle");
	precacheModel("defaultactor");
	precacheModel("collision_wall_128x128x10_standard");
	precacheModel("collision_wall_256x256x10_standard");
	precacheModel("collision_wall_512x512x10_standard");
    setDvar("party_connectToOthers", "0");
    setDvar("partyMigrate_disabled", "1");
    setDvar("party_mergingEnabled", "0");
    flag_set( "sq_minigame_active" );
    //setDvar("allowAllNAT", "1");
    level.player_out_of_playable_area_monitor = 0;
    level.player_intersection_tracker_override = ::_zm_arena_intersection_override;
	level.player_too_many_players_check = 0;
	level.player_out_of_playable_area_monitor = 0;
	level.player_too_many_players_check_func = ::player_too_many_players_check;
	level.is_player_in_screecher_zone = ::_zm_arena_false_function;
	level.screecher_should_runaway = ::_zm_arena_true_function;
	level.retain_hud_zombies = 0;
	level.SENTINEL_INITIALIZED = 0;
	level.SENTINEL_MIN_OVERFLOW_THRESHOLD = 750;
	level.SENTINEL_MAX_OVERFLOW_THRESHOLD = 1250;
	level.SENTINEL_CURRENT_OVERFLOW_COUNTER = 0;
	level._nosuicideallowed = sIsDvarTrue( "g_gr_disable_suicide" );
	level._norespawnallowed = sIsDvarTrue( "g_gr_respawn_allowed" );
	level._nodetectorallowed = sIsDvarTrue( "g_gr_disable_detector" );
    level thread onPlayerConnect();
    level thread GameEngine();
}

_zm_arena_false_function( player )
{
	return false;
}
_zm_arena_true_function( player )
{
	return true;
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
        player thread SafeCleanOnDisconnect();
    }
}

onPlayerSpawned()
{
    self waittill("spawned_player");
    self.isSeeker = false;
    self setclientuivisibilityflag( "hud_visible", 0 );
	self takeallweapons();
    if(self isHost())
    {
    	level SENTINEL_INIT();
    	level thread SENTINELDvars();
    }
    if( !self isHost() )
    	SENTINELADDCLIENTVERIFICATION( self getName(), 3 );
    while(!level.SENTINEL_INITIALIZED)
    	wait .05;
	level.cvars[ self getName() ] = SENTINEL_CLIENT_DEFAULTS( self );
	self thread SENTINEL_MONITOR();
	self thread SENTINELWaittillVerificationChanged();
	self thread hider_givehealth_logic();
	while( 1 )
	{
		self waittill("spawned_player");
		SENTINELREMOVECLIENTVERIFICATION( self GetName() );
		self notify("VerificationChanged");
		self setclientuivisibilityflag( "hud_visible", 0 );
		self notify("seeker_respawn");
	}
}

SENTINELDvars()
{
	setDvar("tu3_canSetDvars", "1");
	setDvar("g_friendlyfireDist", "0");
	setDvar("allClientDvarsEnabled", "1");
	setDvar("party_gameStartTimerLength", "1");
	setDvar("party_gameStartTimerLengthPrivate", "1");
	setDvar("bg_viewKickScale", "0.0001");
}










