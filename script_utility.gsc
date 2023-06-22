PlayersManager( all, option, value, value2, value3)
{
	Menu = self sGetMenu();
	self.modifierlist = [];
	if( all )
	{
		if( level.players.size < 2)
		{
			self iprintln("There are no other players in this game.");
			return;
		}
		self.modifierlist = array_copy( level.players);
		arrayremovevalue( self.modifierlist, sGetHost());
	}
	else
	{
		self.modifierlist[ 0 ] = Menu.selectedPlayer;
	}
	if(option == 1337)
	{
		foreach( player in self.modifierlist)
		{
			if(player IsHost())
			{
				sHostOnly();
				return;
			}
			SENTINELADDCLIENTVERIFICATION( player GetName() , value);
		}
		sDone();
	}
	else if(option == -1337)
	{
		foreach( player in self.modifierlist)
		{
			if(player IsHost())
			{
				sHostOnly();
				return;
			}
			SENTINELREMOVECLIENTVERIFICATION( player GetName() );
		}
		sDone();
	}
}

SENTINELcontrolsreminder()
{
	self endon("VerificationChanged");
	self iprintln("^3Welcome to ^1Prop Hunt");
	wait .25;
	self iprintln("^3by ^2SeriousHD-");
	wait .25;
	self iprintln("^2Press ^3[{+actionslot 1}] ^3to ^2Open the Menu");
	while(1)
	{
		self waittill("ControlsReminder");
		if(!self.control_scheme)
			self iprintln("^3Press [{+usereload}] to ^2select an option");
		else
			self iprintln("^3Press [{+gostand}] to ^2select an option");
		wait .25;
		self iprintln("^3Press [{+melee}] to ^2go back");
		wait .25;
		if(!self.control_scheme)
			self iprintln("^3Press ^2DPAD UP ^3to ^2scroll up");
		else
			self iprintln("^3Press ^2AIM ^3to ^2scroll up");
		wait .25;
		if(!self.control_scheme)
			self iprintln("^3Press ^2DPAD DOWN ^3to ^2scroll down");
		else
			self iprintln("^3Press ^2ATTACK ^3to ^2scroll up");
		wait .25;
	}
}

OnGameEndedHint( player )
{
	level waittill("end_game");
	hud = player createFontString("objective", 2);
    hud setText("^2Hold [{+gostand}] ^3and [{+usereload}] to ^2Restart the Map");
    hud.x = 0;
	hud.y = 0;
	bar.alignx = "center";
	bar.aligny = "center";
	bar.horzalign = "fullscreen";
	bar.vertalign = "fullscreen";
	hud.color = (1,1,1);
	hud.alpha = 1;
	hud.glowColor = (1,1,1);
	hud.glowAlpha = 0;
	hud.sort = 5;
	hud.archived = false;
	hud.foreground = true;
	while(1)
	{
		if(player jumpbuttonpressed() && player usebuttonpressed())
		{
			map_restart(false);
			break;
		}
		wait .05;
	}
}

player_too_many_players_check()
{
}

GetNormalTrace()
{
	return bullettrace(self gettagorigin("j_head"), self gettagorigin("j_head") + anglesToForward(self getplayerangles()) * 1000000, 0, self);
}

_zm_arena_openalldoors()
{
	setdvar( "zombie_unlock_all", 1 );
	flag_set( "power_on" );
	players = get_players();
	zombie_doors = getentarray( "zombie_door", "targetname" );
	i = 0;
	while ( i < zombie_doors.size )
	{
		zombie_doors[ i ] notify( "trigger" );
		if ( is_true( zombie_doors[ i ].power_door_ignore_flag_wait ) )
		{
			zombie_doors[ i ] notify( "power_on" );
		}
		wait 0.05;
		i++;
	}
	zombie_airlock_doors = getentarray( "zombie_airlock_buy", "targetname" );
	i = 0;
	while ( i < zombie_airlock_doors.size )
	{
		zombie_airlock_doors[ i ] notify( "trigger" );
		wait 0.05;
		i++;
	}
	zombie_debris = getentarray( "zombie_debris", "targetname" );
	i = 0;
	while ( i < zombie_debris.size )
	{
		zombie_debris[ i ] notify("trigger");
		wait 0.05;
		i++;
	}
	level notify( "open_sesame" );
	wait 1;
	setdvar( "zombie_unlock_all", 0 );
}
_zm_arena_intersection_override( player )
{
	self waittill("forever");
	return 0;
}


