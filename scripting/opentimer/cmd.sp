public Action OnPlayerRunCmd(
	int client,
	int &buttons,
	int &impulse, // Not used
	float vel[3],
	float angles[3],
	int &weapon/*,
	int &subtype, int &cmdnum, int &tickcount, int &seed, // Not used
	int mouse[2]*/ )
{
	if ( !IsPlayerAlive( client ) ) return Plugin_Continue;
	
	
	// Shared between recording and mimicing.
#if defined RECORD
	static int		iFrame[FRAME_SIZE];
	static float	vecPos[3];
#endif
	
	if ( !IsFakeClient( client ) )
	{
		if ( g_bAntiCheat_StrafeVel )
		{
			// Anti-cheat
			// Check if player has a strafe-hack that modifies the velocity and don't actually press the keys for them.
			// Can be called when tabbing back in to the game.
			// 0 = forwardspeed
			// 1 = sidespeed
			// 2 = upspeed
			if ( 	vel[0] != 0.0 && !( buttons & IN_FORWARD || buttons & IN_BACK ) ||
					vel[1] != 0.0 && !( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT ) )
			{
				// Allow to do it thrice.
				if ( ++g_nClientCheatDetections[client] >= MAX_CHEATDETECTIONS && g_iClientState[client] == STATE_RUNNING )
				{
					TeleportPlayerToStart( client );
				}
				
				if ( !IsSpamming( client ) )
				{
					PRINTCHAT( client, client, CHAT_PREFIX..."Potential cheat detected!" );
					PrintToServer( CONSOLE_PREFIX..."Potential cheat detected (%N)!", client );
				}
				
				return Plugin_Handled;
			}
		}
		
		// +left/+right
		if ( !g_bAllowLeftRight && ( buttons & IN_LEFT || buttons & IN_RIGHT ) )
		{
			if ( g_iClientState[client] == STATE_RUNNING )
			{
				TeleportPlayerToStart( client );
			}
			
			if ( !IsSpamming( client ) )
			{
				PRINTCHAT( client, client, CHAT_PREFIX...""...CLR_TEAM..."+left"...CLR_TEXT..." and "...CLR_TEAM..."+right"...CLR_TEXT..." are not allowed!" );
			}
			
			return Plugin_Continue;
		}
		
		static int fFlags;
		fFlags = GetEntProp( client, Prop_Data, "m_fFlags" );
		
		// MODES
		switch ( g_iClientStyle[client] )
		{
			case STYLE_SW :
			{
				if ( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT )
					CheckFreestyle( client );
			}
			case STYLE_W :
			{
				if ( buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT )
					CheckFreestyle( client );
			}
			case STYLE_RHSW :
			{
				// Somehow I feel like I'm making this horribly complicated when in reality it's simple.
				
				// Not holding all keys.
				if ( !( buttons & IN_BACK && buttons & IN_FORWARD && buttons & IN_MOVELEFT && buttons & IN_MOVERIGHT ) )
				{
					// Let players fail.
					if ( buttons & IN_BACK && !( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT ) )
						CheckStyleFails( client );
					else if ( buttons & IN_FORWARD && !( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT ) )
						CheckStyleFails( client );
					else if ( buttons & IN_MOVELEFT && !( buttons & IN_FORWARD || buttons & IN_BACK ) )
						CheckStyleFails( client );
					else if ( buttons & IN_MOVERIGHT && !( buttons & IN_FORWARD || buttons & IN_BACK ) )
						CheckStyleFails( client );
					// Holding opposite keys.
					else if ( buttons & IN_BACK && buttons & IN_FORWARD )
						CheckStyleFails( client );
					else if ( buttons & IN_MOVELEFT && buttons & IN_MOVERIGHT )
						CheckStyleFails( client );
					// Reset fails if nothing else happened.
					else if ( g_nClientStyleFail[client] > 0 )
						g_nClientStyleFail[client]--;
				}
			}
			case STYLE_HSW :
			{
				if ( buttons & IN_BACK )
					CheckFreestyle( client );
				else if ( !( buttons & IN_FORWARD ) && ( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT ) )
					CheckFreestyle( client );
				// Let players fail.
				else if ( buttons & IN_FORWARD && !( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT ) )
					CheckStyleFails( client );
				// Reset fails if nothing else happened.
				else if ( g_nClientStyleFail[client] > 0 )
					g_nClientStyleFail[client]--;
			}
			case STYLE_A_D :
			{
				if ( buttons & IN_FORWARD || buttons & IN_BACK )
					CheckFreestyle( client );
				// Determine which button player wants to hold.
				else if ( !g_iClientPrefButton[client] )
				{
					if ( buttons & IN_MOVELEFT ) g_iClientPrefButton[client] = IN_MOVELEFT;
					else if ( buttons & IN_MOVERIGHT ) g_iClientPrefButton[client] = IN_MOVERIGHT;
				}
				// Else, check if they are holding the opposite key!
				else if ( g_iClientPrefButton[client] == IN_MOVELEFT && buttons & IN_MOVERIGHT )
					CheckFreestyle( client );
				else if ( g_iClientPrefButton[client] == IN_MOVERIGHT && buttons & IN_MOVELEFT )
					CheckFreestyle( client );
			}
		}
		
		
		if ( fFlags & FL_ONGROUND )
		{
			// VELCAP
			if ( g_iClientMode[client] == MODE_VELCAP && !( g_fClientFreestyleFlags[client] & ZONE_VEL_NOSPEEDCAP ) )
			{
				static float vecVel[3];
				GetEntPropVector( client, Prop_Data, "m_vecVelocity", vecVel );
				
				static float flSpd;
				flSpd = GetEntitySpeedSquared( client );
				
				if ( flSpd > g_flVelCapSq )
				{
					flSpd = SquareRoot( flSpd ) / g_flVelCap;
					
					vecVel[0] /= flSpd;
					vecVel[1] /= flSpd;
					
					TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, vecVel );
				}
			}
			
#if defined ANTI_DOUBLESTEP
			if ( g_bAutoHop && g_bClientHoldingJump[client] ) buttons |= IN_JUMP;
#endif
		}
		// AUTOHOP
		else if ( g_bAutoHop && !HasScroll( client ) )
		{
			buttons &= ~IN_JUMP;
		}
		
		
		
		// Reset field of view in case they reloaded their gun.
		if ( buttons & IN_RELOAD )
		{
			SetClientFOV( client, g_iClientFOV[client] );
		}
		
		// Rest what we do is done in running only.
		if ( g_iClientState[client] != STATE_RUNNING ) return Plugin_Continue;
		
		
		///////////////
		// RECORDING //
		///////////////
#if defined RECORD
		if ( g_bClientRecording[client] && g_hClientRec[client] != null )
		{
			// Remove distracting buttons.
			iFrame[FRAME_FLAGS] = ( buttons & IN_DUCK ) ? FRAMEFLAG_CROUCH : 0;
			
			// Do weapons.
			// 0 = No changed weapon.
			/*if ( weapon )
			{
				switch ( FindSlotByWeapon( client, weapon ) )
				{
					case SLOT_PRIMARY :
					{
						iFrame[FRAME_FLAGS] |= FRAMEFLAG_PRIMARY;
					}
					case SLOT_SECONDARY :
					{
						iFrame[FRAME_FLAGS] |= FRAMEFLAG_SECONDARY;
					}
					case SLOT_MELEE :
					{
						iFrame[FRAME_FLAGS] |= FRAMEFLAG_MELEE;
					}
				}
			}
			else if ( buttons & IN_ATTACK )
			{
				iFrame[FRAME_FLAGS] |= FRAMEFLAG_ATTACK;
			}
			else if ( buttons & IN_ATTACK2 )
			{
				iFrame[FRAME_FLAGS] |= FRAMEFLAG_ATTACK2;
			}*/
			
			ArrayCopy( angles, iFrame[FRAME_ANG], 2 );
			
			GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecPos );
			ArrayCopy( vecPos, iFrame[FRAME_POS], 3 );
			
			
			// Is our recording longer than max length.
			if ( ++g_nClientTick[client] > g_iRecMaxLength[ g_iClientRun[client] ][ g_iClientStyle[client] ][ g_iClientMode[client] ] )
			{
				if ( g_nClientTick[client] >= RECORDING_MAX_LENGTH )
					PRINTCHAT( client, client, CHAT_PREFIX..."Your time was too long to be recorded!" );
				
				g_nClientTick[client] = 0;
				g_bClientRecording[client] = false;
				
				if ( g_hClientRec[client] != null )
				{
					delete g_hClientRec[client];
					g_hClientRec[client] = null;
				}
			}
			else
			{
				g_hClientRec[client].PushArray( iFrame, view_as<int>( RecData ) );
			}
		}
