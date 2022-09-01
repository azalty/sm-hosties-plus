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
#include <hosties>
#include <multicolors>

ConVar gH_Cvar_CheckPlayersOn;

void CheckPlayers_OnPluginStart()
{
	gH_Cvar_CheckPlayersOn 	= 	AutoExecConfig_CreateConVar("sm_hosties_checkplayers_enable", "1", "Enable or disable the !checkplayers command: 0 - disable, 1 - enable", FCVAR_NONE, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_checkplayers", Command_CheckPlayers);
}

public Action Command_CheckPlayers(int client, int args)
{
	if (gH_Cvar_CheckPlayersOn.BoolValue)
	{
		if (IsPlayerAlive(client))
		{
			// count number of rebels
			int realrebelscount = 0;
			for (int idx = 1; idx < MaxClients; idx++)
			{
				if (g_bIsARebel[idx] && IsClientInGame(idx))
				{
					realrebelscount++;
				}
			}

			if (realrebelscount < 1)
			{
				CPrintToChat(client, "%s %t", gShadow_Hosties_ChatBanner, "No Rebels ATM");
			}
			else
			{
				Handle checkplayersmenu = CreateMenu(Handler_DoNothing);
				char rebellingterrorists[32];
				Format(rebellingterrorists, sizeof(rebellingterrorists), "%T", "Rebelling Terrorists", client);
				SetMenuTitle(checkplayersmenu, rebellingterrorists);
				char item[64];
				for(int i; i < MaxClients; i++)
				{
					if (g_bIsARebel[i] && IsClientInGame(i))
					{
						GetClientName(i, item, sizeof(item));
						AddMenuItem(checkplayersmenu, "player", item);
					}
				}
				SetMenuExitButton(checkplayersmenu, true);
				DisplayMenu(checkplayersmenu, client, MENU_TIME_FOREVER);
			}
		}
	}
	else
	{
		CReplyToCommand(client,  "%s %t", gShadow_Hosties_ChatBanner, "CheckPlayers CMD Disabled");
	}

	return Plugin_Handled;
}

public int Handler_DoNothing(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
}