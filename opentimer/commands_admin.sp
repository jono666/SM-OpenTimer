public Action Command_Admin_ZoneEnd( int client, int args )
{
	if ( client == INVALID_INDEX ) return Plugin_Handled;
	
	if ( g_iBuilderIndex != client )
	{
		if ( g_iBuilderIndex == 0 )
		{
			PrintColorChat( client, client, "%s You haven't even started a zone! (\x03!startzone%s)", CHAT_PREFIX, COLOR_TEXT );
			return Plugin_Handled;
		}
		
		if ( !IsClientInGame( g_iBuilderIndex ) )
		{
			g_iBuilderIndex = 0;
			
			PrintColorChat( client, client, "%s You haven't even started a zone! (\x03!startzone%s)", CHAT_PREFIX, COLOR_TEXT );
			
			return Plugin_Handled;
		}
		
		
		PrintColorChat( client, client, "%s Somebody else is building the zone!", CHAT_PREFIX );
		return Plugin_Handled;
	}
	
	if ( g_iBuilderZone < 0 )
	{
		PrintColorChat( client, client, "%s You haven't even started a zone! (\x03!startzone%s)", CHAT_PREFIX, COLOR_TEXT );
		return Plugin_Handled;
	}
	
	static float vecClientPos[3];
	GetClientAbsOrigin( client, vecClientPos );
	
	g_vecBoundsMax[g_iBuilderZone][0] = vecClientPos[0] - ( RoundFloat( vecClientPos[0] ) % g_iBuilderGridSize );
	g_vecBoundsMax[g_iBuilderZone][1] = vecClientPos[1] - ( RoundFloat( vecClientPos[1] ) % g_iBuilderGridSize );
	
	
	float flDif = vecClientPos[2] - g_vecBoundsMin[g_iBuilderZone][2];
	
	// If player built the mins on the ground and just walks to the other side, we will then automatically make it higher.
	g_vecBoundsMax[g_iBuilderZone][2] = ( flDif <= 4.0 && flDif >= -4.0 ) ? ( vecClientPos[2] + BOUNDS_DEF_HEIGHT ) : float( RoundFloat( vecClientPos[2] ) );
	
	
	
	// This was used for precise min bounds that would always be on the ground, so our origin cannot be under the mins.
	// E.g player is standing on ground but our mins are higher than player's origin meaning that the player is outside of the bounds.
	// It is unneccesary now because our bounds are rounded. The player will always be 0.1 - 2.0 units higher.
	
	/*
	static const float angDown[] = { 90.0, 0.0, 0.0 };
	
	TR_TraceRay( g_vecBoundsMin[g_iBuilderZone], angDown, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite );
	
	if ( TR_DidHit( null ) )
		if ( TR_GetEntityIndex( null ) != client )
			TR_GetEndPosition( g_vecBoundsMin[g_iBuilderZone], null );
	*/
	
	
	// Save to database.
	if ( SaveMapCoords( g_iBuilderZone ) )
	{
		PrintColorChat( client, client, "%s Saved the zone!", CHAT_PREFIX );
	}
	else
	{
		PrintColorChat( client, client, "%s Couldn't save the zone!", CHAT_PREFIX );
	}
	
	
	// Notify clients of the change!
	if ( ( g_iBuilderZone == BOUNDS_START || g_iBuilderZone == BOUNDS_END ) && ( g_bZoneExists[BOUNDS_START] && g_bZoneExists[BOUNDS_END] ) )
	{
		DoMapStuff();
		
		g_bIsLoaded[RUN_MAIN] = true;
		PrintColorChatAll( client, false, "%s Main zones are back!", CHAT_PREFIX );
	}
	else if ( ( g_iBuilderZone == BOUNDS_BONUS_1_START || g_iBuilderZone == BOUNDS_BONUS_1_END ) && ( g_bZoneExists[BOUNDS_BONUS_1_START] && g_bZoneExists[BOUNDS_BONUS_1_END] ) )
	{
		DoMapStuff();
		
		g_bIsLoaded[RUN_BONUS_1] = true;
		PrintColorChatAll( client, false, "%s \x03%s%s is now back!", CHAT_PREFIX, g_szRunName[NAME_LONG][RUN_BONUS_1], COLOR_TEXT );
	}
	else if ( ( g_iBuilderZone == BOUNDS_BONUS_2_START || g_iBuilderZone == BOUNDS_BONUS_2_END ) && ( g_bZoneExists[BOUNDS_BONUS_2_START] && g_bZoneExists[BOUNDS_BONUS_2_END] ) )
	{
		DoMapStuff();
		
		g_bIsLoaded[RUN_BONUS_2] = true;
		PrintColorChatAll( client, false, "%s \x03%s%s is now back!", CHAT_PREFIX, g_szRunName[NAME_LONG][RUN_BONUS_2], COLOR_TEXT );
	}
	// Block zones must be spawned!
	else if ( g_iBuilderZone >= BOUNDS_BLOCK_1 && g_iBuilderZone <= BOUNDS_BLOCK_3 )
	{
		CreateBlockZoneEntity( g_iBuilderZone );
	}
	
	g_iBuilderIndex = INVALID_INDEX;
	g_iBuilderZone = INVALID_ZONE_INDEX;
	
	return Plugin_Handled;
}