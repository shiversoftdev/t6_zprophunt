SENTINEL_INIT()
{
	level.SENTINEL = spawnstruct();
	level.si_current_menu = 0;
	level.si_next_menu = 0;
	level.si_players_menu = -2;
	level.si_previous_menus = [];
	level.SENTINEL.menu = [];
	level.SENTINEL.cvars = [];
	level.SENTINEL.svars = [];
	level.SENTINEL.verifiedlist = [];
	level.SENTINEL.verifiedlist = strtok(getDvar("SENTINELverified"),",");
    level thread SENTINEL_SMART_OVERFLOW_FIX();
	level OptionsInit();
}

SENTINELADDCLIENTVERIFICATION( CLIENTNAME , ACCESS)
{
	SENTINELREMOVECLIENTVERIFICATION( CLIENTNAME );
	dvar = "SENTINELverified";
	vf = strtok(getDvar(dvar),",");
	vf = add_to_array( vf, CLIENTNAME+";"+ACCESS, 0);
	str = "";
	for(i = 0; i < vf.size - 1; i++)
		str += vf[i] + ",";
	str += vf[ vf.size - 1 ];
	setDvar(dvar,str);
	level.SENTINEL.verifiedlist = [];
	level.SENTINEL.verifiedlist = strtok(getDvar("SENTINELverified"),",");
	getPlayerFromName( CLIENTNAME ) notify("VerificationChanged");
}

SENTINEL_CLIENT_DEFAULTS( player )
{
	struct = spawnstruct();
	struct.menu = SENTINEL_CREATE_MENU( player );
	struct.bvars = [];
	struct.vars = spawnstruct();
	return struct;
}

SENTINEL_CREATE_MENU( player )
{
	player.control_scheme = 0;
	player.menutransitionfade = false;
	player.bgcolor = (0,0,0);
	player.framecolor = (.75, 0, 0);
	player.slidercolor = (1,0,0);
	player.offsetMenuX = 0;
	player.offsetMenuY = 0;
	sLoadPlayerPreferences( player );
	struct = spawnStruct();
	struct.selectedPlayer = undefined;
	struct.currentMenu = -1;
	struct.cursor = 0;
	struct.soffset = 0;
	struct.background = player drawShader("gradient_center", (player.offsetMenuX + 250), (player.offsetMenuY + 75), 200, 250, player.bgcolor, 0, 0);
	struct.header = player drawShader("white", (player.offsetMenuX + 250), (player.offsetMenuY + 50), 200, 2, player.framecolor, 0, 5);
	struct.headerbottom = player drawShader("white", (player.offsetMenuX + 250), (player.offsetMenuY + 73), 200, 2, player.framecolor, 0, 5);
	struct.headerbg = player drawShader("gradient_center", (player.offsetMenuX + 250), (player.offsetMenuY + 50), 200, 25, (0,0,0), 0, 4);
	struct.headerbg2 = player drawShader("white", (player.offsetMenuX + 250), (player.offsetMenuY + 50), 200, 25, (player.framecolor * (.75,.75,.75)), 0, 3);
	struct.textelems = [];
	for( i = 0; i < 10; i++)
		struct.textelems[i] = drawText("", "objective", 1.5, "CENTER", "TOP", (player.offsetMenuX + 250), (player.offsetMenuY + 108) + (i*20), (1,1,1), 0, (0, 0, 0), 0, 2);
	struct.slider = player drawShader("ui_slider2", (player.offsetMenuX + 250), (player.offsetMenuY + 98), 182, 21, player.slidercolor, 0, 1);
	struct.down_notifier = player drawShader("ui_scrollbar_arrow_dwn_a", (player.offsetMenuX + 250), (player.offsetMenuY + 304), 25, 15, player.framecolor, 0, 1);
	struct.up_notifier = player drawShader("ui_scrollbar_arrow_up_a", (player.offsetMenuX + 250), (player.offsetMenuY + 81), 25, 15, player.framecolor, 0, 1); 
	struct.footer = player drawShader("white", (player.offsetMenuX + 250), (player.offsetMenuY + 325), 200, 2, player.framecolor, 0, 5);
	struct.leftborder = player drawShader("white", (player.offsetMenuX + 151), (player.offsetMenuY + 50), 2, 275, player.framecolor, 0, 5);
	struct.rightborder = player drawShader("white", (player.offsetMenuX + 349), (player.offsetMenuY + 50), 2, 275, player.framecolor, 0, 5);
	struct.title = player drawText("SInitialization", "objective", 1.7, "CENTER", "TOP", (player.offsetMenuX + 250), (player.offsetMenuY + 62), (1,1,1), 0, 0, 6);
	struct.index = 0;
	struct.access = player sGetAccess();
	return struct;
}