#endif
		
		// Don't calc sync and strafes for special styles.
		if ( g_iClientStyle[client] == STYLE_W || g_iClientStyle[client] == STYLE_A_D ) return Plugin_Continue;
		
		
		static float flClientLastVel[MAXPLAYERS_BHOP];
		static float flClientPrevYaw[MAXPLAYERS_BHOP];
		
		// We don't want ladders or water counted as jumpable space.
		if ( GetEntityMoveType( client ) != MOVETYPE_WALK || GetEntProp( client, Prop_Send, "m_nWaterLevel" ) > 1 )
		{
			flClientLastVel[client] = 0.0;
			flClientPrevYaw[client] = angles[1];
			
			return Plugin_Continue;
		}
		
		// If we're on the ground and not jumping, we reset our last speed.
		if ( fFlags & FL_ONGROUND && !( buttons & IN_JUMP ) )
		{
			flClientLastVel[client] = 0.0;
			flClientPrevYaw[client] = angles[1];
			
			return Plugin_Continue;
		}
		
		
		///////////////////////////
		// SYNC AND STRAFE COUNT //
		///////////////////////////
		// The reason why we don't just use mouse[0] to determine whether our player is strafing is because it isn't reliable.
		// If a player is using a strafe hack, the variable doesn't change.
		// If a player is using a controller, the variable doesn't change. (unless using no acceleration)
		// If a player has a controller plugged in and uses mouse instead, the variable doesn't change.
		static int iClientLastStrafe[MAXPLAYERS_BHOP] = { STRAFE_INVALID, ... };
		
		// Not on ground, moving mouse and we're pressing at least some key.
		if ( angles[1] != flClientPrevYaw[client] && ( buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_FORWARD || buttons & IN_BACK ) )
		{
			static int iClientSync[MAXPLAYERS_BHOP][NUM_STRAFES];
			static int iClientSync_Max[MAXPLAYERS_BHOP][NUM_STRAFES];
			
			// Thing to remember: angle is a number between 180 and -180.
			// So we give 20 degree cap where this can be registered as strafing to the left.
			static int iCurStrafe;
			iCurStrafe = (
				!( flClientPrevYaw[client] < -170.0 && angles[1] > 170.0 ) // Make sure we didn't do -180 -> 180 because that would mean left when it's actually right.
				&& ( angles[1] > flClientPrevYaw[client] // Is our current yaw bigger than last time? Strafing to the left.
				|| ( flClientPrevYaw[client] > 170.0 && angles[1] < -170.0 ) ) ) // If that didn't pass, there might be a chance of 180 -> -180.
				? STRAFE_LEFT : STRAFE_RIGHT;
			
			
			if ( iCurStrafe != iClientLastStrafe[client] )
			// Start of a new strafe.
			{
				// Calc previous strafe's sync. This will then be shown to the player.
				if ( iClientLastStrafe[client] != STRAFE_INVALID )
				{
					g_flClientSync[client][ iClientLastStrafe[client] ] = ( g_flClientSync[client][ iClientLastStrafe[client] ] + iClientSync[client][ iClientLastStrafe[client] ] / float( iClientSync_Max[client][ iClientLastStrafe[client] ] ) ) / 2;
				}
				
				// Reset the new strafe's variables.
				iClientSync[client][iCurStrafe] = 1;
				iClientSync_Max[client][iCurStrafe] = 1;
				
				iClientLastStrafe[client] = iCurStrafe;
				g_nClientStrafes[client]++;
			}
			
			
			static float flCurVel;
			flCurVel = GetEntitySpeedSquared( client );
			
			// We're moving our mouse, but are we gaining speed?
			if ( flCurVel > flClientLastVel[client] )
				iClientSync[client][iCurStrafe]++;
			
			iClientSync_Max[client][iCurStrafe]++;
			
			
			flClientLastVel[client] = flCurVel;
		}
		
		flClientPrevYaw[client] = angles[1];

		return Plugin_Continue;
	}
	
	
