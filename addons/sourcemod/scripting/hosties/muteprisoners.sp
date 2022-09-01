/*
 * SourceMod Hosties Project
 * by: SourceMod Hosties Dev Team
 *
 * This file is part of the SM Hosties project.
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

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <hosties>
#undef REQUIRE_PLUGIN
#include <basecomm>
#define REQUIRE_PLUGIN

ConVar 	gH_Cvar_MuteStatus,
		gH_Cvar_MuteLength,
		gH_Cvar_MuteImmune,
		gH_Cvar_MuteCT;

int gAdmFlags_MuteImmunity;

void MutePrisoners_OnPluginStart()
{
	gH_Cvar_MuteStatus = AutoExecConfig_CreateConVar("sm_hosties_mute", "1", "Setting for muting terrorists automatically: 0 - disable, 1 - terrorists are muted the first few seconds of a round, 2 - terrorists are muted when they die, 3 - both", 0, true, 0.0, true, 3.0);	
	gH_Cvar_MuteLength = AutoExecConfig_CreateConVar("sm_hosties_roundstart_mute", "30.0", "The length of time the Terrorist team is muted for after the round begins", 0, true, 3.0, true, 90.0);	
	gH_Cvar_MuteImmune = AutoExecConfig_CreateConVar("sm_hosties_mute_immune", "z", "Admin flags which are immune from getting muted: 0 - nobody, flag values: abcdefghijklmnopqrst");	
	gH_Cvar_MuteCT = AutoExecConfig_CreateConVar("sm_hosties_mute_ct", "0", "Setting for muting counter-terrorists automatically when they die (requires sm_hosties_mute 2 or 3): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	
	CalImmun();
}

void MutePrisoners_AllPluginsLoaded()
{
	HookEvent("round_start", MutePrisoners_RoundStart);
	HookEvent("round_end", MutePrisoners_RoundEnd);
	HookEvent("player_death", MutePrisoners_PlayerDeath);
	HookEvent("player_spawn", MutePrisoners_PlayerSpawn);
}

void MutePrisoners_OnConfigsExecuted()
{
	CalImmun();
}

stock void CalImmun()
{
	char flag[32];
	gH_Cvar_MuteImmune.GetString(flag, sizeof(flag));
	int bt = EMP_Flag_StringToInt(flag);
	gAdmFlags_MuteImmunity = (bt != -1) ? bt : 0;
}

stock void MuteTs()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (EMP_IsValidClient(i, false, false, CS_TEAM_T)) // if player is in game and alive with better validation
		{
			if (!BaseComm_IsClientMuted(i))
			{
				MutePlayer(i);
			}
		}
	}
}

stock void UnmuteAlive()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (EMP_IsValidClient(i, false, false)) // if player is in game and alive with better validation
		{
			if (!BaseComm_IsClientMuted(i))
			{
				UnmutePlayer(i);
			}
		}
	}
}

stock void UnmuteAll()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (EMP_IsValidClient(i)) // if player is in game
		{
			if (!BaseComm_IsClientMuted(i))
			{
				UnmutePlayer(i);
			}
		}
	}
}

public Action MutePrisoners_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if ((gH_Cvar_MuteStatus.IntValue == 1 || gH_Cvar_MuteStatus.IntValue == 3) && ((g_Game == Game_CSGO && GameRules_GetProp("m_bWarmupPeriod") == 0) || g_Game == Game_CSS))
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			if (gAdmFlags_MuteImmunity == 0)
			{
				CreateTimer(0.1, Timer_Mute, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if (!Client_HasAdminFlags(client, gAdmFlags_MuteImmunity) || !Client_HasAdminFlags(client, ADMFLAG_ROOT))
				{
					CreateTimer(0.1, Timer_Mute, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action MutePrisoners_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (gH_Cvar_MuteStatus.IntValue <= 1)
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((gAdmFlags_MuteImmunity == 0 || !Client_HasAdminFlags(victim, gAdmFlags_MuteImmunity) || !Client_HasAdminFlags(victim, ADMFLAG_ROOT)) && ((g_Game == Game_CSGO && GameRules_GetProp("m_bWarmupPeriod") == 0) || g_Game == Game_CSS))
	{
		int team = GetClientTeam(victim);
		switch (team)
		{
			case CS_TEAM_T:
			{
				CreateTimer(0.1, Timer_Mute, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
			}
			case CS_TEAM_CT:
			{
				if (gH_Cvar_MuteCT.BoolValue)
				{			
					CreateTimer(0.1, Timer_Mute, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

public Action Timer_Mute(Handle timer, any id)
{
	int client = GetClientOfUserId(client);
	if (EMP_IsValidClient(client))
	{
		MutePlayer(client);
		CPrintToChat(client, "%s %t", gShadow_Hosties_ChatBanner, "Now Muted");
	}
	
	return Plugin_Stop;
}

public Action MutePrisoners_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (gH_Cvar_MuteStatus.IntValue)
	{
		// Unmute Timer
		CreateTimer(0.2, Timer_UnmuteAll, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action MutePrisoners_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (gH_Cvar_MuteStatus.IntValue == 1 || gH_Cvar_MuteStatus.IntValue == 3)
	{
		if (gAdmFlags_MuteImmunity == 0)
		{
			// Mute All Ts
			MuteTs();
		}
		else
		{
			// Mute non-flagged Ts
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx, false, true, CS_TEAM_T) && !Client_HasAdminFlags(idx, gAdmFlags_MuteImmunity || !Client_HasAdminFlags(idx, ADMFLAG_ROOT)))
				{
					MutePlayer(idx);
				}
			}
		}
		
		CreateTimer(gH_Cvar_MuteLength.FloatValue, Timer_UnmutePrisoners, _, TIMER_FLAG_NO_MAPCHANGE);
		
		LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Ts Muted", RoundToNearest(gH_Cvar_MuteLength.FloatValue));
	}
}

public Action Timer_UnmutePrisoners(Handle timer)
{
	UnmuteAlive();
	LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Ts Can Speak Again");
	return Plugin_Stop;
}

public Action Timer_UnmuteAll(Handle timer)
{
	UnmuteAll();
	return Plugin_Stop;
}