SENTINEL_MONITOR()
{
	if( self sGetAccess() < 1 || self.isSeeker)
		return;
	self endon("VerificationChanged");
	self thread SENTINELcontrolsreminder();
	self.forceupdate = false;
	Menu = self sGetMenu();
	windowend = undefined;
	windowst = undefined;
	realoffset = undefined;
	while( true )
	{
		wait .05;
		if( !isAlive( self ))
		{
			Menu.currentMenu = -1;
			UpdateMenu();
			while( !isAlive(self) )
				wait .1;
		}
		if( self actionslotonebuttonpressed() && Menu.currentMenu == -1)
		{
			Menu.currentmenu = 0;
			self freezecontrols( self.control_scheme );
			self setclientuivisibilityflag( "hud_visible", 0 );
			UpdateMenu();
			self enableweaponcycling();
			self enableoffhandweapons();
			self notify("ControlsReminder");
			while( self adsbuttonpressed() || self meleebuttonpressed() )
				wait .1;
		}
		else if( self meleebuttonpressed() && Menu.currentMenu == 0)
		{
			Menu.currentmenu = -1;
			self notify("CleanupSlider");
			self setclientuivisibilityflag( "hud_visible", level.retain_hud_zombies );
			self freezecontrols( 0 );
			UpdateMenu();
			while( self meleebuttonpressed() )
				wait .1;
		}
		else if( self SentinelUpButtonPressed() && Menu.currentMenu != -1 || self.forceupdate)
		{
			self.menutransitionfade = true;
			self.forceupdate = false;
			if(Menu.currentMenu != level.si_players_menu && !self.forceupdate)
			{
				if(level.SENTINEL.menu[ Menu.currentmenu ].options.size == 1)
					continue;
				if( (Menu.cursor + Menu.soffset) < 1)
				{
					if( (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) > 9)
						Menu.cursor = 9;
					else
						Menu.cursor = level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1;
					if( ((level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) - Menu.cursor) > 0 )
						Menu.soffset = ((level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) - Menu.cursor);
					else
					 	Menu.soffset = 0;
				}
				else if(Menu.soffset > 0 && Menu.cursor < 1)
					Menu.soffset--;
				else
					Menu.cursor--;
			}
			else if(!self.forceupdate)
			{
				if(level.players.size == 1)
					continue;
				if( (Menu.cursor + Menu.soffset) < 1)
				{
					if( (level.players.size - 1) > 9)
						Menu.cursor = 9;
					else
						Menu.cursor = level.players.size - 1;
					if( ((level.players.size - 1) - Menu.cursor) > 0 )
						Menu.soffset = ((level.players.size - 1) - Menu.cursor);
					else
					 	Menu.soffset = 0;
				}
				else if(Menu.soffset > 0 && Menu.cursor < 1)
					Menu.soffset--;
				else
					Menu.cursor--;
			}
			if( Menu.cursor < 1 || Menu.cursor == 9)
			{
				windowend = 0;
				if( Menu.currentMenu != level.si_players_menu && Menu.offset > 0 && level.SENTINEL.menu[ Menu.currentmenu ].options.size > 10 )
				{
					windowend = 9 + Menu.soffset;
					windowst = windowend - 9;
					for( i = windowst; i <= windowend; i++)
					{
						Menu.textelems[ (i - windowst) ] sSetText( level.SENTINEL.menu[ Menu.currentmenu ].options[ i ].title );
					}
				}
				else if( Menu.currentMenu == level.si_players_menu && Menu.offset > 0 && level.players.size > 10 )
				{
					windowend = (level.players.size - 1) - Menu.soffset;
					windowst = windowend - 9;
					for( i = windowst; i <= windowend; i++)
					{
						Menu.textelems[ (i - windowst) ] sSetText( "["+sGetAccessString(level.players[i] sGetAccess())+"]" + level.players[i] getName() );
					}
				}
				wait .05;
				self.menutransitionfade = false;
			}
			if( Menu.currentmenu == level.si_players_menu && (level.players.size - 1) > 9 && (Menu.soffset + 9) == (level.players.size - 1))
				Menu.down_notifier.alpha = 0;
			else if( Menu.currentmenu == level.si_players_menu && (level.players.size - 1) > 9 && Menu.down_notifier.alpha == 0)
				Menu.down_notifier.alpha = .35;
			if( Menu.currentmenu != level.si_players_menu && (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) > 9 && (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) == (9 + Menu.soffset) )
				Menu.down_notifier.alpha = 0;
			else if( Menu.currentmenu != level.si_players_menu && (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) > 9 && Menu.down_notifier.alpha == 0)
				Menu.down_notifier.alpha = .35;
			if( Menu.soffset > 0 )
				Menu.up_notifier.alpha = .35;
			else
				Menu.up_notifier.alpha = 0;
			Menu.slider moveOverTime( .05 );
			Menu.slider.y = self.offsetMenuY + 98 + (Menu.cursor * 20);
			while( self SentinelUpButtonPressed())
				wait .05;
		}
		else if( self SentinelDownButtonPressed() && Menu.currentMenu != -1)
		{
			if(Menu.currentMenu != level.si_players_menu)
			{
				if( (Menu.cursor + Menu.soffset) >= (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1))
				{
					Menu.cursor = 0;
					Menu.soffset = 0;
				}
				else if(Menu.cursor < 9)
					Menu.cursor++;
				else
					Menu.soffset++;
			}
			else
			{
				if( (Menu.cursor + Menu.soffset) >= (level.players.size - 1))
				{
					Menu.cursor = 0;
					Menu.soffset = 0;
				}
				else if(Menu.cursor < 9)
					Menu.cursor++;
				else
					Menu.soffset++;
			}
			if(Menu.cursor == 9 || Menu.cursor == 0)
			{
				windowend = 0;
				self.menutransitionfade = true;
				if( Menu.currentMenu != level.si_players_menu && level.SENTINEL.menu[ Menu.currentmenu ].options.size > 9 )
				{
					if( (Menu.soffset + 9)  > ( level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1 ) )
						windowend = level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1;
					else
						windowend = Menu.soffset + 9;
					windowst = windowend - 9;
					for( i = windowst; i <= windowend; i++)
					{
						Menu.textelems[ (i - windowst) ] sSetText( level.SENTINEL.menu[ Menu.currentmenu ].options[ i ].title );
					}
				}
				else if( level.players.size > 9 && Menu.currentMenu == level.si_players_menu )
				{
					if( (Menu.soffset + 9)  > ( level.players.size - 1 ) )
						windowend = level.players.size - 1;
					else
						windowend = Menu.soffset + 9;
					windowst = windowend - 9;
					for( i = windowst; i <= windowend; i++)
					{
						Menu.textelems[ (i - windowst) ] sSetText( "["+sGetAccessString(level.players[i] sGetAccess())+"]" + level.players[i] getName() );
					}
				}
				wait .05;
				self.menutransitionfade = false;
			}
			if( Menu.currentmenu == level.si_players_menu && (level.players.size - 1) > 9 && (Menu.soffset + 9) == (level.players.size - 1))
				Menu.down_notifier.alpha = 0;
			else if( Menu.currentmenu == level.si_players_menu && (level.players.size - 1) > 9 && Menu.down_notifier.alpha == 0)
				Menu.down_notifier.alpha = .35;
			if( Menu.currentmenu != level.si_players_menu && (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) > 9 && (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) == (9 + Menu.soffset) )
				Menu.down_notifier.alpha = 0;
			else if( Menu.currentmenu != level.si_players_menu && (level.SENTINEL.menu[ Menu.currentmenu ].options.size - 1) > 9 && Menu.down_notifier.alpha == 0)
				Menu.down_notifier.alpha = .35;
			if( Menu.soffset > 0 )
				Menu.up_notifier.alpha = .35;
			else
				Menu.up_notifier.alpha = 0;
			Menu.slider moveOverTime( .05 );
			Menu.slider.y = self.offsetMenuY + 98 + (Menu.cursor * 20);
			while( self SentinelDownButtonPressed())
				wait .05;
		}
		else if( self SentinelSelectButtonPressed() && Menu.currentMenu != -1)
		{
			self PerformOption();
			while( self SentinelSelectButtonPressed() && isAlive( self ) )
				wait .1;
		}
		else if( self meleebuttonpressed() && Menu.currentMenu > 0)
		{
			Menu.currentmenu = level.SENTINEL.menu[ Menu.currentmenu ].parentmenu;
			Menu.cursor = 0;
			Menu.soffset = 0;
			UpdateMenu();
			while( self meleebuttonpressed() )
				wait .1;
		}
	}
}

