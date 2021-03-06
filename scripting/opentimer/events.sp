public Action Event_SetTransmit_Client( int ent, int client )
{
	if ( ent < 1 || ent > MaxClients || client == ent ) return Plugin_Continue;
	
	
	if ( !IsPlayerAlive( client ) && GetEntPropEnt( client, Prop_Send, "m_hObserverTarget" ) == ent )
	{
		return Plugin_Continue;
	}
	
	
	if ( IsFakeClient( ent ) )
	{
		return ( g_fClientHideFlags[client] & HIDEHUD_BOTS ) ? Plugin_Handled : Plugin_Continue;
	}
	
	return ( g_fClientHideFlags[client] & HIDEHUD_PLAYERS ) ? Plugin_Handled : Plugin_Continue;
}

// Tell the client to respawn!
public Action Event_ClientDeath( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	int client;

	if ( !(client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) )) ) return;
	
	
	PRINTCHAT( client, client, CHAT_PREFIX..."Type "...CLR_TEAM..."!respawn"...CLR_TEXT..." to spawn again." );
}

// Hide player name changes. Doesn't work.
/*public Action Event_ClientName( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	bDontBroadcast = true;
	SetEventBroadcast( hEvent, true );
	
	return Plugin_Handled;
}*/

public void Event_WeaponSwitchPost( int client )
{
	// Higher the ping, the longer the transition period will be.
	SetClientFOV( client, g_iClientFOV[client] );
}

public void Event_WeaponDropPost( int client, int weapon )
{
	// This doesn't delete all the weapons.
	// In fact, this doesn't get called when player suicides.
	if ( IsValidEntity( weapon ) )
		AcceptEntityInput( weapon, "Kill" );
}

/*public Action CS_OnCSWeaponDrop( int client, int wep )
{
	return Plugin_Continue;
}*/

public Action Event_ClientTeam( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	if ( GetEventInt( hEvent, "team" ) > CS_TEAM_SPECTATOR )
	{
		CreateTimer( 1.0, Timer_ClientJoinTeam, GetEventInt( hEvent, "userid" ), TIMER_FLAG_NO_MAPCHANGE );
	}
}

// Set client ready for the map. Collision groups, bots, transparency, etc.
public Action Event_ClientSpawn( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	int client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	
	if ( client < 1 || GetClientTeam( client ) < 2 || !IsPlayerAlive( client ) ) return;
	
	
	TeleportPlayerToStart( client );
	
	// -----------------------------------------------------------------------------------------------
	// Story time!
	// 
	// Once upon a time I had a great idea of making a timer plugin. I started to experiment with movement recording and playback.
	// I was pretty happy what I had at the time. It followed you pretty well, not perfect, though.
	// The bot movement was really choppy, so I tried to perfect the movement. I recorded the player's velocity. That didn't change a thing.
	// I tried recording absolute velocity... didn't work.
	// I couldn't figure it out and months flew by... still didn't find a solution.
	// Fast forward to today! I decided to make the bots visible again since I wanted to debug the movement.
	// I was surprised how smooth it looked. I thought I had accidentally discovered the secret of smooth recording(TM).
	// Then I realized what I changed.
	// 
	// Moral of the story: DO NOT SET PLAYERS' RENDER MODE TO RENDER_NONE!
	// If you do that, all movement smoothing will be thrown out of the window.
	// This cost me almost a year of suffering, trying to figure out why my bots looked so choppy.
	// You can't imagine how enraged I was to learn that it was a simple fix.
	// I can't. I've lost the ability to can.
	// BUT YOU LEARN SOMETHING EVERY DAY! :^)
	// -----------------------------------------------------------------------------------------------
	SetEntityRenderMode( client, RENDER_TRANSALPHA );
	SetEntityRenderColor( client, _, _, _, 128 );
	
	// 2 = Disable player collisions.
	// 1 = Same + no trigger collision.
	SetEntProp( client, Prop_Send, "m_CollisionGroup", IsFakeClient( client ) ? 1 : 2 );
	
	CreateTimer( 0.1, Timer_ClientSpawn, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
}

// Continued from above event.
public Action Timer_ClientSpawn( Handle hTimer, any client )
{
	if ( !(client = GetClientOfUserId( client )) ) return Plugin_Handled;
	
	if ( g_fClientHideFlags[client] & HIDEHUD_VM )
		SetEntProp( client, Prop_Send, "m_bDrawViewmodel", 0 );
	
	SetEntProp( client, Prop_Send, "m_nHitboxSet", 2 ); // Bullets go through players.
	
	// Hide guns so they are not just floating around
	int wep;
	for ( int i = 0; i < NUM_SLOTS; i++ )
	{
		if ( (wep = GetPlayerWeaponSlot( client, i )) > 0 )
			HideEntity( wep );
		
		switch ( i )
		{
			case SLOT_BOMB :
			{
				if ( wep > 0 )
					RemoveEdict( wep );
			}
			case SLOT_SECONDARY :
			{
				if ( wep < 1 )
				{
					if ( (wep = GivePlayerItem( client, PREF_SECONDARY ) ) > 0 )
						HideEntity( wep );
					
					continue;
				}
			}
			case SLOT_MELEE :
			{
				if ( wep < 1 )
				{
					if ( (wep = GivePlayerItem( client, "weapon_knife" )) > 0 )
						HideEntity( wep );
					
					continue;
				}
			}
		}
	}
	
	if ( IsFakeClient( client ) )
	{
#if defined RECORD
		SetEntityGravity( client, 0.0 );
		SetEntityMoveType( client, MOVETYPE_NOCLIP );
#endif

		return Plugin_Handled;
	}
	
	SetClientFOV( client, g_iClientFOV[client] );
	
	return Plugin_Handled;
}

///////////
// EZHOP //
///////////
// We assume that CS:GO servers will handle the stamina themselves.
public Action Event_ClientJump( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	static int client;
	if ( !(client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) )) )
		return;
	
	
	if ( g_iClientState[client] != STATE_END )
		g_nClientJumps[client]++;
	
	if ( g_bEZHop && !HasScroll( client ) )
	{
		SetEntPropFloat( client, Prop_Send, "m_flStamina", 0.0 );
	}
}

