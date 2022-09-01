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
 
#if defined _HostiesRestore_Included_
	#endinput
#endif
#define _HostiesRestore_
#define	FlashbangOffsetForHC	15

public char C_sWeapon[MAXPLAYERS + 1][11][64]; 
public int C_WeaponCount[MAXPLAYERS + 1] = 0;
public int C_FlashCounter[MAXPLAYERS + 1] = 0;

/**
* Checks several parameters to see if the specified client is a valid user.
*
* @param client index
* @param Allow bots?
* @param Allow dead?
* @return true if valid
*/
stock bool IsValidClient(int client)
{
	if((1 <= client <= MaxClients) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}

/**
* Strip all weapons from the aimed target and save them
*
* @param aimed client
*/
stock void SaveWeapons(int target)
{
	C_FlashCounter[target] = 0;
	int counter = 0;
	
	C_FlashCounter[target] = GetEntProp(target, Prop_Data, "m_iAmmo", _, FlashbangOffsetForHC);
	C_WeaponCount[target] = Client_GetWeaponCount(target);
	int temp_count = C_WeaponCount[target];
	if (IsValidClient(target))
	{
		for (int g = C_WeaponCount[target]; g != 0; g--)
		{
			int temp_weapon = Client_GetActiveWeapon(target);
			if (Weapon_IsValid(temp_weapon))
			{
				char temp_weapon_name[64];
				SetWeaponClassname(temp_weapon, temp_weapon_name, sizeof(temp_weapon_name));
				
				Client_DetachWeapon(target, temp_weapon);
				C_sWeapon[target][counter] = temp_weapon_name;
				
				counter++; temp_count--;
			}
		}
	}
}

/**
* Restore Saved Weapons of the aimed target
*
* @param aimed client
*/
stock void RestoreWeapons(int aimed)
{
	if (IsValidClient(aimed))
	{
		int weapon;
		while((weapon = GetPlayerWeaponSlot(aimed, CS_SLOT_KNIFE)) != -1)
		{
			if (Weapon_IsValid(weapon))
			{
				RemovePlayerItem(aimed, weapon);
				AcceptEntityInput(weapon, "Kill");
			}
		}
	
		for (int g = 0; g <= C_WeaponCount[aimed]; g++)
		{
			if (StrEqual(C_sWeapon[aimed][g], "weapon_flashbang"))
			{
				for (int x = 1; x <= C_FlashCounter[aimed]; x++)
				{
					GivePlayerItem(aimed, C_sWeapon[aimed][g]);
				}
			}
			else
			{
				int wep = GivePlayerItem(aimed, C_sWeapon[aimed][g]);
				if (Weapon_IsValid(wep))
				{
					int Check = Client_GetWeaponPlayerAmmo(aimed, C_sWeapon[aimed][g]);
					if (Check == 0)
					{
						EquipPlayerWeapon(aimed, wep);
					}
				}
			}
		}
	}
}

/**
* Sets the ClassName of a weapon
*
* @param Weapon entity
* @param buffer
* @param size
*/
stock void SetWeaponClassname(int weapon, char[] buffer, int size) 
{ 
	if (Weapon_IsValid(weapon))
	{
		switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) 
		{ 
			case 23: Format(buffer, size, "weapon_mp5sd"); 
			case 60: Format(buffer, size, "weapon_m4a1_silencer"); 
			case 61: Format(buffer, size, "weapon_usp_silencer"); 
			case 63: Format(buffer, size, "weapon_cz75a"); 
			case 64: Format(buffer, size, "weapon_revolver"); 
			default: GetEntityClassname(weapon, buffer, size); 
		}
	}
}