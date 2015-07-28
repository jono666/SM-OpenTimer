// Query handles are closed automatically.

public void Threaded_PrintRecords( Handle hOwner, Handle hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( !(client = GetClientOfUserId( hData.Get( 0, 0 ) )) ) return;
	
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."An error occured when trying to print times to client. Error: %s", g_szError );
	
		PRINTCHAT( client, client, CHAT_PREFIX..."Sorry, something went wrong." );
		return;
	}
	
	
	bool bInConsole = hData.Get( 0, 1 );
	int run = hData.Get( 0, 2 );
	
	Menu mMenu;
	
	if ( bInConsole )
	{
		PrintToConsole( client, "--------------------" );
		PrintToConsole( client, ">> !printrecords <style/run> for specific styles and runs. (\"normal\", \"sideways\", \"w\", \"b1/b2\", etc.)" );
		PrintToConsole( client, ">> Records (%s) (Max. %i):", g_szRunName[NAME_LONG][run], RECORDS_PRINT_MAX );
	}
	else
	{
		mMenu = new Menu( Handler_Empty );
		mMenu.SetTitle( "Records (%s)\n ", g_szRunName[NAME_LONG][run] );
	}
	
	int num;
	
	if ( SQL_GetRowCount( hQuery ) )
	{
		int			jumps;
		int			strafes;
		int			style;
		int			mode;
		static char	szSteam[MAX_ID_LENGTH];
		static char	szName[MAX_NAME_LENGTH];
		static char	szFormTime[TIME_SIZE_DEF];
		char		szStyleFix[STYLEPOSTFIX_LENGTH];
		
		char szItem[64];
		
		while ( SQL_FetchRow( hQuery ) )
		{
			style = SQL_FetchInt( hQuery, 0 );
			mode = SQL_FetchInt( hQuery, 1 );
			
			FormatSeconds( SQL_FetchFloat( hQuery, 2 ), szFormTime );
			
			SQL_FetchString( hQuery, 3, szName, sizeof( szName ) );
			
			
			if ( bInConsole )
			{
				GetStylePostfix( mode, szStyleFix );
				
				SQL_FetchString( hQuery, 4, szSteam, sizeof( szSteam ) );
			
				jumps = SQL_FetchInt( hQuery, 5 );
				strafes = SQL_FetchInt( hQuery, 6 );
				
				PrintToConsole( client, "%i. %s - %s - %s - %s%s - %i jmps - %i strfs",
					num + 1,
					szName,
					szSteam,
					szFormTime,
					g_szStyleName[NAME_LONG][style],
					szStyleFix,
					jumps,
					strafes );
			}
			else
			{
				GetStylePostfix( mode, szStyleFix, true );
				// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - XX:XX:XX [XXXX XXXXXX]
				FormatEx( szItem, sizeof( szItem ), "%s - %s [%s%s]", szName, szFormTime, g_szStyleName[NAME_SHORT][style], szStyleFix );
				mMenu.AddItem( "", szItem, ITEMDRAW_DISABLED );
			}
			
			num++;
		}
	}
	else
	{
		#define NO_RECS "No one has beaten the map yet... :("
		
		if ( bInConsole )
			PrintToConsole( client, NO_RECS );
		else
			mMenu.AddItem( "", NO_RECS, ITEMDRAW_DISABLED );
	}

	if ( bInConsole )
	{
		PRINTCHATV( client, client, CHAT_PREFIX..."Printed ("...CLR_TEAM..."%i"...CLR_TEXT...") records in your console.", num );
	}
	else
	{
		mMenu.Display( client, MENU_TIME_FOREVER );
	}
}

