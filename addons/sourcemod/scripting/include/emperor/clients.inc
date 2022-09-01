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

#if defined _emperor_client_included
	#endinput
#endif
#define _emperor_client_included

//Loop all the Connected Players (No bots included)
#define EMP_LoopPlayers(%1) for (int %1 = 1; %1 <= MaxClients; ++%1) if (EMP_IsValidClient(%1, false, true))

//Loop all the Alive Connected Players (No bots or Dead players included)
#define EMP_LoopAlivePlayers(%1) for (int %1 = 1; %1 <= MaxClients; ++%1) if (EMP_IsValidClient(%1, false, false))

/**
* Checks if the specified client index is valid or not.
*
* @param client				An entity index
* @param bAllowBots			Set Bots to be accepted or not. Default: False
* @param bAllowDead			Set Dead Players to be accepted or not. Default: True
* @param Team				Set the team the player must be in
* @return					Returns true if the specified entity index is a player connected, false otherwise.
*/
stock bool EMP_IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true, int team = -1)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (!bAllowBots && IsFakeClient(client)) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)) || (team != -1 && GetClientTeam(client) != team))
    {
        return false;
    }
    return true;
}

/**
* Gets a random client from the server
*
* @param alive				If True the client has to be alive
* @param bAllowBots			IF set the adminflag will be ignored
* @return					Returns the idx of the client
*/
stock int EMP_RandomClient(bool alive = false, int ignoreFlags = 0)
{
    int[] clients = new int [MaxClients+1];
    int total;

    clients[total++] = -1;

    for (int client = 1; client <= MaxClients; client++)
        if(ClientIsValid(client))
            if(!alive || ClientIsAlive(client))
                if((ignoreFlags != 0 && HasClientUserFlags(client, ignoreFlags)) || ignoreFlags == 0) 
                    clients[total++] = client;
    
    return clients[RandomInt(0, total)];
}

/**
* Checks if a client is in the sight range
*
* @param client				Client index
* @param target				Target index
* @param angle				Angle to check
* @param floatdistance		Distance to check
* @param heightcheck		Check the target heigh too?
* @param negativeangle		Negate the Vector or not?
* @return					Returns True if in the sight range, otherwise false
*/
stock bool EMP_IsTargetInSightRange(int client, int target, float angle = 90.0, float floatdistance = 0.0, bool heightcheck = true, bool negativeangle = false)
{
	if((angle > 360.0 || angle < 0.0) || !EMP_IsValidClient(client, true, false) || !EMP_IsValidClient(target, true, false))
		return false;
		
	float clientpos[3], targetpos[3], anglevector[3], targetvector[3], resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
		
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	float resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
				
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

/**
* Returns if the client is currently playing sound from HLDJ or SLAM
*
* @param client				Player index
*/
stock bool EMP_CheckAudio(int client)
{
	if (EMP_IsValidClient(client))
		return QueryClientConVar(client, "voice_inputfromfile", EMP_Query_CheckAudio);
	else
		return false;
}

stock bool EMP_Query_CheckAudio(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if (result == ConVarQuery_Okay && StringToInt(cvarValue) == 1)
		return true;
	else
		return false;
}

/**
* Sets the Clan Tag for a client
*
* @param client				Player index
* @param buffer				Text to set the clantag to
*/
stock void EMP_SetClanTag(int client, const char[] buffer)
{
	if (EMP_IsValidClient(client))
		CS_SetClientClanTag(client, buffer);
}

/**
* Safely kills the player without any problem
*
* @param client				Player index
*/
stock void EMP_SafeSlay(int client)
{
	if (EMP_IsValidClient(client))
		ForcePlayerSuicide(client);
}

/**
* Shows an overlay to the client
*
* @param client				Player index
* @param overlaypath		Path to the overlay to show
*/
stock void EMP_ShowOverlayToClient(int client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

/**
* Shows an overlay to everyone in the server
*
* @param overlaypath		Path to the overlay to show
*/
stock void EMP_ShowOverlayToAll(const char[] overlaypath)
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (EMP_IsValidClient(x))
		{
			EMP_ShowOverlayToClient(x, overlaypath);
		}
	}
}

/**
* Sets the godmode for the client
*
* @param client		Player index
* @param mode		Enable or disable the mode (True - Enable, False - Disable)
*/
stock void EMP_GodMode(int client, bool mode)
{
	if (EMP_IsValidClient(client))
	{
		if (mode)
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		else
			SetEntProp(attacker, Prop_Data, "m_takedamage", 2, 1);
	}
}

/**
* Mutes the player (Recommended to use with Basecomm or Sourceban checks)
*
* @param client		Player index
*/
stock void EMP_MutePlayer(int client)
{
	if (EMP_IsValidClient(client))
		SetClientListeningFlags(client, VOICE_MUTED);
}