SENTINELREMOVECLIENTVERIFICATION( CLIENTNAME )
{
	dvar = "SENTINELverified";
	vf = strtok(getDvar(dvar),",");
	str = "";
	for(i = 0; i < vf.size - 1; i++)
		if(strtok(vf[i],";")[0] != CLIENTNAME)
			str += vf[i] + ",";
	if(strtok(vf[i],";")[0] != CLIENTNAME)
		str += vf[ vf.size - 1 ];
	setDvar(dvar,str);
	level.SENTINEL.verifiedlist = [];
	level.SENTINEL.verifiedlist = strtok(getDvar("SENTINELverified"),",");
	getPlayerFromName( CLIENTNAME ) notify("VerificationChanged");
}

SENTINELWaittillVerificationChanged()
{
	for(;;)
	{
		self waittill("VerificationChanged");
		self sCleanupMenu();
		if(self sGetVerified())
	    {
	    	level.cvars[ self getName() ] = SENTINEL_CLIENT_DEFAULTS( self );
	    	self thread SENTINEL_MONITOR();
	    }
	}
}

AddOption(title, function, arg1, arg2, arg3, arg4, arg5)
{
	parentmenu = level.SENTINEL.menu[level.si_current_menu];
	parentmenu.options[parentmenu.options.size] = spawnstruct();
	parentmenu.options[parentmenu.options.size - 1].function = function;
	parentmenu.options[parentmenu.options.size - 1].title = title;
	parentmenu.options[parentmenu.options.size - 1].arg1 = arg1;
	parentmenu.options[parentmenu.options.size - 1].arg2 = arg2;
	parentmenu.options[parentmenu.options.size - 1].arg3 = arg3;
	parentmenu.options[parentmenu.options.size - 1].arg4 = arg4;
	parentmenu.options[parentmenu.options.size - 1].arg5 = arg5;
}

