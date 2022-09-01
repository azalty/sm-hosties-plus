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
#include <hosties>

int g_Offset_CollisionGroup = -1;
ConVar gH_Cvar_NoBlock;

void NoBlock_OnPluginStart()
{
	gH_Cvar_NoBlock = AutoExecConfig_CreateConVar("sm_hosties_noblock_enable", "1", "Enable or disable integrated removing of player vs player collisions (noblock): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	
	g_Offset_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if (g_Offset_CollisionGroup == -1)
	{
		SetFailState("Unable to find offset for collision groups.");
	}
	
	HookEvent("player_spawn", NoBlock_PlayerSpawn);
}

public Action NoBlock_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (gH_Cvar_NoBlock.BoolValue)
	{
		UnblockEntity(client, g_Offset_CollisionGroup);
	}
}
