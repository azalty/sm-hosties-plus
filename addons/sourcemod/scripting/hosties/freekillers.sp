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
#include <sdktools>
#include <cstrike>
#include <hosties>
#include <lastrequest>
#include <multicolors>

ConVar	gH_Cvar_Advanced_FK_Prevention;

int	 	g_iLastKillTime[MAXPLAYERS+1],
		g_iConsecutiveKills[MAXPLAYERS+1];

Handle 	gH_Reset_Kill_Counter[MAXPLAYERS+1];

void Freekillers_OnPluginStart()
{
	gH_Cvar_Freekill_Sound 			= AutoExecConfig_CreateConVar("sm_hosties_freekill_sound", "sm_hosties/freekill1.mp3", "What sound to play if a non-rebelling T gets 'freekilled', relative to the sound-folder: -1 - disable, path - path to sound file", 0);
	gH_Cvar_Freekill_Threshold 		= AutoExecConfig_CreateConVar("sm_hosties_freekill_treshold", "0", "The amount of non-rebelling terrorists a CT is allowed to kill before action is taken: 0 - disabled, >0 - amount of Ts", 0, true, 0.0, true, 64.0);
	gH_Cvar_Freekill_Notify 		= AutoExecConfig_CreateConVar("sm_hosties_freekill_notify", "0", "Whether to notify CTs who kills a non-rebelling T about how many 'freekills' they have, or not: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Freekill_BanLength 		= AutoExecConfig_CreateConVar("sm_hosties_freekill_ban_length", "60", "The length of an automated freekill ban (if sm_hosties_freekill_punishment is 2): x - ban length in minutes", _, true, 0.0);
	gH_Cvar_Freekill_Punishment 	= AutoExecConfig_CreateConVar("sm_hosties_freekill_punishment", "0", "The punishment to give to a CT who overrides the treshold: 0 - slay, 1 - kick, 2 - ban", 0, true, 0.0, true, 2.0);
	gH_Cvar_Freekill_Reset 			= AutoExecConfig_CreateConVar("sm_hosties_freekill_reset", "0", "When to reset the 'freekill counter' for all CTs: 0 - on round start, 1 - on map end", 0, true, 0.0, true, 1.0);
	gH_Cvar_Advanced_FK_Prevention	= AutoExecConfig_CreateConVar("sm_hosties_freekill_adv_prot", "1", "Turns on or off the advanced freekill protection system.", 0, true, 0.0, true, 1.0);
	
	Format(gShadow_Freekill_Sound, PLATFORM_MAX_PATH, "sm_hosties/freekill1.mp3");
	gShadow_Freekill_Punishment 	= FP_Slay;
	
	HookEvent("player_death", Freekillers_PlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Freekillers_RoundEnd);
	
	HookConVarChange(gH_Cvar_Freekill_Sound, Freekillers_CvarChanged);
	HookConVarChange(gH_Cvar_Freekill_Punishment, Freekillers_CvarChanged);
	
	ResetNumFreekills();
	
	for (int kidx = 1; kidx < MaxClients; kidx++)
	{	
		if (IsClientInGame(kidx))
		{
			SDKHook(kidx, SDKHook_OnTakeDamage, Freekill_Damage_Adjustment);
		}
	}
}

void ResetNumFreekills()
{
	for (int fidx = 1; fidx < MaxClients; fidx++)
	{
		gH_Reset_Kill_Counter[fidx] = null;
		g_iLastKillTime[fidx] = 0;
		g_iConsecutiveKills[fidx] = 0;
		gA_FreekillsOfCT[fidx] = 0;
	}
}

void Freekillers_OnMapEnd()
{
	if (gH_Cvar_Freekill_Reset.BoolValue)
	{
		ResetNumFreekills();
	}
}

public Action Freekill_Damage_Adjustment(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if ((victim != attacker) && (victim > 0) && (victim <= MaxClients) && (attacker > 0) && (attacker <= MaxClients))
	{
		if (gH_Cvar_Advanced_FK_Prevention.BoolValue && (g_iConsecutiveKills[attacker] > 0))
		{
			float f_percentChange = 0.01*(100.0 - 20.0*float(g_iConsecutiveKills[attacker]));			
			if (f_percentChange < 0.01)
			{
				f_percentChange = 0.01;
			}
			damage = f_percentChange * damage;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

void Freekillers_ClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Freekill_Damage_Adjustment); 
}

void Freekillers_OnConfigsExecuted()
{
	// check for -1 for backward compatibility
	GetConVarString(gH_Cvar_Freekill_Sound, gShadow_Freekill_Sound, sizeof(gShadow_Freekill_Sound));
	if ((strlen(gShadow_Freekill_Sound) > 0) && strcmp(gShadow_Freekill_Sound, "-1") != 0)
	{
		MediaType soundfile = type_Sound;
		CacheTheFile(gShadow_Freekill_Sound, soundfile);
	}
	gShadow_Freekill_Punishment = GetConVarInt(gH_Cvar_Freekill_Punishment);
}

public void Freekillers_CvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == gH_Cvar_Freekill_Sound)
		Format(gShadow_Freekill_Sound, PLATFORM_MAX_PATH, newValue);
	else if (cvar == gH_Cvar_Freekill_Punishment)
		gShadow_Freekill_Punishment = StringToInt(newValue);
}

