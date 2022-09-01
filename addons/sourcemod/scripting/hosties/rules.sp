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

ConVar 	gH_Cvar_RulesOn,
		gH_Cvar_Announce_Rules,
		gH_Cvar_Rules_Mode,
		gH_Cvar_Rules_Website;

char gShadow_Rules_Website[192];
Handle gH_DArray_Rules = INVALID_HANDLE;

void Rules_OnPluginStart()
{
	gH_Cvar_RulesOn = AutoExecConfig_CreateConVar("sm_hosties_rules_enable", "1", "Enable or disable rules showing up at !rules command (if you need to disable the command registration on plugin startup, add a file in your sourcemod/configs/ named hosties_rulesdisable.ini with any content): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	
	gH_Cvar_Announce_Rules = AutoExecConfig_CreateConVar("sm_hosties_announce_rules", "1", "Enable or disable rule announcements in the beginning of every round ('please follow the rules listed in !rules'): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	
	gH_Cvar_Rules_Mode = AutoExecConfig_CreateConVar("sm_hosties_rules_mode", "1", "1 - Panel Mode, 2 - Website", 0, true, 1.0, true, 2.0);
	
	gH_Cvar_Rules_Website = AutoExecConfig_CreateConVar("sm_hosties_rules_website", "http://www.youtube.com/watch?v=oHg5SJYRHA0", "The website for the rules page.", 0);
	gH_Cvar_Rules_Website.GetString(gShadow_Rules_Website, sizeof(gShadow_Rules_Website));
	
	HookEvent("round_start", Rules_RoundStart);
	
	// Provided for backwards comparibility
	char file[256];
	BuildPath(Path_SM, file, 255, "configs/hosties_rulesdisable.ini");
	Handle fileh = OpenFile(file, "r");
	if (fileh == null)
	{
		RegConsoleCmd("sm_rules", Command_Rules);
	}
	gH_DArray_Rules = CreateArray(255);
}

public Action Rules_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (gH_Cvar_Announce_Rules.BoolValue)
	{
		LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Please Follow Rules");
	}
}

void Rules_OnConfigsExecuted()
{
	gH_Cvar_Rules_Website.GetString(gShadow_Rules_Website, sizeof(gShadow_Rules_Website));
	
	ParseTheRulesFile();
}

void ParseTheRulesFile()
{
	ClearArray(gH_DArray_Rules);
	
	char pathRules[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, pathRules, sizeof(pathRules), "configs/hosties_rules.ini");
	Handle rulesFile = OpenFile(pathRules, "r");
	
	if (rulesFile != null)
	{
		char sRulesLine[256];
		
		while(ReadFileLine(rulesFile, sRulesLine, sizeof(sRulesLine)))
		{
			PushArrayString(gH_DArray_Rules, sRulesLine);
		}
	}
}

public Action Command_Rules(int client, int args)
{
	if (gH_Cvar_RulesOn.BoolValue)
	{
		switch (gH_Cvar_Rules_Mode.IntValue)
		{
			case 1:
			{
				int iNumOfRules = GetArraySize(gH_DArray_Rules);
				
				if (iNumOfRules > 0)
				{
					char sPanelText[256];
					Format(sPanelText, sizeof(sPanelText), "%t", "Server Rules");
					
					Menu menu = CreateMenu(MenuRule);
					menu.SetTitle(sPanelText);
					menu.AddItem("spacer", " ", ITEMDRAW_RAWLINE);	
					
					for (int line = 0; line < iNumOfRules; line++)
					{
						GetArrayString(gH_DArray_Rules, line, sPanelText, sizeof(sPanelText));
						menu.AddItem("rule", sPanelText, ITEMDRAW_DISABLED);
					}					
					menu.Display(client, MENU_TIME_FOREVER);
				}
			}
			case 2:
			{
				ShowMOTDPanel(client, "Rules", gShadow_Rules_Website, MOTDPANEL_TYPE_URL);
			}
		}
	}

	return Plugin_Handled;
}

public int MenuRule(Menu menu, MenuAction action, int client, int itemNum)
{
	// regardless of what the MenuAction is, do nothing
}