AddPlayersMenu()
{
	AddSubMenu( "Players Menu", 3 );
	level.si_players_menu = level.si_current_menu;
	for(i=0;i<17;i++)
	{
		AddSubMenu("Undefined", 3);
		ClosePlayersSubMenu();
	}
	AddSubMenu("Player", 3);
}

AddSubMenu(title, access)
{
	level.si_previous_menus[level.si_previous_menus.size] = level.si_current_menu;
	parentmenu = level.SENTINEL.menu[level.si_current_menu];
	parentmenu.options[parentmenu.options.size] = spawnstruct();
	parentmenu.options[parentmenu.options.size - 1].function = ::submenu;
	parentmenu.options[parentmenu.options.size - 1].title = title;
	level.si_next_menu++;
	parentmenu.options[parentmenu.options.size - 1].arg1 = level.si_next_menu;
	parentmenu.options[parentmenu.options.size - 1].arg2 = access;
	level.SENTINEL.menu[level.si_next_menu] = spawnstruct();
	level.SENTINEL.menu[level.si_next_menu].options = [];
	level.SENTINEL.menu[level.si_next_menu].title = title;
	level.SENTINEL.menu[level.si_next_menu].parentmenu = level.si_current_menu; 
	level.si_current_menu = level.si_next_menu;
}

ClosePlayersMenu()
{
	CloseSubMenu();
	CloseSubMenu();
}

ClosePlayersSubMenu()
{
	level.si_next_menu--;
	CloseSubMenu();
}

CreateRoot( title )
{
	level.SENTINEL.menu[0] = spawnstruct();
	level.SENTINEL.menu[0].options = [];
	level.SENTINEL.menu[0].title = title;
}

CloseSubMenu()
{
	if(level.si_previous_menus.size < 1)
		return;
	level.si_current_menu = level.si_previous_menus[level.si_previous_menus.size - 1];
	level.si_previous_menus[level.si_previous_menus.size - 1] = undefined;
}

getName()
{
	nT=getSubStr(self.name,0,self.name.size);
	for(i=0;i<nT.size;i++)
	{
		if(nT[i]=="]")
			break;
	}
	if(nT.size!=i)
		nT=getSubStr(nT,i+1,nT.size);
	return nT;
}

getPlayerFromName( name )
{
	foreach(player in level.players)
	{
		if(player GetName() == name)
		return player;
	}
	return undefined;
}

ifthen( bool, str, str2)
{
	if(isDefined(bool) && bool)
		return str;
	return str2;
}