public Action Freekillers_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (gH_Cvar_Freekill_Reset.IntValue == 0)
	{
		ResetNumFreekills();
	}
}

public Action Freekillers_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// if attacker was a counter-terrorist and target was a terrorist
	if (EMP_IsValidClient(attacker, false, false, CS_TEAM_CT) && \
		EMP_IsValidClient(victim, false, false, CS_TEAM_T))
	{
		// advanced freekill tracking
		int iTime = GetTime();
		int iTimeSinceKill = iTime - g_iLastKillTime[attacker];
		g_iLastKillTime[attacker] = iTime;
		
		if ((iTimeSinceKill <= 4) || g_iConsecutiveKills[attacker] == 0)
		{
			g_iConsecutiveKills[attacker]++;
			gH_Reset_Kill_Counter[attacker] = CreateTimer(4.0, Timer_ResetKills, attacker, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (!g_bIsARebel[victim])
		{
			int iArraySize = GetArraySize(gH_DArray_LR_Partners);
			if (iArraySize == 0)
			{
				TakeActionOnFreekiller(attacker);
			}
			else
			{
				// check if victim was in an LR and not the attacker pair
				for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
				{
					int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
					int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
					int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
					
					if (type != LR_Rebel && (victim == LR_Player_Prisoner) && (attacker != LR_Player_Guard))
					{
						TakeActionOnFreekiller(attacker);
					}
				}
			}
		}
	}
}

public Action Timer_ResetKills(Handle timer, any client)
{
	if (gH_Reset_Kill_Counter[client] == timer)
	{
		g_iConsecutiveKills[client] = 0;
		gH_Reset_Kill_Counter[client] = null;
	}
	
	return Plugin_Stop;
}

void TakeActionOnFreekiller(int attacker)
{
	// FREEEEEKILL... rawr...
	if (gH_Cvar_Freekill_Threshold.IntValue > 0)
	{
		if (gA_FreekillsOfCT[attacker] >= gH_Cvar_Freekill_Threshold.IntValue)
		{
			// Take action...
			switch(gShadow_Freekill_Punishment)
			{
				case FP_Slay:
				{
					ForcePlayerSuicide(attacker);
					LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Freekill Slay", attacker);
					gA_FreekillsOfCT[attacker] = 0;
				}
				case FP_Kick:
				{
					KickClient(attacker, "%t", "Freekill Kick Reason");
					LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Freekill Kick", attacker);
					LogMessage("%N was kicked for killing too many non-rebelling terrorists.", attacker);
				}
				case FP_Ban:
				{
					if (g_bSBAvailable)
					{
						SBPP_BanPlayer(0, attacker, gH_Cvar_Freekill_BanLength.IntValue, "SM_Hosties: Freekilling");
					}
					else
					{
						char ban_message[128];
						Format(ban_message, sizeof(ban_message), "%T", "Freekill Ban Reason", attacker);
						BanClient(attacker, gH_Cvar_Freekill_BanLength.IntValue, BANFLAG_AUTO, "SM_Hosties: Freekilling", ban_message);
						LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Freekill Ban", attacker);
					}
				}
			}
		}
		else
		{
			// Add 1 freekill to the records...
			gA_FreekillsOfCT[attacker]++;

			// Notify the player if the server owner so desires...
			if (gH_Cvar_Freekill_Notify.BoolValue)
			{
				PrintHintText(attacker, "%t", "Freekill Record Increased", gA_FreekillsOfCT[attacker], gH_Cvar_Freekill_Threshold.IntValue+1);
			}
		}
		
		// check for -1 for backward compatibility
		if ((strlen(gShadow_Freekill_Sound) > 0) && strcmp(gShadow_Freekill_Sound, "-1") != 0)
		{
			EmitSoundToAllAny(gShadow_Freekill_Sound);
		}
	}
}