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
 
#include		<sourcemod>
#include		<sdktools>
#include		<cstrike>
#include		<adminmenu>
#include		<sdkhooks>
#include		<emitsoundany>
#include		<hosties>
#include		<autoexecconfig>
#include		<multicolors>
#include		<smlib>
#include		<emperor>

#undef 			REQUIRE_PLUGIN
#undef 			REQUIRE_EXTENSIONS
#tryinclude		<SteamWorks>
#tryinclude		<sourcebanspp>
#tryinclude		<myjailbreak>
#tryinclude		<wardenmenu>
#define 		REQUIRE_EXTENSIONS
#define 		REQUIRE_PLUGIN

#pragma			semicolon 					1

#define 		PLUGIN_VERSION				"4.2.44b"
#define 		PLUGIN_NAME					"ENT_Hosties(V4.2.3b)"
#define 		MAX_DISPLAYNAME_SIZE		64
#define 		MAX_DATAENTRY_SIZE			5
#define 		SERVERTAG					"ENT_Hosties,LR,LastRequest"

// Note: you cannot safely turn these modules on and off yet. Use cvars to disable functionality.

// Add ability to disable collisions for players
#define	MODULE_NOBLOCK						1
// Add anti-healing check for LRs
#define	MODULE_ANTIHEAL						1
// Add the last request system
#define	MODULE_LASTREQUEST					1
// Add a game description override
#define	MODULE_GAMEDESCRIPTION				1
// Add start weapons for both teams
#define	MODULE_STARTWEAPONS					1
// Add round-end team overlays
#define	MODULE_TEAMOVERLAYS					1
// Add !rules command
#define	MODULE_RULES						1
// Add !checkplayers command
#define	MODULE_CHECKPLAYERS					1
// Add muting system
#define	MODULE_MUTE							1
// Add freekill detection and prevention
#define	MODULE_FREEKILL						1
// Add gun safety
#define	MODULE_GUNSAFETY					1
// Add intelli-respawn
#define	MODULE_RESPAWN						1
// Fix MyJailbreak value sets
#define	MODULE_FIXJB						1

/******************************************************************************
                   !EDIT BELOW THIS COMMENT AT YOUR OWN PERIL!
******************************************************************************/

// Global vars
char			gShadow_Hosties_ChatBanner[256],
				gShadow_Hosties_LogFile[PLATFORM_MAX_PATH];

bool			g_bSBAvailable		=		false,
				g_bMYJB				=		false,
				g_bBW				=		false;
		
int				g_Game				=		Game_Unknown;

Handle			gH_TopMenu			=		INVALID_HANDLE,
				gH_GameVar_CT_Name	=		INVALID_HANDLE,
				gH_GameVar_T_Name	=		INVALID_HANDLE;
TopMenuObject 	gM_Hosties			=		INVALID_TOPMENUOBJECT;

ConVar 			gH_Cvar_Add_ServerTag,
				gH_Cvar_Display_Advert,
				gH_Cvar_ChatTag,
				gH_Cvar_CT_Name,
				gH_Cvar_T_Name,
				gH_Cvar_LR_Debug_Enabled;

#if (MODULE_FREEKILL == 1)
ConVar			gH_Cvar_Freekill_Sound,
				gH_Cvar_Freekill_Threshold,
				gH_Cvar_Freekill_Notify,
				gH_Cvar_Freekill_BanLength,
				gH_Cvar_Freekill_Punishment,
				gH_Cvar_Freekill_Reset;

char			gShadow_Freekill_Sound[PLATFORM_MAX_PATH];

int				gA_FreekillsOfCT[MAXPLAYERS+1],
				gShadow_Freekill_Punishment;
#endif