/*public Action Event_ClientHurt( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	static int client;
	if ( !(client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) )) ) return;
	
	if ( g_bEZHop )
	{
		SetEntPropFloat( client, Prop_Send, "m_flVelocityModifier", 1.0 );
	}
	
	SetEntProp( client, Prop_Send, "m_iHealth", 100 );
}*/

public Action Event_OnTakeDamage_Client( int victim, int &attacker, int &inflictor, float &flDamage, int &fDamage )
{
	if ( g_bEZHop && !HasScroll( victim ) ) return Plugin_Handled;

	flDamage = 0.0;
	return Plugin_Changed;
}

public Action Event_RoundRestart( Handle hEvent, const char[] szEvent, bool bDontBroadcast )
{
	CheckZones();
}


//////////
// CHAT //
//////////
#if defined CHAT
	public Action Listener_Say( int client, const char[] szCommand, int argc )
	{
		// Let the server talk :^)
		if ( !client || !IsClientInGame( client ) ) return Plugin_Continue;
		
		if ( BaseComm_IsClientGagged( client ) ) return Plugin_Handled;
		
		static char szArg[256];
		GetCmdArgString( szArg, sizeof( szArg ) );
		
		StripQuotes( szArg );
		
		if ( szArg[0] == '@' || szArg[0] == '/' ) return Plugin_Handled;
		
		
#if defined VOTING
		if ( StrEqual( szArg, "rtv" ) || StrEqual( szArg, "rockthevote" ) || StrEqual( szArg, "nominate" ) || StrEqual( szArg, "choosemap" ) )
		{
			FakeClientCommand( client, "sm_choosemap" );
			return Plugin_Handled;
		}
#endif // VOTING
		
		
		if ( !IsPlayerAlive( client ) )
		{
			PrintColorChatAll( client, true, CLR_TEXT..."["...CLR_CUSTOM3..."SPEC"...CLR_TEXT..."] "...CLR_TEAM..."%N\x01: "...CLR_TEXT..."%s", client, szArg );
		}
		else
		{
			PrintColorChatAll( client, true, ""...CLR_TEAM..."%N\x01: "...CLR_TEXT..."%s", client, szArg );
		}
		
		
		// Print to server and players' consoles.
		PrintToServer( "%N: %s", client, szArg );
		
		for ( int i = 1; i <= MaxClients; i++ )
			if ( IsClientInGame( i ) ) PrintToConsole( i, "%N: %s", client, szArg );
		
		
		return Plugin_Handled;
	}
#endif // CHAT

#if defined ANTI_DOUBLESTEP
	// Anti-doublestep
	public Action Listener_AntiDoublestep_On( int client, const char[] szCommand, int argc )
	{
		if ( !(g_fClientStyleFlags[client] & STYLEFLAGS_SCROLL) )
			g_bClientHoldingJump[client] = true;
		
		return Plugin_Handled;
	}
	public Action Listener_AntiDoublestep_Off( int client, const char[] szCommand, int argc )
	{
		g_bClientHoldingJump[client] = false;
		return Plugin_Handled;
	}
#endif

