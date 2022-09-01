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
#include <steamworks>

ConVar 	gH_Cvar_GameDescriptionOn,
		gH_Cvar_GameDescriptionTag;
char 	gShadow_GameDescriptionTag[64];
bool 	g_bSTAvailable = false; // SteamTools

void GameDescription_OnPluginStart()
{
	gH_Cvar_GameDescriptionOn 	= AutoExecConfig_CreateConVar("sm_hosties_override_gamedesc", "1", "Enable or disable an override of the game description (standard Counter-Strike: Source, override to Hosties/jailbreak): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_GameDescriptionTag 	= AutoExecConfig_CreateConVar("sm_hosties_gamedesc_tag", "ENT Hosties/Jailbreak v3", "Sets the game description tag.", 0);
	gH_Cvar_GameDescriptionTag.GetString(gShadow_GameDescriptionTag, sizeof(gShadow_GameDescriptionTag));
	
	// check for SteamTools
	if (GetFeatureStatus(FeatureType_Native, "SteamWorks_SetGameDescription") == FeatureStatus_Available)
	{
		g_bSTAvailable = true;
	}
}

void GameDesc_OnConfigsExecuted()
{
	gH_Cvar_GameDescriptionTag.GetString(gShadow_GameDescriptionTag, sizeof(gShadow_GameDescriptionTag));
	
	if (gH_Cvar_GameDescriptionOn.BoolValue && g_bSTAvailable)
	{
		SteamWorks_SetGameDescription(gShadow_GameDescriptionTag);
	}
}