/**
* Unmutes the player (Recommended to use with Basecomm or Sourceban checks)
*
* @param client		Player index
*/
stock void EMP_UnmutePlayer(int client)
{
	if (EMP_IsValidClient(client))
	{
		static Handle cvDeadTalk = INVALID_HANDLE;

		if (cvDeadTalk == INVALID_HANDLE) cvDeadTalk = FindConVar("sm_deadtalk");

		if (cvDeadTalk == INVALID_HANDLE)
			SetClientListeningFlags(client, VOICE_NORMAL);
		else
		{
			if (GetConVarInt(cvDeadTalk) == 1 && !IsPlayerAlive(client))
				SetClientListeningFlags(client, VOICE_LISTENALL);
			else if (GetConVarInt(cvDeadTalk) == 2 && !IsPlayerAlive(client))
				SetClientListeningFlags(client, VOICE_TEAM);
			else
				SetClientListeningFlags(client, VOICE_NORMAL);
		}
	}
}

/**
 * Displays a MOTD panel for a specified player
 */
stock void CSGO_ShowMOTDPanel(int client, const char[] title, const char[] url, bool show = false, int width = 0, int height = 0)
{
	KeyValues kv = new KeyValues("data");
	
	kv.SetString("title", title);
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	kv.SetString("msg", url);
	
	if (show)
	{
		kv.SetNum("x-vgui-width", width);
		kv.SetNum("x-vgui-height", height);
	}
	
	ShowVGUIPanel(client, "info", kv, show);
	
	delete kv;
}

/**
* Closes the menus to free memory or just for some reason
*/
stock void EMP_CancelAllMenus()
{
	for (int idx = 1; idx < MaxClients; idx++)
	{
		if (EMP_IsValidClient(idx))
		{
			if (GetClientMenu(idx))
				CancelClientMenu(idx);
		}
	}
}

/**
* Sets the player model
*
* @param client				Player index
* @param model_path			Path to the model
*/
stock void EMP_SetPlayerModel(int client, char model_path[PLATFORM_MAX_PATH])
{
	if (EMP_IsValidClient(idx))
	{
		if(strcmp(model_path, "") != 0)
		{
			if(!IsModelPrecached(model_path))
				PrecacheModel(model_path);
			SetEntityModel(client, model_path);
		}
	}
}

/**
* Reset player armor, helmet
*
* @param client				Player index
*/
stock void EMP_ResetArmor(int client)
{
	if (EMP_IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
		SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 0);
	
		if (GetEngineVersion() == Engine_CSGO)
		{
			SetEntProp(client, Prop_Send, "m_bHasHeavyArmor", 0);
			SetEntProp(client, Prop_Send, "m_bWearingSuit", 0);
		}
	}
}

/**
* Searches for a player by the given Steam32 ID
*
* @param id					Steam32 ID
* @return					Returns the client index of the user
*/
stock int EMP_GetClientOfSteamID(const char[] id)
{
	char steamid[20];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if(!EMP_IsValidClient(i))
			continue;
		
		GetClientAuthId(i, AuthId_Steam2, steamid, sizeof(steamid));
		if(StrEqual(steamid, id))
			return i;
	}

	return -1;
}

/**
* Dissolves the player deadd body
*
* @param client				Player index
*/
stock void EMP_Dissolve(int client)
{
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > 0)
	{
		int ent = CreateEntityByName("env_entity_dissolver");
		if (ent > 0)
		{
			char dissolvename[32];
			Format(dissolvename, sizeof(dissolvename), "dis_%d", client);
			DispatchKeyValue(ragdoll, "targetname", dissolvename);
			DispatchKeyValue(ent, "dissolvetype", "0");
			DispatchKeyValue(ent, "target", dissolvename);
			AcceptEntityInput(ent, "Dissolve");
			AcceptEntityInput(ent, "kill");
		}
	}
}

/**
* Hide/Show player on the radar
*
* @param client				Player index
* @param status				Status for the hide
*/
stock void EMP_RadarVisibilityToggle(int client, bool status)
{
	int offset = FindSendPropInfo("CBaseEntity", "m_bSpotted");
	if (offset > 0)
	{
		Address g_aCanBeSpotted = view_as<Address>(offset - 4);
		
		if (active)
		{
			SetEntProp(client, Prop_Send, "m_bSpotted", false);
			SetEntProp(client, Prop_Send, "m_bSpottedByMask", 0, 4, 0);
			SetEntProp(client, Prop_Send, "m_bSpottedByMask", 0, 4, 1);
		   
			StoreToAddress(GetEntityAddress(client)+g_aCanBeSpotted, 0, NumberType_Int32);
		}
		else
		{
			StoreToAddress(GetEntityAddress(client)+g_aCanBeSpotted, 9, NumberType_Int32);
		}
	}
}