public void Threaded_Admin_Records_DeleteMenu( Handle hOwner, Handle hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( !(client = GetClientOfUserId( hData.Get( 0, 0 ) )) ) return;
	
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."An error occured when trying to print records to an admin. Error: %s", g_szError );
		
		PRINTCHAT( client, client, CHAT_PREFIX..."Sorry, something went wrong." );
		return;
	}
	
	
	int		run = hData.Get( 0, 1 );
	int		style;
	int		mode;
	int		id;
	char	szName[MAX_NAME_LENGTH];
	char	szFormTime[TIME_SIZE_DEF];
	char	szStyleFix[STYLEPOSTFIX_LENGTH];
	char	szItem[64];
	char	szId[32];
	
	
	
	Menu mMenu = new Menu( Handler_RecordDelete );
	mMenu.SetTitle( "Record Deletion (%s)\n ", g_szRunName[NAME_LONG][run] );
	
	if ( SQL_GetRowCount( hQuery ) )
	{
		while ( SQL_FetchRow( hQuery ) )
		{
			style = SQL_FetchInt( hQuery, 0 );
			mode = SQL_FetchInt( hQuery, 1 );
			id = SQL_FetchInt( hQuery, 2 );
			FormatSeconds( SQL_FetchFloat( hQuery, 3 ), szFormTime );
			SQL_FetchString( hQuery, 4, szName, sizeof( szName ) );
			
			FormatEx( szId, sizeof( szId ), "0_%i_%i_%i_%i", run, style, mode, id ); // Used to identify records.
			
			GetStylePostfix( mode, szStyleFix, true );
			FormatEx( szItem, sizeof( szItem ), "%s - %s [%s%s]", szName, szFormTime, g_szStyleName[NAME_SHORT][style], szStyleFix );
			
			mMenu.AddItem( szId, szItem );
		}
	}
	else
	{
		FormatEx( szItem, sizeof( szItem ), "No one has beaten %s yet... :(", g_szRunName[NAME_LONG][run] );
		mMenu.AddItem( "", szItem, ITEMDRAW_DISABLED );
	}
	
	mMenu.Display( client, MENU_TIME_FOREVER );
}

public void Threaded_Admin_CPRecords_DeleteMenu( Handle hOwner, Handle hQuery, const char[] szError, ArrayList hData )
{
	int client;
	if ( !(client = GetClientOfUserId( hData.Get( 0, 0 ) )) ) return;
	
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."An error occured when trying to print checkpoint records to an admin. Error: %s", g_szError );
		
		PRINTCHAT( client, client, CHAT_PREFIX..."Sorry, something went wrong." );
		return;
	}
	
	
	int		run = hData.Get( 0, 1 );
	int		style;
	int		mode;
	int		id;
	float	flTime;
	char	szFormTime[TIME_SIZE_DEF];
	char	szStyleFix[STYLEPOSTFIX_LENGTH];
	char	szItem[64];
	char	szId[32];
	
	
	
	Menu mMenu = new Menu( Handler_RecordDelete );
	mMenu.SetTitle( "Checkpoint Record Deletion (%s)\n ", g_szRunName[NAME_LONG][run] );
	
	if ( SQL_GetRowCount( hQuery ) )
	{
		while ( SQL_FetchRow( hQuery ) )
		{
			flTime = SQL_FetchFloat( hQuery, 3 );
			
			if ( flTime <= TIME_INVALID ) continue;
			
			
			id = SQL_FetchInt( hQuery, 0 );
			style = SQL_FetchInt( hQuery, 1 );
			mode = SQL_FetchInt( hQuery, 2 );
			FormatSeconds( flTime, szFormTime );
			
			FormatEx( szId, sizeof( szId ), "1_%i_%i_%i_%i", run, style, mode, id ); // Used to identify records.
			
			GetStylePostfix( mode, szStyleFix, true );
			FormatEx( szItem, sizeof( szItem ), "#%i - %s [%s%s]", id + 1, szFormTime, g_szStyleName[NAME_SHORT][style], szStyleFix );
			
			mMenu.AddItem( szId, szItem );
		}
	}
	else
	{
		FormatEx( szItem, sizeof( szItem ), "No checkpoint records found!" );
		mMenu.AddItem( "", szItem, ITEMDRAW_DISABLED );
	}
	
	mMenu.Display( client, MENU_TIME_FOREVER );
}

