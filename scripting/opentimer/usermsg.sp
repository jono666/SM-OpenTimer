static char g_szBuffer[256];

stock void PrintColorChat( int target, int author, const char[] szMsg, any...)
{
	VFormat( g_szBuffer, sizeof( g_szBuffer ), szMsg, 4 );
	
	SendColorMessage( target, author, g_szBuffer );
}

stock void PrintColorChatAll( int author, bool bAllowHide, const char[] szMsg, any...)
{
	VFormat( g_szBuffer, sizeof( g_szBuffer ), szMsg, 4 );
	
#if defined CHAT
	if ( bAllowHide )
	{
		for ( int client = 1; client <= MaxClients; client++ )
			if ( IsClientInGame( client ) && !( g_fClientHideFlags[client] & HIDEHUD_CHAT ) )
			{
				SendColorMessage( client, author, g_szBuffer );
			}
		return;
	}
#endif
	
	for ( int client = 1; client <= MaxClients; client++ )
		if ( IsClientInGame( client ) )
		{
			SendColorMessage( client, author, g_szBuffer );
		}
}

stock void SendColorMessage( int target, int author, const char szMsg[256] )
{
	// If we don't use the reliable channel, sometimes clients won't receive the message (?).
	// Happens more than you'd normally think.
	Handle hMsg = StartMessageOne( "SayText2", target );
	
	if ( hMsg != null )
	{
#if defined CSGO
		PbSetInt( hMsg, "ent_idx", author );
		PbSetBool( hMsg, "chat", true );
		
		PbSetString( hMsg, "msg_name", szMsg );
		PbAddString( hMsg, "params", "" );
		PbAddString( hMsg, "params", "" );
		PbAddString( hMsg, "params", "" );
		PbAddString( hMsg, "params", "" );
		
		PbSetBool( hMsg, "textallchat", false );
#else
		BfWriteByte( hMsg, author );
		
		// false for no console print. We do this manually because it would display the hex codes in the console.
		BfWriteByte( hMsg, false );
		
		BfWriteString( hMsg, szMsg );
#endif

		
		EndMessage();
	}
}

stock void ShowKeyHintText( int client, int target )
{
	/*static clients[2];
	
	clients[0] = client;
	Handle hMsg = StartMessageEx( g_UsrMsg_HudMsg, clients, 1 );*/
	
	Handle hMsg = StartMessageOne( "KeyHintText", client );
	
	if ( hMsg != null )
	{
		static char szTime[TIME_SIZE_DEF];
		static char szText[120];
		
		static int run;
		static int style;
		static int mode;
		run = g_iClientRun[target];
		style = g_iClientStyle[target];
		mode = g_iClientMode[target];
		
		if ( IsFakeClient( target ) ) 
		{
#if defined RECORD
			FormatSeconds( g_flMapBestTime[run][style][mode], szTime );
			
			FormatEx( szText, sizeof( szText ), "Name: %s\nTime: %s", g_szRecName[run][style][mode], szTime );
#else
			FormatEx( szText, sizeof( szText ), "I am a bot! :)" );
#endif
		}
		else
		{
			if ( g_flClientBestTime[target][run][style][mode] != TIME_INVALID )
			{
				FormatSeconds( g_flClientBestTime[target][run][style][mode], szTime );
			}
			else FormatEx( szTime, sizeof( szTime ), "N/A" );
			
			
			static char szStylePostFix[STYLEPOSTFIX_LENGTH];
			GetStylePostfix( g_iClientMode[target], szStylePostFix );
			
			if ( g_iClientState[target] != STATE_START )
			{
				if ( style == STYLE_W || style == STYLE_A_D )
				{
					FormatEx( szText, sizeof( szText ), "Jumps: %i\n \nStyle: %s%s\nPB: %s\n%s",
						g_nClientJumps[target],
						g_szStyleName[NAME_LONG][style], // Show our style.
						szStylePostFix, // Don't forget postfix
						szTime,
						( g_bClientPractising[target] ? "(Practice Mode)" : "" ) ); // Have a practice mode warning for players!
				}
				else
				{
					// "Strafes: XXXXXCL Sync: 100.0CL Sync: 100.0CR Sync: 100.0CJumps: XXXXC CStyle: Real HSWCPB: 00:00:00.00C(Practice Mode)"
					FormatEx( szText, sizeof( szText ), "Strafes: %i\nL Sync: %3.1f\nR Sync: %3.1f\nJumps: %i\n \nStyle: %s%s\nPB: %s\n%s",
						g_nClientStrafes[target],
						g_flClientSync[target][STRAFE_LEFT] * 100.0, // Left Sync
						g_flClientSync[target][STRAFE_RIGHT] * 100.0, // Right Sync
						g_nClientJumps[target],
						g_szStyleName[NAME_LONG][style],
						szStylePostFix,
						szTime,
						( g_bClientPractising[target] ? "(Practice Mode)" : "" ) );
				}
			}
			else
			{
				FormatEx( szText, sizeof( szText ), "Style: %s%s\nPB: %s\n%s",
					g_szStyleName[NAME_LONG][style],
					szStylePostFix,
					szTime,
					( g_bClientPractising[target] ? "(Practice Mode)" : "" ) );
			}
		}
		
		/*static const float vec[2] = { 0.8, 0.05 };
		static const int color[4] = { 255, 255, 255, 255 };
		
		PbSetInt( hMsg, "channel", 4 );
		
		PbSetVector2D( hMsg, "pos", vec );
		PbSetColor( hMsg, "clr1", color );
		PbSetColor( hMsg, "clr2", color );
		PbSetInt( hMsg, "effect", 0 );
		
		PbSetFloat( hMsg, "fade_in_time", 0.0 );
		PbSetFloat( hMsg, "fade_out_time", 0.0 );
		PbSetFloat( hMsg, "hold_time", 0.1 );
		PbSetFloat( hMsg, "fx_time", 0.0 );
		
		PbSetString( hMsg, "text", szText );*/
		
		BfWriteByte( hMsg, 1 );
		BfWriteString( hMsg, szText );
		
		EndMessage();
	}
}