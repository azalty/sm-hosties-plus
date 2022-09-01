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
#include <lastrequest>

int 	g_Offset_Health 	= -1;

ConVar 	gH_Cvar_AntiHeal_Enabled;

void Antiheal_OnPluginStart()
{
	g_Offset_Health = FindSendPropInfo("CBasePlayer", "m_iHealth");
	if (g_Offset_Health == -1)
	{
		SetFailState("Unable to find offset for health.");
	}

	gH_Cvar_AntiHeal_Enabled		= 	AutoExecConfig_CreateConVar("sm_hosties_antiheal_enabled", "1", "Enable or disable heal anticheat in lr:", 0, true, 0.0, true, 1.0);
}

public void OnStartLR(int PrisonerIndex, int GuardIndex)
{
	if (gH_Cvar_AntiHeal_Enabled.BoolValue)
	{
		if (EMP_IsValidClient(PrisonerIndex, false, false))
		{
			SetEntProp(PrisonerIndex, Prop_Data, "m_iMaxHealth", 100);
			SDKHook(PrisonerIndex, SDKHook_OnTakeDamage, HealBlock);
		}
		
		if (EMP_IsValidClient(GuardIndex, false, false))
		{
			SetEntProp(PrisonerIndex, Prop_Data, "m_iMaxHealth", 100);
			SDKHook(GuardIndex, SDKHook_OnTakeDamage, HealBlock);
		}
	}
}

public void OnStopLR(int PrisonerIndex, int GuardIndex)
{
	if (gH_Cvar_AntiHeal_Enabled.BoolValue)
	{
		if (EMP_IsValidClient(PrisonerIndex, false, true))
		{
			SDKUnhook(PrisonerIndex, SDKHook_OnTakeDamage, HealBlock);
			
			if (IsPlayerAlive(PrisonerIndex))
			{
				SetEntProp(PrisonerIndex, Prop_Data, "m_iMaxHealth", 100);
				SetEntData(PrisonerIndex, g_Offset_Health, 100, 4, true);
			}
		}
		
		if (EMP_IsValidClient(GuardIndex, false, true))
		{
			SDKUnhook(GuardIndex, SDKHook_OnTakeDamage, HealBlock);
			
			if (IsPlayerAlive(GuardIndex))
			{
				SetEntProp(GuardIndex, Prop_Data, "m_iMaxHealth", 100);
				SetEntData(GuardIndex, g_Offset_Health, 100, 4, true);
			}
		}
	}
}

public Action HealBlock(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (EMP_IsValidClient(victim, false, false) && gH_Cvar_AntiHeal_Enabled.BoolValue && IsClientInLastRequest(victim))
	{
		int g_iNewHP = GetEntData(victim, g_Offset_Health);
		SetEntProp(victim, Prop_Data, "m_iMaxHealth", g_iNewHP);
	}
	else
		SDKUnhook(victim, SDKHook_OnTakeDamage, HealBlock);
}