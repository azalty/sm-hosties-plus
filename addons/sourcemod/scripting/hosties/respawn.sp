/*
 * SourceMod Hosties+ Project
 * by: SourceMod Hosties+ Dev Team
 *
 * Copyright (C) 2020 Kőrösfalvi "Entity" Martin
 * Copyright (C) 2023 azalty
 *
 * This file is part of the Hosties+ project.
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
#include <multicolors>

float g_DeathLocation[MAXPLAYERS+1][3];

void Respawn_OnPluginStart()
{
	RegAdminCmd("sm_hrespawn", Command_Respawn, ADMFLAG_SLAY);
	RegAdminCmd("sm_1up", Command_Respawn, ADMFLAG_SLAY);
	HookEvent("player_death", Respawn_PlayerDeath);
}

public Action Command_Respawn(int client, int args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "%sUsage: sm_hrespawn <#userid|name>", gShadow_Hosties_ChatBanner);
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_DEAD|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		PerformRespawn(client, target_list[i]);
	}
	
	Hosties_ShowActivity(client, "%t", "Respawned Target", target_name);
	
	return Plugin_Handled;
}

void Respawn_PlayerDeath(Event event, const char[] name , bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(victim, g_DeathLocation[victim]);
	// account for eye level versus origin level to avoid clipping
	g_DeathLocation[victim][2] -= 45.0;
}

void Respawn_Menus(Handle h_TopMenu, TopMenuObject obj_Hosties)
{
	AddToTopMenu(h_TopMenu, "sm_hrespawn", TopMenuObject_Item, AdminMenu_Respawn, obj_Hosties, "sm_hrespawn", ADMFLAG_SLAY);
}

void PerformRespawn(int client, int target)
{
	CS_RespawnPlayer(target);
	if (g_DeathLocation[target][0] == 0.0 && g_DeathLocation[target][1] == 0.0 && g_DeathLocation[target][2] == 0.0)
	{
		// no death location was available
		CReplyToCommand(client, "%s%t", gShadow_Hosties_ChatBanner, "Respawn Data Unavailable", target);
	}
	else
	{
		TeleportEntity(target, g_DeathLocation[target], NULL_VECTOR, NULL_VECTOR);
	}
	LogAction(client, target, "\"%L\" respawned \"%L\"", client, target);
}

void DisplayRespawnMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_Respawn);
	
	char title[100];
	Format(title, sizeof(title), "%T", "Respawn Player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	if (EMP_IsValidClient(client))
	{
		int targets_added = AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD|COMMAND_FILTER_NO_BOTS);
		if (targets_added == 0)
		{
			CReplyToCommand(client, "%s%t", gShadow_Hosties_ChatBanner, "Target is not in game");
			if (gH_TopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(gH_TopMenu, client, TopMenuPosition_LastCategory);
			}
		}
		else
		{
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
	}
	else
	{
		CReplyToCommand(client, "[Hosties] You have to be in game to use that command!");
	}
}

public void AdminMenu_Respawn(Handle topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Respawn Player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayRespawnMenu(param);
	}
}

int MenuHandler_Respawn(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && gH_TopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(gH_TopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			CPrintToChat(param1, "%s%t", gShadow_Hosties_ChatBanner, "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			CPrintToChat(param1, "%s%t", gShadow_Hosties_ChatBanner, "Unable to target");
		}
		else if (IsPlayerAlive(target))
		{
			CReplyToCommand(param1, "%s%t", gShadow_Hosties_ChatBanner, "Player Alive");
		}
		else
		{
			char name[32];
			GetClientName(target, name, sizeof(name));
			PerformRespawn(param1, target);
			Hosties_ShowActivity(param1, "%t", "Respawned Target", name);
		}
		
		DisplayRespawnMenu(param1);
	}
	return 0;
}