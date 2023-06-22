void_handler( option, value, value2, value3, value4)
{
	if( option == 0 )
	{
		if(level._nosuicideallowed)
		{
			sDisabled();
			return;
		}
		self dodamage( 99999, self.origin);
	}
	else if( option == 2)
	{
		self setclientthirdperson( sToggle(2) );
	}
	else if( option == 1)
	{
		self thread loop_handler( 1, value);
		sDone();
	}
	else if( option == 3 )
	{
		if( sToggle( 3 ) )
			self CameraActivate(false);
	}
	else if( option == 4 )
	{
		if( sIsDvarTrue( "g_gr_respawn_allowed" ) )
		{
			SetDvar( "g_gr_respawn_allowed", "0" );
			sDisabled();
		}
		else
		{
			SetDvar( "g_gr_respawn_allowed", "1" );
			sEnabled();
		}
		level._norespawnallowed = sIsDvarTrue( "g_gr_respawn_allowed" );
	}
	else if( option == 5 )
	{
		if( sIsDvarTrue( "g_gr_disable_suicide" ) )
		{
			SetDvar( "g_gr_disable_suicide", "0" );
			sDisabled();
		}
		else
		{
			SetDvar( "g_gr_disable_suicide", "1" );
			sEnabled();
		}
		level._nosuicideallowed = sIsDvarTrue( "g_gr_disable_suicide" );
	}
	else if( option == 6 )
	{
		if( sIsDvarTrue( "g_gr_disable_detector" ) )
		{
			SetDvar( "g_gr_disable_detector", "0" );
			sDisabled();
		}
		else
		{
			SetDvar( "g_gr_disable_detector", "1" );
			sEnabled();
		}
		level._nodetectorallowed = sIsDvarTrue( "g_gr_disable_detector" );
	}
}

sIsDvarTrue( dvar )
{
	return isDefined( GetDvar(dvar) ) && GetDvar(dvar) == "1";
}

loop_handler( option, a_id, arg1 )
{
	if(option == 1)
	{
		self iprintln("^2Hold L1 to Lock model");
		oldorigin = undefined;
		self setclientplayerpushamount( 0 );
		if( isDefined( self.iconicmodelpref ) )
			self detach( self.iconicmodelpref, "tag_origin" );
		self setModel( "tag_origin" );
		self.iconicmodelpref = a_id;
		self attach( self.iconicmodelpref, "tag_origin", true );
		while( self.iconicmodelpref == a_id && !self.isseeker)
		{
			if( self adsbuttonpressed() )
			{
				self detach( self.iconicmodelpref, "tag_origin" );
				oldorigin = self.origin;
				tmodel = spawn("script_model", self.origin );
				tmodel setModel( self.iconicmodelpref );
				tmodel rotateTo( self.angles, .01 );
				self.modellock = true;
				self CameraActivate(false);
				while( Distance( self.origin, oldorigin ) < 4 && self.iconicmodelpref == a_id && !self.isseeker )
					wait .1;
				if( self.iconicmodelpref != a_id )
				{
					tmodel delete();
					self.modellock = false;
					return;
				}
				self.modellock = false;
				tmodel delete();
				self attach( self.iconicmodelpref, "tag_origin", true );
			}
			wait .1;
		}
		if( self.isseeker )
			self detach( self.iconicmodelpref, "tag_origin" );
	}
}



