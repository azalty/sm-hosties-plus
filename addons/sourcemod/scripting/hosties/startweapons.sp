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
#include <multicolors>
#include <smlib>


Handle 	gH_Cvar_StartWeaponsOn = INVALID_HANDLE,
		gH_Cvar_T_Weapons = INVALID_HANDLE,
		gH_Cvar_CT_Weapons = INVALID_HANDLE;
		
bool 	gShadow_StartWeaponsOn;

char 	gShadow_T_Weapons[256],
		gShadow_CT_Weapons[256],
		gs_T_WeaponList[8][32],
		gs_CT_WeaponList[8][32];
		
int 	g_iSizeOfTList,
		g_iSizeOfCTList;

void StartWeapons_OnPluginStart()
{
	gH_Cvar_StartWeaponsOn = AutoExecConfig_CreateConVar("sm_hosties_startweapons_on", "1", "Enable or disable configurable payloads for each time on player spawn", 0, true, 0.0, true, 1.0);
	gShadow_StartWeaponsOn = true;
	gH_Cvar_T_Weapons = AutoExecConfig_CreateConVar("sm_hosties_t_start", "weapon_knife", "Comma delimitted list of items to give to Ts at spawn", 0);
	Format(gShadow_T_Weapons, sizeof(gShadow_T_Weapons), "weapon_knife");
	if (g_Game == Game_CSS)
	{
		gH_Cvar_CT_Weapons = AutoExecConfig_CreateConVar("sm_hosties_ct_start", "weapon_knife,weapon_m4a1,weapon_usp", "Comma delimitted list of items to give to CTs at spawn", 0);
		Format(gShadow_CT_Weapons, sizeof(gShadow_CT_Weapons), "weapon_knife,weapon_m4a1,weapon_usp");
	}
	else if (g_Game == Game_CSGO)
	{
		gH_Cvar_CT_Weapons = AutoExecConfig_CreateConVar("sm_hosties_ct_start", "weapon_knife,weapon_m4a1,weapon_hkp2000", "Comma delimitted list of items to give to CTs at spawn", 0);
		Format(gShadow_CT_Weapons, sizeof(gShadow_CT_Weapons), "weapon_knife,weapon_m4a1,weapon_hkp2000");
	}
	UpdateStartWeapons();	
	
	HookEvent("player_spawn", StartWeapons_Spawn);
	
	HookConVarChange(gH_Cvar_StartWeaponsOn, StartWeapons_CvarChanged);
	HookConVarChange(gH_Cvar_T_Weapons, StartWeapons_CvarChanged);
	HookConVarChange(gH_Cvar_CT_Weapons, StartWeapons_CvarChanged);
}

void StartWeapons_OnConfigsExecuted()
{
	GetConVarString(gH_Cvar_CT_Weapons, gShadow_CT_Weapons, sizeof(gShadow_CT_Weapons));
	GetConVarString(gH_Cvar_T_Weapons, gShadow_T_Weapons, sizeof(gShadow_T_Weapons));
	gShadow_StartWeaponsOn = GetConVarBool(gH_Cvar_StartWeaponsOn);
	UpdateStartWeapons();
}

public Action StartWeapons_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (gShadow_StartWeaponsOn && EMP_IsValidClient(client))
	{
		Client_RemoveAllWeapons(client);

		int team = GetClientTeam(client);
		switch (team)
		{
			case CS_TEAM_T:
			{
				for (int Tidx = 0; Tidx < g_iSizeOfTList; Tidx++)
				{
					if (!Client_HasWeapon(client, gs_T_WeaponList[Tidx]))
						EMP_GiveWeapon(client, gs_T_WeaponList[Tidx]);
				}
			}
			case CS_TEAM_CT:
			{
				for (int CTidx = 0; CTidx < g_iSizeOfCTList; CTidx++)
				{
					char sWeapon[64];
					
					if(g_Game == Game_CSGO && strcmp(gs_CT_WeaponList[CTidx], "weapon_usp", false) == 0)
					{
						Format(sWeapon, sizeof(sWeapon), "weapon_hkp2000");
					}
					else
					{
						Format(sWeapon, sizeof(sWeapon), gs_CT_WeaponList[CTidx]);
					}

					if (!Client_HasWeapon(client, sWeapon))
						EMP_GiveWeapon(client, sWeapon);
				}
			}
		}
		
		if (gH_Cvar_LR_Fists_Instead_Knife.BoolValue)
		{
			int weapon;
			while((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1)
			{
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
			}
			
			EMP_EquipWeapon(client, "weapon_fists");
		}
		else if (GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == -1)
		{
			EMP_EquipWeapon(client, "weapon_knife");
		}
	}
}

public void StartWeapons_CvarChanged(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == gH_Cvar_StartWeaponsOn)
	{
		gShadow_StartWeaponsOn = view_as<bool>(StringToInt(newValue));
	}
	else if (cvar == gH_Cvar_T_Weapons)
	{
		Format(gShadow_T_Weapons, sizeof(gShadow_T_Weapons), newValue);
		UpdateStartWeapons();
	}
	else if (cvar == gH_Cvar_CT_Weapons)
	{
		Format(gShadow_CT_Weapons, sizeof(gShadow_CT_Weapons), newValue);
		UpdateStartWeapons();
	}
}

void UpdateStartWeapons()
{
	g_iSizeOfTList = ExplodeString(gShadow_T_Weapons, ",", gs_T_WeaponList, sizeof(gs_T_WeaponList), sizeof(gs_T_WeaponList[]));
	g_iSizeOfCTList = ExplodeString(gShadow_CT_Weapons, ",", gs_CT_WeaponList, sizeof(gs_CT_WeaponList), sizeof(gs_CT_WeaponList[]));
}