#if (MODULE_ANTIHEAL == 1)
#include		"hosties/antiheal.sp"
#endif
#if (MODULE_NOBLOCK == 1)
#include 		"hosties/noblock.sp"
#endif
#if (MODULE_LASTREQUEST == 1)
#include 		"hosties/lastrequest.sp"
#endif
#if (MODULE_GAMEDESCRIPTION == 1)
#include 		"hosties/gamedescription.sp"
#endif
#if (MODULE_STARTWEAPONS == 1)
#include 		"hosties/startweapons.sp"
#endif
#if (MODULE_TEAMOVERLAYS == 1)
#include 		"hosties/teamoverlays.sp"
#endif
#if (MODULE_RULES == 1)
#include 		"hosties/rules.sp"
#endif
#if (MODULE_CHECKPLAYERS == 1)
#include 		"hosties/checkplayers.sp"
#endif
#if (MODULE_MUTE == 1)
#include 		"hosties/muteprisoners.sp"
#endif
#if (MODULE_FREEKILL == 1)
#include		 "hosties/freekillers.sp"
#endif
#if (MODULE_GUNSAFETY == 1)
#include 		"hosties/gunsafety.sp"
#endif
#if (MODULE_RESPAWN == 1)
#include 		"hosties/respawn.sp"
#endif
#if (MODULE_FIXJB == 1)
#include		 "hosties/myjailbreak_fixvalue.sp"
#endif

public Plugin myinfo =
{
	name     	  	=		PLUGIN_NAME,
	author    	 	=		"databomb & Entity",
	description 	= 		"SM_Hosties Remake",
	version    		=		PLUGIN_VERSION,
};