public void Threaded_RetrieveClientData( Handle hOwner, Handle hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."Couldn't retrieve player data! Error: %s", g_szError );
		
		return;
	}
	
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	char szSteam[MAX_ID_LENGTH];
	
	if ( !GetClientAuthId( client, AuthId_Engine, szSteam, sizeof( szSteam ) ) )
	{
		LogError( CONSOLE_PREFIX..."There was an error at trying to retrieve player's \"%N\" Steam Id! Cannot retrieve data.", client );
		return;
	}
	
	
	static char szQuery[162];
	
	int num;
	if ( !(num = SQL_GetRowCount( hQuery )) )
	{
		FormatEx( szQuery, sizeof( szQuery ), "INSERT INTO "...TABLE_PLYDATA..." (steamid) VALUES ('%s')", szSteam );
		
		SQL_TQuery( g_hDatabase, Threaded_NewID, szQuery, GetClientUserId( client ), DBPrio_Normal );
		
		return;
	}
	
	
	if ( num > 1 )
	{
		// Should never happen.
		LogError( CONSOLE_PREFIX..."Found multiple records with the same Steam Id!!" );
	}
	
	
	
	if ( SQL_GetRowCount( hQuery ) )
	{
		g_iClientId[client] = SQL_FetchInt( hQuery, 0 );
		
		g_iClientFOV[client] = SQL_FetchInt( hQuery, 1 );
		
		g_fClientHideFlags[client] = SQL_FetchInt( hQuery, 2 );
		
		// If spectating.
		if ( g_fClientHideFlags[client] & HIDEHUD_VM )
			SetEntProp( client, Prop_Send, "m_bDrawViewmodel", 0 );
		
		if ( g_flClientStartTime[client] == TIME_INVALID )
		{
			int style = SQL_FetchInt( hQuery, 3 );
			
			g_iClientStyle[client] = ( IsAllowedStyle( style ) ) ? style : STYLE_NORMAL;
			
			
			int mode = SQL_FetchInt( hQuery, 4 );
			
			g_iClientMode[client] = ( IsAllowedMode( mode ) ) ? mode : FindAllowedMode();
		}
		
		g_iClientFinishes[client] = SQL_FetchInt( hQuery, 5 );
	}
	
	// Then we get the times.
	FormatEx( szQuery, sizeof( szQuery ), "SELECT run, style, mode, time FROM "...TABLE_RECORDS..." WHERE map = '%s' AND uid = %i ORDER BY run", g_szCurrentMap, g_iClientId[client] );
	SQL_TQuery( g_hDatabase, Threaded_RetrieveClientTimes, szQuery, GetClientUserId( client ), DBPrio_Normal );
}

public void Threaded_RetrieveClientTimes( Handle hOwner, Handle hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."Couldn't retrieve player records! Error: %s", g_szError );
		
		return;
	}
	
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	
	int style;
	int run;
	int mode;
	while ( SQL_FetchRow( hQuery ) )
	{
		run = SQL_FetchInt( hQuery, 0 );
		
		style = SQL_FetchInt( hQuery, 1 );
		
		mode = SQL_FetchInt( hQuery, 2 );
	
		g_flClientBestTime[client][run][style][mode] = SQL_FetchFloat( hQuery, 3 );
	}
	
	UpdateScoreboard( client );
	
	DB_DisplayClientRank( client, RUN_MAIN, g_iClientStyle[client], g_iClientMode[client] );
}

public void Threaded_DisplayRank( Handle hOwner, Handle hQuery, const char[] szError, ArrayList hData )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."Couldn't retrieve ranks! Error: %s", g_szError );
		
		return;
	}
	
	int client;
	if ( !(client = GetClientOfUserId( hData.Get( 0, 0 ) )) ) return;
	
	int num;
	// Nobody has beaten the map!
	// For some odd reason...
	if ( !(num = SQL_GetRowCount( hQuery )) ) return;
	
	
	static char szQuery[162];
	
	int run = hData.Get( 0, 1 );
	int style = hData.Get( 0, 2 );
	int mode = hData.Get( 0, 3 );
	
	FormatEx( szQuery, sizeof( szQuery ), "SELECT run FROM "...TABLE_RECORDS..." WHERE map = '%s' AND run = %i AND style = %i AND mode = %i AND time < %.3f",
		g_szCurrentMap,
		run,
		style,
		mode,
		g_flClientBestTime[client][run][style][mode] );
	
	
	int iData[5];
	iData[0] = GetClientUserId( client );
	iData[1] = run;
	iData[2] = style;
	iData[3] = mode;
	iData[4] = num;
	
	ArrayList hData_ = new ArrayList( sizeof( iData ) );
	hData_.PushArray( iData, sizeof( iData ) );
	
	
	SQL_TQuery( g_hDatabase, Threaded_DisplayRank_End, szQuery, hData_, DBPrio_Low );
}

