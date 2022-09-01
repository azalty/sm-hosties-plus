/*
 * SourceMod Entity Projects
 * by: Entity
 *
 * Copyright (C) 2020 Kőrösfalvi "Entity" Martin
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#if defined _emperor_messages_included
	#endinput
#endif
#define _emperor_messages_included

Database EMP_DB;

/**
* Strip all weapons from the target and save them
*
* @return				Returns a random color
*/
stock int EMP_GetRandomColor()
{
	switch(GetRandomInt(1, 16))
	{
		case  1: return '\x01';
		case  2: return '\x02';
		case  3: return '\x03';
		case  4: return '\x03';
		case  5: return '\x04';
		case  6: return '\x05';
		case  7: return '\x06';
		case  8: return '\x07';
		case  9: return '\x08';
		case 10: return '\x09';
		case 11: return '\x10';
		case 12: return '\x0A';
		case 13: return '\x0B';
		case 14: return '\x0C';
		case 15: return '\x0E';
		case 16: return '\x0F';
	}
	return '\x01';
}

/**
* Escape text to block MySQL exploits
* Use like "char escaped[64] = EMP_EscapeString(SteamName);"
*
* @param string				Strign to escape
*/
stock void EMP_EscapeString(const char[] string)
{
	int len = strlen(string) * 2 + 1;
	char[len] escapedString = new char[len];
	EMP_DB.Escape(string, escapedString, len);
	
	return escapedString;
}

/**
* Replace the color names with code
*
* @param string			String to repalce colors in
* @param size			Size of the string
*/
stock void EMP_ProcessColors(char[] message, int maxLen)
{
	ReplaceString(message, maxLen, "{normal}",      "\x01", false);
	ReplaceString(message, maxLen, "{default}",     "\x01", false);
	ReplaceString(message, maxLen, "{white}",       "\x01", false);
	ReplaceString(message, maxLen, "{darkred}",     "\x02", false);
	ReplaceString(message, maxLen, "{lightred}",    "\x07", false);
	ReplaceString(message, maxLen, "{pink}",        "\x03", false);
	ReplaceString(message, maxLen, "{green}",       "\x04", false);
	ReplaceString(message, maxLen, "{lime}",        "\x05", false);
	ReplaceString(message, maxLen, "{yellow}",      "\x05", false);
	ReplaceString(message, maxLen, "{lightgreen}",  "\x06", false);
	ReplaceString(message, maxLen, "{red}",         "\x02", false);
	ReplaceString(message, maxLen, "{gray}",        "\x08", false);
	ReplaceString(message, maxLen, "{grey}",        "\x08", false);
	ReplaceString(message, maxLen, "{olive}",       "\x09", false);
	ReplaceString(message, maxLen, "{orange}",      "\x10", false);
	ReplaceString(message, maxLen, "{silver}",      "\x0A", false);
	ReplaceString(message, maxLen, "{lightblue}",   "\x0B", false);
	ReplaceString(message, maxLen, "{blue}",        "\x0C", false);
	ReplaceString(message, maxLen, "{purple}",      "\x0E", false);
	ReplaceString(message, maxLen, "{darkorange}",  "\x0F", false);
}