#if defined RECORD
	//////////////
	// PLAYBACK //
	//////////////
	if ( !g_bPlayback || g_hRec[ g_iClientRun[client] ][ g_iClientStyle[client] ][ g_iClientMode[client] ] == null ) return Plugin_Handled;
	
	
	if ( g_bClientMimicing[client] )
	{
		g_hRec[ g_iClientRun[client] ][ g_iClientStyle[client] ][ g_iClientMode[client] ].GetArray( g_nClientTick[client], iFrame, view_as<int>( RecData ) );
		
		// Do buttons and weapons.
		buttons = ( iFrame[FRAME_FLAGS] & FRAMEFLAG_CROUCH ) ? IN_DUCK : 0;
		
		/*static int wep;
		if ( iFrame[FRAME_FLAGS] & FRAMEFLAG_PRIMARY )
		{
			if ( (wep = GetPlayerWeaponSlot( client, SLOT_PRIMARY )) > 0 )
			{
				weapon = wep;
			}
		}
		else if ( iFrame[FRAME_FLAGS] & FRAMEFLAG_SECONDARY )
		{
			if ( (wep = GetPlayerWeaponSlot( client, SLOT_SECONDARY )) > 0 )
			{
				weapon = wep;
			}
		}
		else if ( iFrame[FRAME_FLAGS] & FRAMEFLAG_MELEE )
		{
			if ( (wep = GetPlayerWeaponSlot( client, SLOT_MELEE )) > 0 )
			{
				weapon = wep;
			}
		}
		else if ( iFrame[FRAME_FLAGS] & FRAMEFLAG_ATTACK )
		{
			buttons |= IN_ATTACK;
		}
		else if ( iFrame[FRAME_FLAGS] & FRAMEFLAG_ATTACK2 )
		{
			buttons |= IN_ATTACK2;
		}*/
		
		vel = g_vecNull;
		ArrayCopy( iFrame[FRAME_ANG], angles, 2 );
		
		
		ArrayCopy( iFrame[FRAME_POS], vecPos, 3 );
		
		static float vecPrevPos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecPrevPos );
		
		if ( GetVectorDistance( vecPos, vecPrevPos, true ) > MIN_TICK_DIST_SQ )
		{
			TeleportEntity( client, vecPos, angles, NULL_VECTOR );
		}
		else
		{
			// Make the velocity!
			static float vecDirVel[3];
			vecDirVel[0] = vecPos[0] - vecPrevPos[0];
			vecDirVel[1] = vecPos[1] - vecPrevPos[1];
			vecDirVel[2] = vecPos[2] - vecPrevPos[2];
			
			ScaleVector( vecDirVel, g_flTickRate ); // Based on tickrate (?)
			
			TeleportEntity( client, NULL_VECTOR, angles, vecDirVel );
			
			// If server ops want more responsive but choppy movement, here it is.
			if ( !g_bSmoothPlayback )
				SetEntPropVector( client, Prop_Send, "m_vecOrigin", vecPos );
		}
		
		// Are we done with our recording?
		if ( ++g_nClientTick[client] >= g_iRecTickMax[ g_iClientRun[client] ][ g_iClientStyle[client] ][ g_iClientMode[client] ] )
		{
			g_bClientMimicing[client] = false;
			
			CreateTimer( 2.0, Timer_Rec_Restart, client, TIMER_FLAG_NO_MAPCHANGE );
		}
		
		return Plugin_Changed;
	}
	
	// Not calling this here doesn't work for some reason.
	if ( g_nClientTick[client] == 0 )
	{
		g_hRec[ g_iClientRun[client] ][ g_iClientStyle[client] ][ g_iClientMode[client] ].GetArray( 0, iFrame, view_as<int>( RecData ) );
		
		buttons = ( iFrame[FRAME_FLAGS] & FRAMEFLAG_CROUCH ) ? IN_DUCK : 0;
		
		ArrayCopy( iFrame[FRAME_POS], vecPos, 3 );
		ArrayCopy( iFrame[FRAME_ANG], angles, 2 );
		
		TeleportEntity( client, vecPos, angles, g_vecNull );
		
		return Plugin_Changed;
	}
#endif
	
	// Freezes bots when they don't need to do anything. I.e. at the start/end of the run.
	return Plugin_Handled;
}