public void Threaded_DisplayRank_End( Handle hOwner, Handle hQuery, const char[] szError, ArrayList hData )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."Couldn't retrieve player's rank! Error: %s", g_szError );
		
		return;
	}
	
	int client;
	if ( !(client = GetClientOfUserId( hData.Get( 0, 0 ) )) ) return;
	
	
	int rank = SQL_GetRowCount( hQuery );
	
	
	char szStyleFix[STYLEPOSTFIX_LENGTH];
	GetStylePostfix( hData.Get( 0, 3 ), szStyleFix, true );
	
	// "XXX is ranked X/X in [XXXX XXXX]"
	PRINTCHATALLV( client, true, CHAT_PREFIX...""...CLR_TEAM..."%N"...CLR_TEXT..." is ranked "...CLR_CUSTOM3..."%i"...CLR_TEXT..."/"...CLR_CUSTOM3..."%i"...CLR_TEXT..." in "...CLR_CUSTOM2..."%s"...CLR_TEXT..." ["...CLR_CUSTOM2..."%s%s"...CLR_TEXT..."]", client, ++rank, hData.Get( 0, 4 ), g_szRunName[NAME_LONG][hData.Get( 0, 1 )], g_szStyleName[NAME_SHORT][ hData.Get( 0, 2 ) ], szStyleFix );
}

public void Threaded_NewID( Handle hOwner, Handle hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."Couldn't create new player data record! Error: %s", g_szError );
		
		return;
	}
	
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	
	char szSteam[MAX_ID_LENGTH];
	
	if ( !GetClientAuthId( client, AuthId_Engine, szSteam, sizeof( szSteam ) ) )
	{
		LogError( CONSOLE_PREFIX..."There was an error at trying to retrieve player's \"%N\" Steam Id! Cannot retrieve id.", client );
		return;
	}
	
	
	static char szQuery[92];
	FormatEx( szQuery, sizeof( szQuery ), "SELECT uid FROM "...TABLE_PLYDATA..." WHERE steamid = '%s'", szSteam );
	
	SQL_TQuery( g_hDatabase, Threaded_NewID_Final, szQuery, GetClientUserId( client ), DBPrio_Low );
}

public void Threaded_NewID_Final( Handle hOwner, Handle hQuery, const char[] szError, any client )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."Couldn't receive new id for player! Error: %s", g_szError );
		
		return;
	}
	
	if ( !(client = GetClientOfUserId( client )) ) return;
	
	
	if ( SQL_GetRowCount( hQuery ) )
	{
		g_iClientId[client] = SQL_FetchInt( hQuery, 0 );
	}
	else
	{
		LogError( CONSOLE_PREFIX..."Couldn't receive new id for player!" );
	}
}