public void OnPluginStart()
{
	// Load translations
	LoadTranslations("common.phrases");
	LoadTranslations("hosties.phrases");

	// Events hooks
	HookEvent("round_start", Event_RoundStart);
	
	EMP_DirExistsEx("cfg/sourcemod/Hosties");

	// Create ConVars
	AutoExecConfig_SetFile("Hosties_Settings", "sourcemod/Hosties");
	AutoExecConfig_SetCreateFile(true);
	
	gH_Cvar_Add_ServerTag		= 	AutoExecConfig_CreateConVar("sm_hosties_add_servertag", "1", "Enable or disable automatic adding of SM_Hosties in sv_tags (visible from the server browser in CS:S): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Display_Advert		= 	AutoExecConfig_CreateConVar("sm_hosties_display_advert", "1", "Enable or disable the display of the Powered by SM Hosties message at the start of each round.", 0, true, 0.0, true, 1.0);
	gH_Cvar_ChatTag				= 	AutoExecConfig_CreateConVar("sm_hosties_chat_banner", "{darkblue}[{lightblue}Hosties{darkblue}]", "Edit ChatTag for ENT_Hosties (Colors can be used).");
	gH_Cvar_LR_Debug_Enabled 	= 	AutoExecConfig_CreateConVar("sm_hosties_debug_enabled", "0", "Allow prisoners to set race points in the air.", 0, true, 0.0, true, 1.0);
	gH_Cvar_CT_Name 			= 	AutoExecConfig_CreateConVar("sm_hosties_team_name_ct", "Guards", "Edit CT Team Name - Leave empty for no change");
	gH_Cvar_T_Name 				= 	AutoExecConfig_CreateConVar("sm_hosties_team_name_t", "Prisoners", "Edit T Team Name - Leave empty for no change");
	
	#if (MODULE_STARTWEAPONS == 1)
		StartWeapons_OnPluginStart();
	#endif
	#if (MODULE_NOBLOCK == 1)
		NoBlock_OnPluginStart();
	#endif
	#if (MODULE_CHECKPLAYERS == 1)
		CheckPlayers_OnPluginStart();
	#endif
	#if (MODULE_RULES == 1)
		Rules_OnPluginStart();
	#endif
	#if (MODULE_GAMEDESCRIPTION == 1)
		GameDescription_OnPluginStart();
	#endif
	#if (MODULE_TEAMOVERLAYS == 1)
		TeamOverlays_OnPluginStart();
	#endif
	#if (MODULE_MUTE == 1)
		MutePrisoners_OnPluginStart();
	#endif
	#if (MODULE_FREEKILL == 1)
		Freekillers_OnPluginStart();
	#endif
	#if (MODULE_GUNSAFETY == 1)
		GunSafety_OnPluginStart();
	#endif
	#if (MODULE_RESPAWN == 1)
		Respawn_OnPluginStart();
	#endif
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	AutoExecConfig_SetFile("LastRequest_Settings", "sourcemod/Hosties");
	AutoExecConfig_SetCreateFile(true);
	#if (MODULE_ANTIHEAL == 1)
	Antiheal_OnPluginStart();
	#endif
	#if (MODULE_LASTREQUEST == 1)
	LastRequest_OnPluginStart();
	#endif
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	#if (MODULE_FIXJB == 1)
	FixJB_OnPluginStart();
	#endif
	
	HookConVarChange(gH_Cvar_ChatTag, OnCvarChange_ChatTag);
	
	char Temp[256];
	GetConVarString(gH_Cvar_ChatTag, Temp, sizeof(Temp));
	Format(gShadow_Hosties_ChatBanner, sizeof(gShadow_Hosties_ChatBanner), "%s {lightblue}", Temp);
	
	if (StrContains(gShadow_Hosties_ChatBanner, "{red}") != -1)
		ReplaceString(gShadow_Hosties_ChatBanner, sizeof(gShadow_Hosties_ChatBanner), "{red}", "\x02");	
		
	if (StrContains(gShadow_Hosties_ChatBanner, "{blue}") != -1)
		ReplaceString(gShadow_Hosties_ChatBanner, sizeof(gShadow_Hosties_ChatBanner), "{blue}", "\x0C");	
	
	AutoExecConfig_CreateConVar("sm_hosties_version", PLUGIN_VERSION, "SM_Hosties plugin version (unchangeable)", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_hostiesadmin", Command_HostiesAdmin, ADMFLAG_SLAY);
	
	BuildPath(Path_SM, Temp, sizeof(Temp), "logs/Entity");
	EMP_DirExistsEx(Temp);
	
	gH_GameVar_CT_Name = FindConVar("mp_teamname_1");
	gH_GameVar_T_Name = FindConVar("mp_teamname_2");
	
	EMP_SetLogFile(gShadow_Hosties_LogFile, "Hosties-Logs", "Entity");
	if (gH_Cvar_LR_Debug_Enabled.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Hosties Successfully started.");
}

public void OnMapStart()
{
	#if (MODULE_TEAMOVERLAYS == 1)
	TeamOverlays_OnMapStart();
	#endif
	#if (MODULE_LASTREQUEST == 1)
	LastRequest_OnMapStart();
	#endif
	
	char Temp[256];
	GetConVarString(gH_Cvar_CT_Name, Temp, sizeof(Temp));
	if (!StrEqual(Temp, "") && gH_GameVar_CT_Name != INVALID_HANDLE)
		SetConVarString(gH_GameVar_CT_Name, Temp, true, false);
		
	GetConVarString(gH_Cvar_T_Name, Temp, sizeof(Temp));
	if (!StrEqual(Temp, "") && gH_GameVar_T_Name != INVALID_HANDLE)
		SetConVarString(gH_GameVar_T_Name, Temp, true, false);
}

public void OnMapEnd()
{
	#if (MODULE_FREEKILL == 1)	
	Freekillers_OnMapEnd();
	#endif
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
		g_bSBAvailable = true;
	
	Handle h_TopMenu = GetAdminTopMenu();
	if (LibraryExists("adminmenu") && (h_TopMenu != INVALID_HANDLE))
		OnAdminMenuReady(h_TopMenu);
	
	if (LibraryExists("myjailbreak"))
		g_bMYJB = true;
	
	if (LibraryExists("wardenmenu"))
		g_bBW = true;
	
	#if (MODULE_MUTE == 1)
	MutePrisoners_AllPluginsLoaded();
	#endif
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_CSS)
		g_Game = Game_CSS;
	else if (GetEngineVersion() == Engine_CSGO)
		g_Game = Game_CSGO;
	else
		SetFailState("Game is not supported.");

	MarkNativeAsOptional("MyJailbreak_IsEventDayRunning");
	MarkNativeAsOptional("IsEventDayActive");
	MarkNativeAsOptional("SteamWorks_SetGameDescription");

	LastRequest_APL();
	
	RegPluginLibrary("hosties");
	
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "sourcebans"))
		g_bSBAvailable = true;
	else if (StrEqual(name, "adminmenu") && (GetAdminTopMenu() != INVALID_HANDLE))
		OnAdminMenuReady(GetAdminTopMenu());
	else if (StrEqual(name, "myjailbreak"))
		g_bMYJB = true;
	else if (StrEqual(name, "wardenmenu"))
		g_bBW = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "sourcebans"))
		g_bSBAvailable = false;
	else if (StrEqual(name, "adminmenu"))
		gH_TopMenu = GetAdminTopMenu();
	else if (StrEqual(name, "myjailbreak"))
		g_bMYJB = false;
	else if (StrEqual(name, "wardenmenu"))
		g_bBW = false;
}