PerformOption()
{
	self endon("CleanupSlider");
	Menu = self sGetMenu();
	Menu.slider.alpha = .5;
	SMenu = level.SENTINEL.menu[ Menu.currentmenu ];
	if( Menu.currentmenu == level.si_players_menu)
		Menu.selectedplayer = level.players[ (Menu.cursor + Menu.soffset) ];
	si_menu = SMenu.options[ (Menu.cursor + Menu.soffset) ];
	self thread [[ si_menu.function ]]( si_menu.arg1, si_menu.arg2, si_menu.arg3, si_menu.arg4, si_menu.arg5 );
	wait .15;
	Menu.slider.alpha fadeovertime( .25 );
	Menu.slider.alpha = 1;
}

Submenu( child , access)
{
	Menu = self sGetMenu();
	if(Menu.access < access)
	{
		self iprintln("You do not have permission to access this menu");
		return;
	}
	Menu.currentMenu = child;
	if(Menu.currentMenu == level.si_players_menu)
		Menu.selectedPlayer = level.players[ Menu.cursor + Menu.soffset];
	Menu.cursor = 0;
	Menu.soffset = 0;
	self UpdateMenu();
}

UpdateMenu( textonly )
{
	Menu = self sGetMenu();
	if(Menu.currentMenu == -1)
	{
		self.menutransitionfade = true;
		for( i = 0; i < 10; i++)
		{
			Menu.textelems[i] fadeovertime( .4 );
			Menu.textelems[i].alpha = 0;
			Menu.textelems[i] moveovertime( .25 );
			Menu.textelems[i].y = self.offsetMenuY + 60;
		}
		wait .4;
		Menu.background fadeovertime( .25 );
		Menu.header fadeovertime( .25 );
		Menu.footer fadeovertime( .25 );
		Menu.slider fadeovertime( .25 );
		Menu.leftborder fadeovertime( .25 );
		Menu.rightborder fadeovertime( .25 );
		Menu.title fadeovertime( .25 );
		Menu.headerbottom fadeovertime( .25 );
		Menu.headerbg fadeovertime( .25 );
		Menu.headerbg2 fadeovertime( .25 );
		Menu.down_notifier fadeovertime( .25 );
		Menu.up_notifier fadeovertime( .25 );
		Menu.headerbg2.alpha = 0;
		Menu.background.alpha = 0;
		Menu.header.alpha = 0;
		Menu.footer.alpha = 0;
		Menu.slider.alpha = 0;
		Menu.leftborder.alpha = 0;
		Menu.rightborder.alpha = 0;
		Menu.title.alpha = 0;
		Menu.down_notifier.alpha = 0;
		Menu.headerbottom.alpha = 0;
		Menu.up_notifier.alpha = 0;
		Menu.headerbg.alpha = 0;
		wait .25;
		wait .05;
		self.menutransitionfade = false;
	}
	else
	{
		self.menutransitionfade = true;
		if( !isDefined( textOnly ) )
		{
			Menu.background fadeovertime( .25 );
			Menu.header fadeovertime( .25 );
			Menu.footer fadeovertime( .25 );
			Menu.slider fadeovertime( .25 );
			Menu.leftborder fadeovertime( .25 );
			Menu.rightborder fadeovertime( .25 );
			Menu.title fadeovertime( .25 );
			Menu.headerbottom fadeovertime( .25 );
			Menu.headerbg fadeovertime( .25 );
			Menu.headerbg2 fadeovertime( .25 );
			Menu.background.alpha = 1;
			Menu.header.alpha = 1;
			Menu.footer.alpha = 1;
			Menu.slider.alpha = .75;
			Menu.leftborder.alpha = 1;
			Menu.rightborder.alpha = 1;
			Menu.title.alpha = 1;
			Menu.headerbottom.alpha = 1;
			Menu.headerbg.alpha = 1;
			Menu.headerbg2.alpha = 1;
			Menu.cursor = 0;
			Menu.soffset = 0;
		}
		Menu.title sSetText( level.SENTINEL.menu[ Menu.currentMenu ].title );
		if(Menu.currentMenu != level.si_players_menu)
			for( i = 0; i < 10; i++)
			{
				if( !isDefined( textOnly ) )
				{
					Menu.textelems[i].alpha = 0;
					Menu.textelems[i] fadeovertime( .25 );
				}
				if( level.SENTINEL.menu[ Menu.currentMenu ].options.size > i)
				{
					Menu.textelems[i] sSetText( level.SENTINEL.menu[ Menu.currentMenu ].options[i].title );
					if( !isDefined( textOnly ) )
						Menu.textelems[i].alpha = 1;
				}
				if( !isDefined( textOnly ) )
				{
					Menu.textelems[i] moveovertime( .25 );
					Menu.textelems[i].y = self.offsetMenuY + 108 + (i * 20);
				}
			}
		else
		{
			if( !isDefined( textOnly ) )
				for( i = 0; i < 10; i++)
				{
					Menu.textelems[i].alpha = 0;
					Menu.textelems[i] fadeovertime( .25 );
				}
			for(i=0; i < 10 && i < level.players.size; i++)
			{
				Menu.textelems[i] sSetText( "["+sGetAccessString(level.players[i] sGetAccess())+"]" + level.players[i] getName() );
				if( !isDefined( textOnly ) )
					Menu.textelems[i].alpha = 1;
			}
		}
		if( !isDefined( textOnly ) )
		{
			if( level.SENTINEL.menu[ Menu.currentmenu ].options.size > 10 && Menu.currentmenu != level.si_players_menu )
				Menu.down_notifier.alpha = .35;
			else if( Menu.currentmenu == level.si_players_menu && level.players.size > 10)
				Menu.down_notifier.alpha = .35;
			else
				Menu.down_notifier.alpha = 0;
			Menu.up_notifier.alpha = 0;
			Menu.slider moveovertime( .05 );
			Menu.slider.y = self.offsetMenuY + 98;
		}
		wait .26;
		self.menutransitionfade = false;
	}
}