public void Threaded_Init_Zones( Handle hOwner, Handle hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		SetFailState( CONSOLE_PREFIX..."Unable to retrieve map zones! Error: %s", g_szError );
		
		return;
	}
	
	if ( !SQL_GetRowCount( hQuery ) ) return;
	
	
	float vecMins[3];
	float vecMaxs[3];
	int zone;
	int iData[ZONE_SIZE];
	
	while ( SQL_FetchRow( hQuery ) )
	{
		zone = SQL_FetchInt( hQuery, 0 );
		
		vecMins[0] = SQL_FetchFloat( hQuery, 1 );
		vecMins[1] = SQL_FetchFloat( hQuery, 2 );
		vecMins[2] = SQL_FetchFloat( hQuery, 3 );
		
		vecMaxs[0] = SQL_FetchFloat( hQuery, 4 );
		vecMaxs[1] = SQL_FetchFloat( hQuery, 5 );
		vecMaxs[2] = SQL_FetchFloat( hQuery, 6 );
		
		if ( zone >= NUM_REALZONES )
		{
			iData[ZONE_TYPE] = zone;
			iData[ZONE_ID] = SQL_FetchInt( hQuery, 7 );
			iData[ZONE_FLAGS] = SQL_FetchInt( hQuery, 8 );
			
			ArrayCopy( vecMins, iData[ZONE_MINS], 3 );
			ArrayCopy( vecMaxs, iData[ZONE_MAXS], 3 );
			
			g_hZones.PushArray( iData, view_as<int>( ZoneData ) );
		}
		else
		{
			iData[ZONE_ID] = 0;
			
			g_bZoneExists[zone] = true;
			
			ArrayCopy( vecMins, g_vecZoneMins[zone], 3 );
			ArrayCopy( vecMaxs, g_vecZoneMaxs[zone], 3 );
		}
		
		CreateZoneBeams( zone, vecMins, vecMaxs, iData[ZONE_ID] );
	}
	
	
	if ( !g_bZoneExists[ZONE_START] || !g_bZoneExists[ZONE_END] )
	{
		PrintToServer( CONSOLE_PREFIX..."Map is lacking zones..." );
		g_bIsLoaded[RUN_MAIN] = false;
	}
	else g_bIsLoaded[RUN_MAIN] = true;
	
	
	g_bIsLoaded[RUN_BONUS1] = ( g_bZoneExists[ZONE_BONUS_1_START] && g_bZoneExists[ZONE_BONUS_1_END] );
	
	g_bIsLoaded[RUN_BONUS2] = ( g_bZoneExists[ZONE_BONUS_2_START] && g_bZoneExists[ZONE_BONUS_2_END] );
	
	
	if ( g_bIsLoaded[RUN_MAIN] || g_bIsLoaded[RUN_BONUS1] || g_bIsLoaded[RUN_BONUS2] )
	{
		DoMapStuff();
		
		char szQuery[256];
		
		// Get map data for records and votes!
#if defined RECORD
		FormatEx( szQuery, sizeof( szQuery ), "SELECT run, style, mode, time, uid, name FROM "...TABLE_RECORDS..." NATURAL JOIN "...TABLE_PLYDATA..." WHERE map = '%s' GROUP BY run, style, mode ORDER BY MIN(time)", g_szCurrentMap );
#else
		FormatEx( szQuery, sizeof( szQuery ), "SELECT run, style, mode, time FROM "...TABLE_RECORDS..." WHERE map = '%s' GROUP BY run, style ORDER BY MIN(time)", g_szCurrentMap );
#endif
		
		SQL_TQuery( g_hDatabase, Threaded_Init_Records, szQuery, _, DBPrio_High );
		
		
		
		FormatEx( szQuery, sizeof( szQuery ), "SELECT run, id, min0, min1, min2, max0, max1, max2 FROM "...TABLE_CP..." WHERE map = '%s'", g_szCurrentMap );
		// SELECT run, id, min0, min1, min2, max0, max1, max2, rec_time FROM mapcprecs NATURAL JOIN mapcps WHERE map = 'bhop_gottagofast' ORDER BY run, id
		SQL_TQuery( g_hDatabase, Threaded_Init_CPs, szQuery, _, DBPrio_High );
	}
}

public void Threaded_Init_Records( Handle hOwner, Handle hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		SetFailState( CONSOLE_PREFIX..."Unable to retrieve map records! Error: %s", g_szError );
		
		return;
	}
	
	if ( !SQL_GetRowCount( hQuery ) ) return;
	
	
	// More readible this way.
	int		iStyle;
	int		iRun;
	int		iMode;
#if defined RECORD
	bool	bNormalOnly = GetConVarBool( g_ConVar_Bonus_NormalOnlyRec );
	int		id;
	int		num_recs;
	
	int maxbots = GetConVarInt( g_ConVar_MaxBots );
#endif

	while ( SQL_FetchRow( hQuery ) )
	{
		iRun = SQL_FetchInt( hQuery, 0 );
		
		if ( !g_bIsLoaded[iRun] ) continue;
		
		iStyle = SQL_FetchInt( hQuery, 1 );
		iMode = SQL_FetchInt( hQuery, 2 );
		
		g_flMapBestTime[iRun][iStyle][iMode] = SQL_FetchFloat( hQuery, 3 );
		
#if defined RECORD
		// Don't attempt to read any more records.
		if ( num_recs >= maxbots ) continue;
		
		// Load records from disk.
		// Assigning the records to bots are done in OnClientPutInServer()
		if ( bNormalOnly && iRun != RUN_MAIN && iStyle != STYLE_NORMAL && iMode != MODE_AUTO ) continue;
		
		
		id = SQL_FetchInt( hQuery, 4 );
		
		if ( LoadRecording( g_hRec[iRun][iStyle][iMode], g_iRecTickMax[iRun][iStyle][iMode], id, iRun, iStyle, iMode ) )
		{
			SQL_FetchString( hQuery, 5, g_szRecName[iRun][iStyle][iMode], sizeof( g_szRecName[][][] ) );
			g_iRecMaxLength[iRun][iStyle][iMode] = RoundFloat( g_iRecTickMax[iRun][iStyle][iMode] * 1.2 );
			num_recs++;
		}
#endif
	}
	