public void Event_StartTouchPost_Freestyle( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;
	
	static int zone;
	zone = GetTriggerIndex( trigger );
	
	if ( trigger != g_hZones.Get( zone, view_as<int>( ZONE_ENTINDEX ) ) )
	{
		LogError( CONSOLE_PREFIX..."Invalid freestyle zone entity index!" );
		return;
	}
	
	
	static int flags;
	flags = g_hZones.Get( zone, view_as<int>( ZONE_FLAGS ) );
	
	if ( IsAllowedZone( ent, flags ) )
	{
		g_fClientFreestyleFlags[ent] = flags;
		
		if ( g_fClientHideFlags[ent] & HIDEHUD_ZONEMSG )
			return;
		
		// "FREESTYLE ALLOWED [NO SPEEDCAP]"
		static char szMsg[32];
		strcopy( szMsg, sizeof( szMsg ), "FREESTYLE ALLOWED" );
		
		if ( flags & ZONE_VEL_NOSPEEDCAP && g_iClientMode[ent] == MODE_VELCAP )
		{
			StrCat( szMsg, sizeof( szMsg ), " [NO SPEEDCAP]" );
		}
		
		PrintCenterText( ent, szMsg );
	}
}

public void Event_EndTouchPost_Freestyle( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	
	g_fClientFreestyleFlags[ent] = 0;
}

public void Event_StartTouchPost_Block( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;
	
	static int zone;
	zone = GetTriggerIndex( trigger );
	
	if ( trigger != g_hZones.Get( zone, view_as<int>( ZONE_ENTINDEX ) ) )
	{
		LogError( CONSOLE_PREFIX..."Invalid block zone entity index!" );
		return;
	}
	
	if ( !IsAllowedZone( ent, g_hZones.Get( zone, view_as<int>( ZONE_FLAGS ) ) ) )
	{
		if ( !IsSpamming( ent ) )
		{
			PRINTCHAT( ent, ent, CHAT_PREFIX..."You are not allowed to go there!" );
		}
		
		TeleportPlayerToStart( ent );
	}
}

public void Event_StartTouchPost_CheckPoint( int trigger, int ent )
{
	if ( ent < 1 || ent > MaxClients ) return;
	
	// I'm not even going to try get practising to work. It'll just be a major headache and nobody will notice it, anyway.
	if ( g_bClientPractising[ent] ) return;
	
	if ( !IsClientInGame( ent ) ) return;
	
	if ( g_hCPs == null ) return;
	
	static int cp;
	cp = GetTriggerIndex( trigger );
	if ( trigger != g_hCPs.Get( cp, view_as<int>( CP_ENTINDEX ) ) )
	{
		LogError( CONSOLE_PREFIX..."Invalid checkpoint entity index!" );
		return;
	}
	
	// Player ended up in the wrong run! :(
	if ( g_iClientRun[ent] != g_hCPs.Get( cp, view_as<int>( CP_RUN ) ) )
		return;
	
	static int id;
	id = g_hCPs.Get( cp, view_as<int>( CP_ID ) );
	
	// Client attempted to re-enter the cp.
	if ( g_iClientCurCP[ent] >= id ) return;
	
	if ( g_hClientCPData[ent] == null ) return;
	
	
	g_iClientCurCP[ent] = id;
	
	static float flCurTime;
	flCurTime = GetEngineTime();
	
	static int iCData[C_CP_SIZE];
	
	if ( !(g_fClientHideFlags[ent] & HIDEHUD_CPINFO) )
	{
		static float flBestTime;
		flBestTime = g_hCPs.Get( cp, CP_INDEX_RECTIME + ( NUM_STYLES * g_iClientMode[ent] + g_iClientStyle[ent] ) );
		
		if ( flBestTime > TIME_INVALID )
		{
			// Determine what is our reference time.
			// If no previous checkpoint is found, it is our starting time.
			static int index;
			index = g_hClientCPData[ent].Length - 1;
			
			static float flMyTime;
			
			if ( index < 0 )
			{
				flMyTime = flCurTime - g_flClientStartTime[ent];
			}
			else
			{
				// !!! .Get not working. Using .GetArray as a substitute.
				g_hClientCPData[ent].GetArray( index, iCData, view_as<int>( C_CPData ) );
				flMyTime = flCurTime - view_as<float>( iCData[C_CP_GAMETIME] );
			}
			
			static float flLeft;
			static int prefix;
			if ( flBestTime > flMyTime )
			{
				flLeft = flBestTime - flMyTime;
				prefix = '-';
			}
			else
			{
				flLeft = flMyTime - flBestTime;
				prefix = '+';
			}
			
#if defined CSGO
			PrintCenterText( ent, "CP #%i (REC <font color='%s'>%c%06.3fs</font>)",
				id + 1,
				( prefix == '+' ) ? CLR_HINT_1 : CLR_HINT_2,
				prefix,
				flLeft );
#else
			PrintCenterText( ent, "CP #%i (REC %c%06.3fs)", id + 1, prefix, flLeft );
#endif
		}
	}
	
	
	iCData[C_CP_ID] = id;
	iCData[C_CP_INDEX] = cp;
	iCData[C_CP_GAMETIME] = flCurTime;
	
	g_hClientCPData[ent].PushArray( iCData, view_as<int>( C_CPData ) );
}