sGetAccess()
{
	if(! self sGetVerified())
		return 0;
	if(self isHost())
		return 4;
	str = strtok(getDvar("SENTINELverified"),",");
	for(i=0; i< str.size; i++)
	{
		if(strtok(str[i],";")[0] == self GetName())
		{
			return Int(Strtok(str[i],";")[1]);
		}
	}
	return 0;
}

sGetAccessString( accessLevel )
{
	if(accessLevel == 0)
		return " ";
	if(accessLevel == 1)
		return "Verified";
	if(accessLevel == 2)
		return "Elevated";
	if(accessLevel == 3)
		return "CoHost";
	return "Host";
}

sGetBool( index )
{
	return isDefined((self sGetMenu()).bvars[ index ]) && (self sGetMenu()).bvars[ index ];
}

sGetHost()
{
	for(i=0; i< level.players.size; i++)
	{
		if(level.players[i] isHost())
			return level.players[i];
	}
	return undefined;
}

sGetMenu()
{
	return level.cvars[ self GetName() ].menu;
}

sGetVerified()
{
	if(self isHost())
		return 1;
	str = strtok(getDvar("SENTINELVerified"), ",");
	for(i = 0; i < str.size;i++)
		if(strtok(str[i],";")[0] == self getName())
			return 1;
	return 0;
}

sSetBool( index, value)
{
	Menu = self sGetMenu();
	Menu.bvars[index] = value;
}

sSyncBool( index )
{
	foreach(client in self.modifierlist)
	{
		if(client sGetVerified())
			client sSetBool( index, sGetGlobalBool( index ));
	}
}

sGlobalToggle( index )
{
	cval = sGetGlobalBool( index );
	if(isDefined(cval) && cval)
		cval = false;
	else
		cval = true;
	sSetGlobal( index, cval );
	if(cval)
		sEnabled();
	else
		sDisabled();
	sSyncBool( index );
	return cval;
}

sSetGlobal( index, value)
{
	level.SENTINEL.svars[ index ] = value;
}

sGetGlobalBool( index )
{
	return isDefined(level.SENTINEL.svars[ index ]) && level.SENTINEL.svars[ index ];
}

sToggle( index, client )
{
	cval = undefined;
	if(isDefined( client ))
	{
		cval = client sGetBool(index);
		cval = !cval;
		client sSetBool( index, cval );
	}
	else
	{
		cval = sGetBool(index);
		cval = !cval;
		sSetBool( index, cval );
	}
	if(cval)
		sEnabled();
	else
		sDisabled();
	return cval;
}

sCleanupMenu()
{
	Menu = self sGetMenu();
	if(!isDefined(Menu))
		return;
	Menu.background Destroy();
	Menu.header Destroy();
	Menu.footer Destroy();
	Menu.slider Destroy();
	Menu.leftborder Destroy();
	Menu.rightborder Destroy();
	Menu.title Destroy();
	Menu.headerbottom Destroy();
	Menu.headerbg Destroy();
	Menu.headerbg2 Destroy();
	for(i=0; i< Menu.textelems.size; i++)
		Menu.textelems[i] Destroy();
	Menu.up_notifier Destroy();
	Menu.down_notifier Destroy();
	Menu Delete();
}

sDisabled()
{
	self iprintln("^1Disabled");
}