stock void EMP_ReplaceFormats(char[] string, int size, int client = 0)
{
	char buffer[256];
	if (StrContains(string, "{nextmap}"))
	{
		GetNextMap(buffer, sizeof(buffer));
		ReplaceString(string, size, "{nextmap}", buffer);
	}
	
	if (StrContains(string, "{hostname}") || StrContains(string, "{server_name}"))
	{
		Handle hHostName = FindConVar("hostname");
		GetConVarString(hHostName, buffer, sizeof(buffer)); 
		ReplaceString(string, size, "{hostname}", buffer);
		ReplaceString(string, size, "{server_name}", buffer);
		CloseHandle(hHostName);
	}
	
	if (StrContains(string, "{currentmap}"))
	{
		GetCurrentMap(buffer, sizeof(buffer));
		ReplaceString(string, size, "{currentmap}", buffer);
	}
	
	if (StrContains(string, "{timeleft}"))
	{
		int timeleft;
		GetMapTimeLeft(timeleft);
		IntToString(timeleft, buffer, sizeof(buffer));
		ReplaceString(string, size, "{timeleft}", buffer);
	}
	
	if (StrContains(string, "{server_ip}") || StrContains(string, "{ip}"))
	{
		ReplaceString(string, size, "{server_ip}", EMP_GetServerIP());
		ReplaceString(string, size, "{ip}", EMP_GetServerIP());
	}
	
	if (StrContains(string, "{player_count}"))
	{
		IntToString(EMP_GetPlayers(false), buffer, sizeof(buffer));
		ReplaceString(string, size, "{player_count}", buffer);
	}
	
	if (StrContains(string, "{connecting_players}"))
	{
		IntToString(EMP_GetPlayers(true), buffer, sizeof(buffer));
		ReplaceString(string, size, "{connecting_players}", buffer);
	}
	
	if (StrContains(string, "{maxplayers}"))
	{
		IntToString(GetMaxHumanPlayers(), buffer, sizeof(buffer));
		ReplaceString(string, size, "{maxplayers}", buffer);
	}
	
	if (StrContains(string, "{current_date}"))
	{
		FormatTime(buffer, sizeof(buffer), "%d.%m.%Y");
		ReplaceString(string, size, "{current_date}", buffer);
	}
	
	if (StrContains(string, "{current_time}"))
	{
		FormatTime(buffer, sizeof(buffer), "%H:%M:%S");
		ReplaceString(string, size, "{current_time}", buffer);
	}
	
	if (EMP_IsValidClient(client))
	{
		if (StrContains(string, "{userid}"))
		{
			IntToString(GetClientUserId(client), buffer, sizeof(buffer));
			ReplaceString(string, size, "{userid}", buffer);
		}
		
		if (StrContains(string, "{playername}") || StrContains(string, "{name}"))
		{
			Format(buffer, sizeof(buffer), "%N", client);
			ReplaceString(string, size, "{playername}", buffer);
			ReplaceString(string, size, "{name}", buffer);
		}
		
		if (StrContains(string, "{steam32}") || StrContains(string, "{steamid}"))
		{
			GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
			ReplaceString(string, size, "{steam32}", buffer);
			ReplaceString(string, size, "{steamid}", buffer);
		}
		
		if (StrContains(string, "{connection_time}"))
		{
			Format(buffer, sizeof(buffer), "%s", EMP_FormatShortTime(RoundToFloor(GetClientTime(client))));
			ReplaceString(string, size, "{connection_time}", buffer);
		}
		
		if (StrContains(string, "{client_ping}"))
		{
			Format(buffer, sizeof(buffer), "%d", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, client));
			ReplaceString(string, size, "{client_ping}", buffer);
		}
		
		if (StrContains(string, "{client_ip}"))
		{
			GetClientIP(client, buffer, sizeof(buffer));
			ReplaceString(string, size, "{client_ip}", buffer);
		}
	}
}

stock char EMP_GetServerIP()
{
	char NetIP[32];
	int pieces[4];
	int longip = FindConVar("hostip").IntValue;
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], FindConVar("hostport").IntValue);
	return NetIP;
}

stock int EMP_GetPlayers(bool connecting)
{
	int players;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (connecting && IsClientConnected(i) && !IsClientInGame(i))
			players++;
		else if (!connecting && EMP_IsValidClient(i))
			players++;
	}
	return players;
}

stock char EMP_FormatShortTime(int time)
{
	char Time[12];
	int g_iHours = 0;
	int g_iMinutes = 0;
	int g_iSeconds = time;
	
	while (g_iSeconds > 3600) {
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while (g_iSeconds > 60) {
		g_iMinutes++;
		g_iSeconds -= 60;
	}
	if (g_iHours >= 1)Format(Time, sizeof(Time), "%d:%d:%d", g_iHours, g_iMinutes, g_iSeconds);
	else if (g_iMinutes >= 1)Format(Time, sizeof(Time), "  %d:%d", g_iMinutes, g_iSeconds);
	else Format(Time, sizeof(Time), "   %d", g_iSeconds);
	return Time;
}