public void OnConfigsExecuted()
{
	if (gH_Cvar_Add_ServerTag.BoolValue)
	{
		ConVar hTags = FindConVar("sv_tags");
		char sTags[512], sTagsFormat[128];
		hTags.GetString(sTags, sizeof(sTags));
		
		char gShadow_TagList[16][32];
		int TagCount = ExplodeString(SERVERTAG, ",", gShadow_TagList, sizeof(gShadow_TagList), sizeof(gShadow_TagList[]));
		for (int Tidx = 0; Tidx < TagCount; Tidx++)
		{
			if (StrContains(sTags, gShadow_TagList[Tidx], false) == -1)
			{
				Format(sTagsFormat, sizeof(sTagsFormat), ",%s", gShadow_TagList[Tidx]);
			}
		}
		StrCat(sTags, sizeof(sTags), sTagsFormat);
		
		int Def_Flags = hTags.Flags;
		hTags.Flags &= ~FCVAR_NOTIFY;
		hTags.SetString(sTags, true, false);
		hTags.Flags = Def_Flags;
		delete hTags;
	}
	
	#if (MODULE_FREEKILL == 1)
	Freekillers_OnConfigsExecuted();
	#endif
	#if (MODULE_MUTE == 1)
	MutePrisoners_OnConfigsExecuted();
	#endif
	#if (MODULE_GAMEDESCRIPTION == 1)
	GameDesc_OnConfigsExecuted();
	#endif
	#if (MODULE_TEAMOVERLAYS == 1)
	TeamOverlays_OnConfigsExecuted();
	#endif
	#if (MODULE_RULES == 1)
	Rules_OnConfigsExecuted();
	#endif
	#if (MODULE_LASTREQUEST == 1)
	LastRequest_OnConfigsExecuted();
	#endif
	#if (MODULE_STARTWEAPONS == 1)
	StartWeapons_OnConfigsExecuted();
	#endif
	#if (MODULE_FIXJB == 1)
	FixJB_OnConfigsExecuted();
	#endif
	
	char g_sCommands[8][32], commands[128];
	gH_Cvar_LR_Aliases.GetString(commands, sizeof(commands));
	
	int g_iCommandCount = ExplodeString(commands, ",", g_sCommands, sizeof(g_sCommands), sizeof(g_sCommands[]));
	
	for (int i = 0; i < g_iCommandCount; i++)
	{
		String_Trim(g_sCommands[i], g_sCommands[i], 32);
		
		if(!CommandExists(g_sCommands[i]))
			RegConsoleCmd(g_sCommands[i], Command_LastRequest);
	}
	
	char Temp[256];
	GetConVarString(gH_Cvar_CT_Name, Temp, sizeof(Temp));
	if (!StrEqual(Temp, "") && gH_GameVar_CT_Name != INVALID_HANDLE)
		SetConVarString(gH_GameVar_CT_Name, Temp, true, false);
		
	GetConVarString(gH_Cvar_T_Name, Temp, sizeof(Temp));
	if (!StrEqual(Temp, "") && gH_GameVar_T_Name != INVALID_HANDLE)
		SetConVarString(gH_GameVar_T_Name, Temp, true, false);
}