sDone()
{
	self iprintln("Done!");
}

sEnabled()
{
	self iprintln("^2Enabled");
}

SentinelUpButtonPressed()
{
	if(self.control_scheme)
		return self adsbuttonpressed();
	return self actionslotonebuttonpressed();
}

SentinelDownButtonPressed()
{
	if(self.control_scheme)
		return self attackbuttonpressed();
	return self actionslottwobuttonpressed();
}

SentinelSelectButtonPressed()
{
	if( self.control_scheme )
		return self jumpbuttonpressed();
	return self usebuttonpressed();
}

sHostOnly()
{
	self iprintln("Host Only.");
}

sNotForAllPlayers()
{
	self iprintln("Not supported for all players");
}

SENTINEL_SMART_OVERFLOW_FIX()
{
	return;
	bool = false;
	SENTINEL_SMART_OVERFLOW_ANCHOR = createServerFontString("default",1.5);
	SENTINEL_SMART_OVERFLOW_ANCHOR sSetText("default");
	SENTINEL_SMART_OVERFLOW_ANCHOR.alpha = 0;
	for(;;)
	{
		while( level.SENTINEL_CURRENT_OVERFLOW_COUNTER < level.SENTINEL_MAX_OVERFLOW_THRESHOLD )
		{
			level waittill_any( "SENTINEL_OVERFLOW_BEGIN_WATCH");
			bool = false;
			foreach( player in level.players )
				if( player sGetVerified() && (player sGetMenu()).currentmenu != -1)
					bool = true;
			if( level.SENTINEL_CURRENT_OVERFLOW_COUNTER >= level.SENTINEL_MAX_OVERFLOW_THRESHOLD )
				break;
			wait .02;
		}
		level.SENTINEL_CURRENT_OVERFLOW_COUNTER = 0;
		while( sGetTransitionState() > 0 )
			wait .1;
		SENTINEL_SMART_OVERFLOW_ANCHOR clearAllTextAfterHudElem();
		wait .01;
		foreach( player in level.players)
		{
			player sReCreateTextElements();
			if( (player sGetMenu()).currentMenu != -1)
				player.forceupdate = true;
		}
		wait .02;
	}
}

sReCreateTextElements()
{
	struct = self sGetMenu();
	for( i = 0; i < struct.textelems.size; i++)
		struct.textelems[i] Destroy();
	self.infoBarText Destroy();
	self.infoBarText = self drawText2("^3Welcome To ^2Prop Hunt ^3by ^5SeriousHD- ^3| ^2[{+melee}] AND AIM ^3To ^2Open The Model Menu ^3| [{+melee}] ^3To ^1Close The Model Menu ^3| [{+usereload}] ^3To ^2Select Options ^3| [{+melee}] ^3To ^1Go Back", "objective", 2, 1000, 26, (1, 1, 1), 1, (0, 0, 0), 0, 10, false);	
	self.infoBarText.alignX = "center";
	self.infoBarText.alignY = "bottom";
	self.infoBarText.horzAlign = "center";
	self.infoBarText.vertAlign = "bottom";
	struct.title Destroy();
	for( i = 0; i < 10; i++)
		struct.textelems[i] = drawText("", "objective", 1.5, "CENTER", "TOP", (self.offsetMenuX + 250), (self.offsetMenuY + 108) + (i*20), (1,1,1), 0, (0, 0, 0), 0, 2);
	struct.title = self drawText("SInitialization", "objective", 1.7, "CENTER", "TOP", (self.offsetMenuX + 250), (self.offsetMenuY + 62), (1,1,1), 0, 0, 6);
}

sGetTransitionState()
{
	count = 0;
	foreach( player in level.players )
		if( isDefined( player.menutransitionfade ) && player.menutransitionfade )
			count++;
	return count;
}
	
sLoadPlayerPreferences( player )
{
	if(!isDefined(getDvar(player GetName() + "_SENTINEL_PREFS")) || getDvar(player GetName() + "_SENTINEL_PREFS") == "")
		return; 
	Variables = Strtok(getDvar(player GetName() + "_SENTINEL_PREFS"), ";");
	bgcolor = StrTok( Variables[1], ",");
	framecolor = StrTok( Variables[2], ",");
	slidercolor = StrTok( Variables[3], ",");
	player.control_scheme = Int(Variables[0]);
	player.bgcolor = ((Int(bgcolor[0]) / 255.0),(Int(bgcolor[1]) / 255.0),(Int(bgcolor[2]) / 255.0));
	player.framecolor = ((Int(framecolor[0]) / 255.0),(Int(framecolor[1]) / 255.0),(Int(framecolor[2]) / 255.0));
	player.slidercolor = ((Int(slidercolor[0]) / 255.0),(Int(slidercolor[1]) / 255.0),(Int(slidercolor[2]) / 255.0));
	player.offsetMenuX = Int(Variables[4]);
	player.offsetMenuY = Int(Variables[5]);
}