/**
* Checks if the client is currently looking at wall
*
* @param client				Player index
* @param distance			Distance to check
* @return					Returns True if the clients is looking at wall otherwise false
*/
stock bool EMP_IsLookingAtWall(int client, float distance=40.0)
{

	float posEye[3], posEyeAngles[3];
	bool isClientLookingAtWall = false;

	GetClientEyePosition(client, posEye);
	GetClientEyeAngles(client, posEyeAngles);

	posEyeAngles[0] = 0.0;

	Handle trace = TR_TraceRayFilterEx(posEye, posEyeAngles, CONTENTS_SOLID, RayType_Infinite, LookingWall_TraceEntityFilter);

	if (TR_DidHit(trace))
	{
		if (TR_GetEntityIndex(trace) > 0)
		{
			CloseHandle(trace);
			return false;
		}

		float posEnd[3];

		TR_GetEndPosition(posEnd, trace);

		if (GetVectorDistance(posEye, posEnd, true) <= (distance * distance))
		{
			isClientLookingAtWall = true;
		}
	}

	CloseHandle(trace);

	return isClientLookingAtWall;
}

public bool LookingWall_TraceEntityFilter(int entity, int contentsMask)
{
	return entity == 0;
}

/**
* Checks if the client is currently crouching
*
* @param client				Player index
* @return					Returns True if the clients is crouching otherwise false
*/
stock bool EMP_IsClientCrouching(int client)
{
	if(GetEntityFlags(client) & FL_DUCKING)
		return true;

	return false;
}

/**
* Checks if the client is currently on the ground
*
* @param client				Player index
* @return					Returns True if the clients is on the ground otherwise false
*/
stock bool EMP_IsClientOnGround(int client)
{
	if(GetEntityFlags(client) & FL_ONGROUND)
		return true;

	return false;
}

/**
* Convert flag from char to int
*
* @param buffer				Buffer to read the flag letter from
* @return					Returns the int value of the flag given as a letter. (-1 if the flag is incorrect)
*/
stock int EMP_Flag_StringToInt(char[] buffer)
{
	int length = strlen(buffer);
	if ((StrContains("abcdefghijklmnopqrstz", buffer) != -1) && (length == 1))
	{
		EMP_FlagStringToInt_Change(buffer, "a", ADMFLAG_RESERVATION);
		EMP_FlagStringToInt_Change(buffer, "b", ADMFLAG_GENERIC);
		EMP_FlagStringToInt_Change(buffer, "c", ADMFLAG_KICK);
		EMP_FlagStringToInt_Change(buffer, "d", ADMFLAG_BAN);
		EMP_FlagStringToInt_Change(buffer, "e", ADMFLAG_UNBAN);
		EMP_FlagStringToInt_Change(buffer, "f", ADMFLAG_SLAY);
		EMP_FlagStringToInt_Change(buffer, "g", ADMFLAG_CHANGEMAP);
		EMP_FlagStringToInt_Change(buffer, "h", ADMFLAG_CONVARS);
		EMP_FlagStringToInt_Change(buffer, "i", ADMFLAG_CONFIG);
		EMP_FlagStringToInt_Change(buffer, "j", ADMFLAG_CHAT);
		EMP_FlagStringToInt_Change(buffer, "k", ADMFLAG_VOTE);
		EMP_FlagStringToInt_Change(buffer, "l", ADMFLAG_PASSWORD);
		EMP_FlagStringToInt_Change(buffer, "m", ADMFLAG_RCON);
		EMP_FlagStringToInt_Change(buffer, "n", ADMFLAG_CHEATS);
		EMP_FlagStringToInt_Change(buffer, "z", ADMFLAG_ROOT);
		EMP_FlagStringToInt_Change(buffer, "o", ADMFLAG_CUSTOM1);
		EMP_FlagStringToInt_Change(buffer, "p", ADMFLAG_CUSTOM2);
		EMP_FlagStringToInt_Change(buffer, "q", ADMFLAG_CUSTOM3);
		EMP_FlagStringToInt_Change(buffer, "r", ADMFLAG_CUSTOM4);
		EMP_FlagStringToInt_Change(buffer, "s", ADMFLAG_CUSTOM5);
		EMP_FlagStringToInt_Change(buffer, "t", ADMFLAG_CUSTOM6);
		
		return StringToInt(buffer);
	}
	else
		return -1;
}

stock void EMP_FlagStringToInt_Change(char[] StrToReplace, char[] flag, int ReplaceWith)
{
	char NewFlagValue[10];
	IntToString(ReplaceWith, NewFlagValue, sizeof(NewFlagValue));
	ReplaceString(StrToReplace, 10, flag, NewFlagValue, false);
}