#if defined RECORD
	// Spawn record bots.
	SetConVarInt( g_ConVar_BotQuota, num_recs );
	
	if ( num_recs )
		PrintToServer( CONSOLE_PREFIX..."Spawning %i record bots...", num_recs );
#endif
	
	DoMapStuff();
}

public void Threaded_Init_CPs( Handle hOwner, Handle hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		SetFailState( CONSOLE_PREFIX..."Unable to retrieve map checkpoints! Error: %s", g_szError );
		
		return;
	}
	
	if ( !SQL_GetRowCount( hQuery ) ) return;
	
	
	int iData[CP_SIZE];
	float vecMins[3];
	float vecMaxs[3];
	
	while ( SQL_FetchRow( hQuery ) )
	{
		iData[CP_RUN] = SQL_FetchInt( hQuery, 0 );
		
		if ( !g_bIsLoaded[ iData[CP_RUN] ] ) continue;
		
		
		iData[CP_ID] = SQL_FetchInt( hQuery, 1 );
		
		vecMins[0] = SQL_FetchFloat( hQuery, 2 );
		vecMins[1] = SQL_FetchFloat( hQuery, 3 );
		vecMins[2] = SQL_FetchFloat( hQuery, 4 );
		
		vecMaxs[0] = SQL_FetchFloat( hQuery, 5 );
		vecMaxs[1] = SQL_FetchFloat( hQuery, 6 );
		vecMaxs[2] = SQL_FetchFloat( hQuery, 7 );
		
		ArrayCopy( vecMins, iData[CP_MINS], 3 );
		ArrayCopy( vecMaxs, iData[CP_MAXS], 3 );
		
		g_hCPs.PushArray( iData, view_as<int>( CPData ) );
		
		CreateZoneBeams( ZONE_CP, vecMins, vecMaxs, iData[CP_ID] );
	}
	
	// GET CHECKPOINT TIMES
	char szQuery[162];
	FormatEx( szQuery, sizeof( szQuery ), "SELECT run, id, style, mode, time FROM "...TABLE_CP_RECORDS..." WHERE map = '%s'", g_szCurrentMap );
	
	SQL_TQuery( g_hDatabase, Threaded_Init_CPTimes, szQuery, _, DBPrio_High );
}

public void Threaded_Init_CPTimes( Handle hOwner, Handle hQuery, const char[] szError, any data )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		SetFailState( CONSOLE_PREFIX..."Unable to retrieve map checkpoint times! Error: %s", g_szError );
		
		return;
	}
	
	if ( !SQL_GetRowCount( hQuery ) ) return;
	
	
	int id;
	int run;
	int index;
	
	while ( SQL_FetchRow( hQuery ) )
	{
		run = SQL_FetchInt( hQuery, 0 );
		
		if ( !g_bIsLoaded[run] ) continue;
		
		
		id = SQL_FetchInt( hQuery, 1 );
		
		index = FindCPIndex( run, id );
		
		if ( index != -1 )
		{
			int style = SQL_FetchInt( hQuery, 2 );
			int mode = SQL_FetchInt( hQuery, 3 );
			float flTime = SQL_FetchFloat( hQuery, 4 );
			
			SetCPTime( index, style, mode, flTime );
		}
	}
}

public void Threaded_DeleteRecord( Handle hOwner, Handle hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."SQL Error: %s", g_szError );
		
		if ( client && IsClientInGame( client ) )
			PRINTCHAT( client, client, CHAT_PREFIX..."An error occured with SQL query! Couldn't delete record!" );
		
		return;
	}
	
	if ( client && IsClientInGame( client ) )
		PRINTCHAT( client, client, CHAT_PREFIX..."Record was succesfully deleted!" );
}

// No special callback is needed.
public void Threaded_Empty( Handle hOwner, Handle hQuery, const char[] szError, int client )
{
	if ( hQuery == null )
	{
		SQL_GetError( g_hDatabase, g_szError, sizeof( g_szError ) );
		LogError( CONSOLE_PREFIX..."SQL Error: %s", g_szError );
		
		if ( client && IsClientInGame( client ) )
		{
			PRINTCHAT( client, client, CHAT_PREFIX..."An error occured with SQL query! Please read the server error log for more information." );
		}
	}
}