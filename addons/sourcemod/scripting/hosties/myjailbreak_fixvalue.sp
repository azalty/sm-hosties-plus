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
#include <sdktools>
#include <hosties>
#include <multicolors>

int FIX_Announce_RD,
	FIX_Rebel_Color,
	FIX_Mute,
	FIX_Announce_Attack,
	FIX_Announce_WPN_A,
	FIX_Freekill_Not,
	FIX_Freekill_Tre;

void FixJB_OnPluginStart()
{
	HookEvent("round_start", FIXJB_RoundStart);
	
	if (g_bMYJB) SaveValues();
}

public Action FIXJB_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bMYJB)
	{
		if (GetFeatureStatus(FeatureType_Native, "MyJailbreak_IsEventDayRunning") == FeatureStatus_Available)
		{
			if (!MyJailbreak_IsEventDayRunning())
				RestoreValues();
		}
	}
}

void FixJB_OnConfigsExecuted()
{
	if (g_bMYJB) SaveValues();
}

public void FIXJB_OnEventDayEnd(char[] EventDayName, int winner)
{
	RestoreValues();
}

stock void RestoreValues()
{
	gH_Cvar_Announce_RebelDown.IntValue = FIX_Announce_RD;
	gH_Cvar_ColorRebels.IntValue = FIX_Rebel_Color;
	gH_Cvar_MuteStatus.IntValue = FIX_Mute;
	gH_Cvar_Announce_CT_FreeHit.IntValue = FIX_Announce_Attack;
	gH_Cvar_Announce_Weapon_Attack.IntValue = FIX_Announce_WPN_A;
	gH_Cvar_Freekill_Notify.IntValue = FIX_Freekill_Not;
	gH_Cvar_Freekill_Threshold.IntValue = FIX_Freekill_Tre;
}

stock void SaveValues()
{
	FIX_Announce_RD = gH_Cvar_Announce_RebelDown.IntValue;
	FIX_Rebel_Color = gH_Cvar_ColorRebels.IntValue;
	FIX_Mute = gH_Cvar_MuteStatus.IntValue;
	FIX_Announce_Attack = gH_Cvar_Announce_CT_FreeHit.IntValue;
	FIX_Announce_WPN_A = gH_Cvar_Announce_Weapon_Attack.IntValue;
	FIX_Freekill_Not = gH_Cvar_Freekill_Notify.IntValue;
	FIX_Freekill_Tre = gH_Cvar_Freekill_Threshold.IntValue;
}