public void OnClientPutInServer(int client)
{
	#if (MODULE_LASTREQUEST == 1)
	LastRequest_ClientPutInServer(client);
	#endif
	#if (MODULE_FREEKILL == 1)
	Freekillers_ClientPutInServer(client);
	#endif
}

public Action Event_RoundStart(Event event, const char[] name , bool dontBroadcast)
{
	if (gH_Cvar_Display_Advert.BoolValue)
		LOOP_CLIENTS(TargetForLang, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAMEAUTH) CPrintToChat(TargetForLang, "%s %t", gShadow_Hosties_ChatBanner, "Powered By Hosties");
}

public void OnAdminMenuReady(Handle h_TopMenu)
{
	// block double calls
	if (h_TopMenu == gH_TopMenu)
		return;
	
	gH_TopMenu = h_TopMenu;
	
	// Build Hosties menu
	gM_Hosties = AddToTopMenu(gH_TopMenu, "Hosties", TopMenuObject_Category, HostiesCategoryHandler, INVALID_TOPMENUOBJECT);
	
	if (gM_Hosties == INVALID_TOPMENUOBJECT)
		return;
	
	// Let other modules add menu objects
	#if (MODULE_LASTREQUEST == 1)
	LastRequest_Menus(gH_TopMenu, gM_Hosties);
	#endif
	#if (MODULE_GUNSAFETY == 1)
	GunSafety_Menus(gH_TopMenu, gM_Hosties);
	#endif
	#if (MODULE_RESPAWN == 1)
	Respawn_Menus(gH_TopMenu, gM_Hosties);
	#endif
}

public void OnCvarChange_ChatTag(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	Format(gShadow_Hosties_ChatBanner, sizeof(gShadow_Hosties_ChatBanner), "%s {lightblue}", newvalue);
	
	if (StrEqual(gShadow_Hosties_ChatBanner, "{red}"))
		ReplaceString(gShadow_Hosties_ChatBanner, sizeof(gShadow_Hosties_ChatBanner), "{red}", "\x02");	
		
	if (StrEqual(gShadow_Hosties_ChatBanner, "{blue}"))
		ReplaceString(gShadow_Hosties_ChatBanner, sizeof(gShadow_Hosties_ChatBanner), "{blue}", "\x0C");	
}

public Action Command_HostiesAdmin(int client, int args)
{
	DisplayTopMenu(gH_TopMenu, client, TopMenuPosition_LastRoot);
	return Plugin_Handled;
}

public void HostiesCategoryHandler(Handle topmenu, TopMenuAction action, TopMenuObject item, int param, char[] buffer, int maxlength)
{
	switch (action)
	{
		case (TopMenuAction_DisplayTitle):
		{
			if (item == gM_Hosties)
			{
				Format(buffer, maxlength, "Hosties:");
			}
		}
		case (TopMenuAction_DisplayOption):
		{
			if (item == gM_Hosties)
			{
				Format(buffer, maxlength, "Hosties");
			}
		}
	}
}

stock void SetLogFile(char path[PLATFORM_MAX_PATH], char[] file, char[] folder)
{
	char LogDate[12];
	FormatTime(LogDate, sizeof(LogDate), "%y-%m-%d");
	Format(path, sizeof(path), "logs/%s/%s-%s.log", folder, file, LogDate);

	BuildPath(Path_SM, path, sizeof(path), path);
}

stock bool DirExistsEx(const char[] path)
{
	if (!DirExists(path))
	{
		CreateDirectory(path, 511);

		if (!DirExists(path))
		{
			LogError("Couldn't create folder! (%s)", path);
			return false;
		}
	}

	return true;
}