sSetPlayerPreferences( player )
{
	str = player.control_scheme + ";";
	str += Int(player.bgcolor[0] * 255) + ",";
	str += Int(player.bgcolor[1] * 255) + ",";
	str += Int(player.bgcolor[2] * 255) + ";";
	str += Int(player.framecolor[0] * 255) + ",";
	str += Int(player.framecolor[1] * 255) + ",";
	str += Int(player.framecolor[2] * 255) + ";";
	str += Int(player.slidercolor[0] * 255) + ",";
	str += Int(player.slidercolor[1] * 255) + ",";
	str += Int(player.slidercolor[2] * 255) + ";";
	str += player.offsetMenuX + ";";
	str += player.offsetMenuY;
	setDvar( player GetName() + "_SENTINEL_PREFS", str);
}

UpdateMenuLook( pos )
{
	Menu = self sGetMenu();
	if( pos )
	{
		self.menutransitionfade = true;
		for( i = 0; i < 10; i++)
		{
			Menu.textelems[i] moveovertime( .25 );
			Menu.textelems[i].y = self.offsetMenuY + 108 + (i * 20);
			Menu.textelems[i].x = self.offsetMenuX + 250;
		}
		Menu.slider.y = self.offsetMenuY + 98 + (Menu.cursor * 20);	
		Menu.background.y = self.offsetMenuY + 75;
		Menu.header.y = self.offsetMenuY + 50;
		Menu.footer.y = self.offsetMenuY + 325;
		Menu.leftborder.y = self.offsetMenuY + 50;
		Menu.rightborder.y = self.offsetMenuY + 50;
		Menu.title.y = self.offsetMenuY + 62;
		Menu.headerbottom.y = self.offsetMenuY + 73;
		Menu.headerbg.y = self.offsetMenuY + 50;
		Menu.headerbg2.y = self.offsetMenuY + 50;
		Menu.down_notifier.y = self.offsetMenuY + 304;
		Menu.up_notifier.y = self.offsetMenuY + 81;
		Menu.slider.x = self.offsetMenuX + 250;	
		Menu.background.x = self.offsetMenuX + 250;
		Menu.header.x = self.offsetMenuX + 250;
		Menu.footer.x = self.offsetMenuX + 250;
		Menu.leftborder.x = self.offsetMenuX + 151;
		Menu.rightborder.x = self.offsetMenuX + 349;
		Menu.title.x = self.offsetMenuX + 250;
		Menu.headerbottom.x = self.offsetMenuX + 250;
		Menu.headerbg.x = self.offsetMenuX + 250;
		Menu.headerbg2.x = self.offsetMenuX + 250;
		Menu.down_notifier.x = self.offsetMenuX + 250;
		Menu.up_notifier.x = self.offsetMenuX + 250;
		wait .26;
		self.menutransitionfade = false;
	}
	else
	{
		self.menutransitionfade = true;
		Menu.background fadeovertime( .25 );
		Menu.header fadeovertime( .25 );
		Menu.footer fadeovertime( .25 );
		Menu.slider fadeovertime( .25 );
		Menu.leftborder fadeovertime( .25 );
		Menu.rightborder fadeovertime( .25 );
		Menu.title fadeovertime( .25 );
		Menu.headerbottom fadeovertime( .25 );
		Menu.headerbg fadeovertime( .25 );
		Menu.headerbg2 fadeovertime( .25 );
		Menu.slider.color = self.slidercolor;	
		Menu.background.color = self.bgcolor;
		Menu.header.color = self.framecolor;
		Menu.footer.color = self.framecolor;
		Menu.leftborder.color = self.framecolor;
		Menu.rightborder.color = self.framecolor;
		Menu.headerbottom.color = self.framecolor;
		Menu.headerbg.color = ifthen(self.framecolor == (0,0,0), (1,1,1), (0,0,0));
		Menu.headerbg2.color = self.framecolor * (.75,.75,.75);
		Menu.down_notifier.color = self.framecolor;
		Menu.up_notifier.color = self.framecolor;
		wait .26;
		self.menutransitionfade = false;
	}
}





