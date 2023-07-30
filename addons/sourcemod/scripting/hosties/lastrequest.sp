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

#define FlashbangOffset         				12
#define MAX_BUTTONS								25
#define IN_ATTACK2								(1 << 11)
 
// Include files
#include										<sourcemod>
#include										<sdktools>
#include										<cstrike>
#include										<sdkhooks>
#include										<sdktools>
#include										<hosties>
#include										<lastrequest>
#include										<multicolors>

// Compiler options
#pragma semicolon 1

// Global variables
#define BASE_LR_Number LR_Number

int 	g_LastButtons[MAXPLAYERS+1],
		SuitSetBack,
		g_RoundTime,
		g_LR_PermissionLookup[MAXPLAYERS+1],
		BeamSprite 								= -1,
		HaloSprite 								= -1,
		LaserSprite 							= -1,
		LaserHalo 								= -1,
		greenColor[] 							= {15, 255, 15, 255},
		redColor[] 								= {255, 25, 15, 255},
		blueColor[] 							= {50, 75, 255, 255},
		greyColor[] 							= {128, 128, 128, 255},
		yellowColor[] 							= {255, 255, 0, 255},
		g_Offset_Armor 							= -1,
		g_Offset_Clip1 							= -1,
		g_Offset_Ammo 							= -1,
		g_Offset_FOV 							= -1,
		g_Offset_ActiveWeapon 					= -1,
		g_Offset_GroundEnt 						= -1,
		g_Offset_DefFOV 						= -1,
		g_Offset_PunchAngle 					= -1, 
		g_Offset_SecAttack 						= -1,
		g_iLastCT_FreeAttacker 					= -1,
		g_LR_Player_Guard[MAXPLAYERS + 1]	 	= {0, ...};
		
		
bool	g_TriedToStab[MAXPLAYERS+1]				= {false, ...},
		g_bPushedToMenu 						= false,
		LR_Player_Jumped[MAXPLAYERS+1] 			= {false, ...},
		LR_Player_Landed[MAXPLAYERS+1] 			= {false, ...},
		BlockLR 								= false,
		LR_Player_OnCD[MAXPLAYERS+1] 			= {false, ...},
		g_bIsLRAvailable 						= true,
		g_bRoundInProgress						= true,
		g_bListenersAdded 						= false,
		g_bAnnouncedThisRound 					= false,
		g_bInLastRequest[MAXPLAYERS+1],
		g_bIsARebel[MAXPLAYERS+1];
		
char 	LR_C_sWeapon[MAXPLAYERS + 1][11][64];
int 	LR_C_WeaponCount[MAXPLAYERS + 1] = {0, ...};
int 	LR_C_FlashCounter[MAXPLAYERS + 1] = {0, ...};

char	BeforeModel[MAXPLAYERS+1][PLATFORM_MAX_PATH+1],
		g_sLastRequestPhrase[BASE_LR_Number][MAX_DISPLAYNAME_SIZE];

ConVar	g_hRoundTime,
		Cvar_TeamBlock,
		g_cvSvSuit,
		g_cvGraceTime,
		g_cvFreezeTime,
		gH_Cvar_LR_Aliases,
		gH_Cvar_LR_KnifeFight_On,
		gH_Cvar_LR_Shot4Shot_On,
		gH_Cvar_LR_GunToss_On,
		gH_Cvar_LR_ChickenFight_On,
		gH_Cvar_LR_HotPotato_On,
		gH_Cvar_LR_Dodgeball_On,
		gH_Cvar_LR_NoScope_On,
		gH_Cvar_LR_RockPaperScissors_On,
		gH_Cvar_LR_Rebel_On,
		gH_Cvar_LR_Mag4Mag_On,
		gH_Cvar_LR_Race_On,
		gH_Cvar_LR_RussianRoulette_On,
		gH_Cvar_LR_JumpContest_On,
		gH_Cvar_LR_ShieldFight_On,
		gH_Cvar_LR_FistFight_On,
		gH_Cvar_LR_JuggernoutBattle_On,
		gH_Cvar_LR_OnlyHS_On,
		gH_Cvar_LR_HEFight_On,
		gH_Cvar_Announce_Delay_Enable,
		gH_Cvar_LR_HotPotato_Mode,
		gH_Cvar_MaxPrisonersToLR,
		gH_Cvar_CheatAction,
		gH_Cvar_RebelHandling,
		gH_Cvar_SendGlobalMsgs,
		gH_Cvar_ColorRebels,
		gH_Cvar_LR_Enable,
		gH_Cvar_LR_MenuTime,
		gH_Cvar_LR_KillTimeouts,
		gH_Cvar_ColorRebels_Red,
		gH_Cvar_ColorRebels_Blue,
		gH_Cvar_ColorRebels_Green,
		gH_Cvar_LR_Beacons,
		gH_Cvar_LR_HelpBeams,
		gH_Cvar_LR_HelpBeams_Distance,
		gH_Cvar_LR_Beacon_Interval,
		gH_Cvar_RebelOnImpact,
		gH_Cvar_LR_ChickenFight_Slay,
		gH_Cvar_LR_ChickenFight_C_Blue,
		gH_Cvar_LR_ChickenFight_C_Red,
		gH_Cvar_LR_ChickenFight_C_Green,
		gH_Cvar_LR_Dodgeball_CheatCheck,
		gH_Cvar_LR_Dodgeball_SpawnTime,
		gH_Cvar_LR_Dodgeball_Gravity,
		gH_Cvar_LR_HotPotato_MaxTime,
		gH_Cvar_LR_HotPotato_MinTime,
		gH_Cvar_LR_HotPotato_Speed,
		gH_Cvar_LR_NoScope_Sound,
		gH_Cvar_LR_Sound,
		gH_Cvar_LR_NoScope_Weapon,
		gH_Cvar_LR_S4S_DoubleShot,
		gH_Cvar_LR_GunToss_Marker,
		gH_Cvar_LR_GunToss_MarkerMode,
		gH_Cvar_LR_GunToss_ShowMeter,
		gH_Cvar_LR_GunToss_SlayOnLose,
		gH_Cvar_LR_Race_AirPoints,
		gH_Cvar_LR_Race_NotifyCTs,
		gH_Cvar_Announce_CT_FreeHit,
		gH_Cvar_Announce_LR,
		gH_Cvar_Announce_Rebel,
		gH_Cvar_Announce_RebelDown,
		gH_Cvar_Announce_Weapon_Attack,
		gH_Cvar_Announce_HotPotato_Eqp,
		gH_Cvar_Announce_Shot4Shot,
		gH_Cvar_LR_NonContKiller_Action,
		gH_Cvar_LR_Delay_Enable_Time,
		gH_Cvar_LR_Damage,
		gH_Cvar_LR_NoScope_Delay,
		gH_Cvar_LR_Rebel_MaxTs,
		gH_Cvar_LR_Rebel_MinCTs,
		gH_Cvar_LR_Rebel_Weapons,
		gH_Cvar_LR_Rebel_HP_per_CT,
		gH_Cvar_LR_Rebel_CT_HP,
		gH_Cvar_LR_M4M_MagCapacity,
		gH_Cvar_LR_KnifeFight_LowGrav,
		gH_Cvar_LR_KnifeFight_HiSpeed,
		gH_Cvar_LR_KnifeFight_Drunk,
		gH_Cvar_LR_Beacon_Sound,
		gH_Cvar_LR_AutoDisplay,
		gH_Cvar_LR_BlockSuicide,
		gH_Cvar_LR_VictorPoints,
		gH_Cvar_LR_RestoreWeapon_T,
		gH_Cvar_LR_RestoreWeapon_CT,
		gH_Cvar_LR_Race_CDOnCancel,
		gH_Cvar_LR_Fists_Instead_Knife,
		gH_Cvar_LR_Ten_Timer;


Handle	RoundTimeTicker						= INVALID_HANDLE,
		TickerState							= INVALID_HANDLE,
		gH_BuildLR[MAXPLAYERS+1]			= {INVALID_HANDLE, ...},
		g_GunTossTimer						= INVALID_HANDLE,
		g_ChickenFightTimer 				= INVALID_HANDLE,
		g_DodgeballTimer 					= INVALID_HANDLE,
		g_BeaconTimer 						= INVALID_HANDLE,
		g_RaceTimer 						= INVALID_HANDLE,
		g_DelayLREnableTimer 				= INVALID_HANDLE,
		g_BeerGogglesTimer 					= INVALID_HANDLE,
		g_CountdownTimer 					= INVALID_HANDLE,
		g_FarthestJumpTimer 				= INVALID_HANDLE,
		gH_Frwd_LR_CleanUp 					= INVALID_HANDLE,
		gH_Frwd_LR_Start 					= INVALID_HANDLE,
		gH_Frwd_LR_Process 					= INVALID_HANDLE,
		gH_Frwd_LR_StartGlobal 				= INVALID_HANDLE,
		gH_Frwd_LR_StopGlobal				= INVALID_HANDLE,
		gH_Frwd_LR_Available 				= INVALID_HANDLE,
		gH_DArray_LastRequests 				= INVALID_HANDLE,
		gH_DArray_LR_Partners 				= INVALID_HANDLE,
		gH_DArray_Beacons 					= INVALID_HANDLE,
		gH_DArray_LR_CustomNames 			= INVALID_HANDLE;
		
		
float	After_Jump_pos[MAXPLAYERS+1][3],
		Before_Jump_pos[MAXPLAYERS+1][3],
		f_DoneDistance[MAXPLAYERS+1];



int			g_LRLookup[MAXPLAYERS+1],
			g_selection[MAXPLAYERS + 1];

// Custom types local to the plugin
#define 	NSW_AWP				1
#define 	NSW_Scout			2
#define 	NSW_SG550			3
#define 	NSW_G3SG1			4

#define 	OHS_AWP				0
#define 	OHS_Deagle			1
#define 	OHS_Fiveseven		2
#define 	OHS_AK				3

#define 	Pistol_Deagle		0
#define 	Pistol_P228			1
#define 	Pistol_Glock		2
#define 	Pistol_FiveSeven	3
#define 	Pistol_Dualies		4
#define 	Pistol_USP			5
#define 	Pistol_Tec9			6
#define 	Pistol_Revolver		7

#define 	Knife_Vintage		0
#define 	Knife_Drunk			1
#define 	Knife_LowGrav		2
#define 	Knife_HiSpeed		3
#define 	Knife_Drugs			4
#define 	Knife_ThirdPerson	5

#define 	SubType_Vintage		0
#define 	SubType_Drunk		1
#define 	SubType_LowGrav		2
#define 	SubType_HiSpeed		3
#define 	SubType_Drugs		4
#define 	SubType_ThirdPerson	5

#define		Jump_TheMost 	 	0
#define		Jump_Farthest		1
#define		Jump_BrinkOfDeath	2

void LastRequest_OnPluginStart()
{
	// Populate translation entries
	// no longer pulling LANG_SERVER
	g_sLastRequestPhrase[LR_KnifeFight]			= "Knife Fight";
	g_sLastRequestPhrase[LR_Shot4Shot] 			= "Shot4Shot";
	g_sLastRequestPhrase[LR_GunToss] 			= "Gun Toss";
	g_sLastRequestPhrase[LR_ChickenFight] 		= "Chicken Fight";
	g_sLastRequestPhrase[LR_HotPotato] 			= "Hot Potato";
	g_sLastRequestPhrase[LR_Dodgeball] 			= "Dodgeball";
	g_sLastRequestPhrase[LR_NoScope] 			= "No Scope Battle";
	g_sLastRequestPhrase[LR_RockPaperScissors] 	= "Rock Paper Scissors";
	g_sLastRequestPhrase[LR_Rebel] 				= "Rebel!";
	g_sLastRequestPhrase[LR_Mag4Mag] 			= "Mag4Mag";
	g_sLastRequestPhrase[LR_Race] 				= "Race";
	g_sLastRequestPhrase[LR_RussianRoulette] 	= "Russian Roulette";
	g_sLastRequestPhrase[LR_JumpContest] 		= "Jumping Contest";
	g_sLastRequestPhrase[LR_ShieldFight] 		= "Shield Fight";
	g_sLastRequestPhrase[LR_FistFight] 			= "Fist Fight";
	g_sLastRequestPhrase[LR_JuggernoutBattle] 	= "Juggernout Battle";
	g_sLastRequestPhrase[LR_OnlyHS] 			= "Only Headshot";
	g_sLastRequestPhrase[LR_HEFight] 			= "Grenade Fight";

	Cvar_TeamBlock = FindConVar("mp_solid_teammates");
	g_hRoundTime = FindConVar("mp_roundtime");
	g_cvSvSuit = FindConVar("mp_weapons_allow_heavyassaultsuit");
	g_cvGraceTime = FindConVar("mp_join_grace_time");
	g_cvFreezeTime = FindConVar("mp_freezetime");

	// Gather all offsets
	g_Offset_Health = FindSendPropInfo("CBasePlayer", "m_iHealth");
	if (g_Offset_Health == -1)
	{
		SetFailState("Unable to find offset for health.");
	}
	g_Offset_Armor = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	if (g_Offset_Armor == -1)
	{
		SetFailState("Unable to find offset for armor.");
	}
	g_Offset_Clip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	if (g_Offset_Clip1 == -1)
	{
		SetFailState("Unable to find offset for clip.");
	}
	if (g_Game != Game_CSGO)
	{
		g_Offset_Ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
		if (g_Offset_Ammo == -1)
		{
			SetFailState("Unable to find offset for ammo.");
		}
	}
	g_Offset_FOV = FindSendPropInfo("CBasePlayer", "m_iFOV");
	if (g_Offset_FOV == -1)
	{
		SetFailState("Unable to find offset for FOV.");
	}
	g_Offset_ActiveWeapon = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	if (g_Offset_ActiveWeapon == -1)
	{
		SetFailState("Unable to find offset for active weapon.");
	}
	g_Offset_GroundEnt = FindSendPropInfo("CBasePlayer", "m_hGroundEntity");
	if (g_Offset_GroundEnt == -1)
	{
		SetFailState("Unable to find offset for ground entity.");
	}
	g_Offset_DefFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
	if (g_Offset_DefFOV == -1)
	{
		SetFailState("Unable to find offset for default FOV.");
	}
	if (g_Game == Game_CSS)
	{
		g_Offset_PunchAngle = FindSendPropInfo("CBasePlayer", "m_vecPunchAngle");
	}
	else if (g_Game == Game_CSGO)
	{
		g_Offset_PunchAngle = FindSendPropInfo("CBasePlayer", "m_aimPunchAngle");
	}
	if (g_Offset_PunchAngle == -1)
	{
		SetFailState("Unable to find offset for punch angle.");
	}
	g_Offset_SecAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	if (g_Offset_SecAttack == -1)
	{
		SetFailState("Unable to find offset for next secondary attack.");
	}
	g_Offset_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if (g_Offset_CollisionGroup == -1)
	{
		SetFailState("Unable to find offset for collision groups.");
	}
	
	// Admin commands
	RegAdminCmd("sm_stoplr", 		Command_CancelLR, ADMFLAG_SLAY);
	RegAdminCmd("sm_cancellr", 		Command_CancelLR, ADMFLAG_SLAY);
	RegAdminCmd("sm_abortlr", 		Command_CancelLR, ADMFLAG_SLAY);
	
	// Events hooks
	HookEvent("round_start", 		LastRequest_RoundStart);
	HookEvent("round_end", 			LastRequest_RoundEnd);
	HookEvent("player_hurt", 		LastRequest_PlayerHurt);
	HookEvent("player_death", 		LastRequest_PlayerDeath);
	HookEvent("bullet_impact", 		LastRequest_BulletImpact);
	HookEvent("player_disconnect", 	LastRequest_PlayerDisconnect);
	HookEvent("weapon_zoom", 		LastRequest_WeaponZoom, EventHookMode_Pre);
	HookEvent("weapon_fire", 		LastRequest_WeaponFire);
	HookEvent("player_jump", 		LastRequest_PlayerJump);
	HookEvent("player_spawn", 		LastRequest_PlayerSpawn);
	
	// Make global arrays
	gH_DArray_LastRequests		=		CreateArray(2);
	gH_DArray_Beacons 			= 		CreateArray();
	gH_DArray_LR_CustomNames	= 		CreateArray(MAX_DISPLAYNAME_SIZE);
	gH_DArray_LR_Partners 		= 		CreateArray(10);
	// array structure:
	// -- block 0 -> LastRequest type
	// -- block 1 -> Prisoner client index
	// -- block 2 -> Guard client index
	// -- block 3 -> LR Data (Prisoner)
	// -- block 4 -> LR Data (Guard)
	// -- block 5 -> LR Data (Global 1)
	// -- block 6 -> LR Data (Global 2)
	// -- block 7 -> LR Data (Global 3)
	// -- block 8 -> LR Data (Global 4)
	// -- block 9 -> Handle to Additional Data
	
	// Create forwards for custom LR plugins
	gH_Frwd_LR_Available 				= CreateGlobalForward("OnAvailableLR", ET_Ignore, Param_Cell);
	gH_Frwd_LR_CleanUp 					= CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	gH_Frwd_LR_Start 					= CreateForward(ET_Ignore, Param_Cell, Param_Cell);
	gH_Frwd_LR_Process 					= CreateForward(ET_Event, Param_Cell, Param_Cell);
	gH_Frwd_LR_StartGlobal 				= CreateGlobalForward("OnStartLR", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	gH_Frwd_LR_StopGlobal 				= CreateGlobalForward("OnStopLR", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	// Register cvars
	gH_Cvar_LR_Enable 					= AutoExecConfig_CreateConVar("sm_hosties_lr", "1", "Enable or disable Last Requests (the !lr command): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Aliases					= AutoExecConfig_CreateConVar("sm_hosties_lr_commands", "sm_lr,sm_lastrequest", "Command aliases to use Lastrequest (Speparate with , and maximum 8 command can be used)", 0);
	gH_Cvar_LR_MenuTime 				= AutoExecConfig_CreateConVar("sm_hosties_lr_menutime", "0", "Sets the time the LR menu is displayed (in seconds)", 0, true, 0.0);
	gH_Cvar_LR_KillTimeouts 			= AutoExecConfig_CreateConVar("sm_hosties_lr_killtimeouts", "0", "Kills Ts who timeout the LR menu and controls whether the exit button is displayed: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_KnifeFight_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_kf_enable", "1", "Enable LR Knife Fight: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Shot4Shot_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_s4s_enable", "1", "Enable LR Shot4Shot: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_GunToss_On 				= AutoExecConfig_CreateConVar("sm_hosties_lr_gt_enable", "1", "Enable LR Gun Toss: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_ChickenFight_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_cf_enable", "1", "Enable LR Chicken Fight: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_HotPotato_On				= AutoExecConfig_CreateConVar("sm_hosties_lr_hp_enable", "1", "Enable LR Hot Potato: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Dodgeball_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_db_enable", "1", "Enable LR Dodgeball: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_NoScope_On				= AutoExecConfig_CreateConVar("sm_hosties_lr_ns_enable", "1", "Enable LR No Scope Battle: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_RockPaperScissors_On 	= AutoExecConfig_CreateConVar("sm_hosties_lr_rps_enable", "1", "Enable LR Rock Paper Scissors: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Rebel_On 				= AutoExecConfig_CreateConVar("sm_hosties_lr_rebel_on", "1", "Enables the LR Rebel: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Mag4Mag_On 				= AutoExecConfig_CreateConVar("sm_hosties_lr_mag4mag_on", "1", "Enables the LR Magazine4Magazine: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Race_On 					= AutoExecConfig_CreateConVar("sm_hosties_lr_race_on", "1", "Enables the LR Race: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_RussianRoulette_On 		= AutoExecConfig_CreateConVar("sm_hosties_lr_russianroulette_on", "1", "Enables the LR Russian Roulette: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_JumpContest_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_jumpcontest_on", "1", "Enables the LR Jumping Contest: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_ShieldFight_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_shieldfight_on", "1", "Enables the LR Shield Fight: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_FistFight_On 			= AutoExecConfig_CreateConVar("sm_hosties_lr_fistfight_on", "1", "Enables the LR Fsit Fight: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_JuggernoutBattle_On 		= AutoExecConfig_CreateConVar("sm_hosties_lr_juggernout_on", "1", "Enables the LR Juggernout Battle: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_OnlyHS_On 				= AutoExecConfig_CreateConVar("sm_hosties_lr_onlyhs_on", "1", "Enables the LR Only Headshot: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_HEFight_On 				= AutoExecConfig_CreateConVar("sm_hosties_lr_hefight_on", "1", "Enables the LR Grenade Fight: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);

	gH_Cvar_LR_HotPotato_Mode 			= AutoExecConfig_CreateConVar("sm_hosties_lr_hp_teleport", "2", "Teleport CT to T on hot potato contest start: 0 - disable, 1 - enable, 2 - enable and freeze", 0, true, 0.0, true, 2.0);
	gH_Cvar_SendGlobalMsgs				= AutoExecConfig_CreateConVar("sm_hosties_lr_send_global_msgs", "0", "Specifies if non-death related LR messages are sent to everyone or just the active participants in that LR. 0: participants, 1: everyone", 0, true, 0.0, true, 1.0);
	gH_Cvar_MaxPrisonersToLR 			= AutoExecConfig_CreateConVar("sm_hosties_lr_ts_max", "2", "The maximum number of terrorists left to enable LR: 0 - LR is always enabled, >0 - maximum number of Ts", 0, true, 0.0, true, 63.0);
	gH_Cvar_CheatAction 				= AutoExecConfig_CreateConVar("sm_hosties_lr_cheat_action", "2", "Decides what to do with those who cheat/interfere during an LR. 0 - Nothing, but prevent cheating, 1 - Abort the LR, 2 - Slay the culprit", 0, true, 0.0, true, 2.0);
	gH_Cvar_RebelHandling 				= AutoExecConfig_CreateConVar("sm_hosties_lr_rebel_mode", "1", "LR-mode for rebelling terrorists: 0 - Rebelling Ts can never have a LR, 1 - Rebelling Ts must let the CT decide if a LR is OK, 2 - Rebelling Ts can have a LR just like other Ts", 0, true, 0.0);
	gH_Cvar_RebelOnImpact 				= AutoExecConfig_CreateConVar("sm_hosties_lr_rebel_impact", "0", "Sets terrorists to rebels for firing a bullet. 0 - Disabled, 1 - Enabled.", 0, true, 0.0, true, 1.0);
	gH_Cvar_ColorRebels 				= AutoExecConfig_CreateConVar("sm_hosties_rebel_color", "0", "Turns on coloring rebels", 0, true, 0.0, true, 1.0);
	gH_Cvar_ColorRebels_Red 			= AutoExecConfig_CreateConVar("sm_hosties_rebel_red", "255", "What color to turn a rebel into (set R, G and B values to 255 to disable) (Rgb): x - red value", 0, true, 0.0, true, 255.0);
	gH_Cvar_ColorRebels_Green 			= AutoExecConfig_CreateConVar("sm_hosties_rebel_green", "0", "What color to turn a rebel into (rGb): x - green value", 0, true, 0.0, true, 255.0);
	gH_Cvar_ColorRebels_Blue 			= AutoExecConfig_CreateConVar("sm_hosties_rebel_blue", "0", "What color to turn a rebel into (rgB): x - blue value", 0, true, 0.0, true, 255.0);
	gH_Cvar_LR_Beacons 					= AutoExecConfig_CreateConVar("sm_hosties_lr_beacon", "1", "Beacon players on LR or not: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_HelpBeams 				= AutoExecConfig_CreateConVar("sm_hosties_lr_beams", "1", "Displays connecting beams between LR contestants: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_HelpBeams_Distance 		= AutoExecConfig_CreateConVar("sm_hosties_lr_beams_distance", "0.0", "Controls how close LR partners must be before the connecting beams will disappear: 0 - always on, >0 the distance in game units", 0, true, 0.0);
	gH_Cvar_LR_Beacon_Interval 			= AutoExecConfig_CreateConVar("sm_hosties_lr_beacon_interval", "1.0", "The interval in seconds of which the beacon 'beeps' on LR", 0, true, 0.1);
	gH_Cvar_LR_ChickenFight_Slay 		= AutoExecConfig_CreateConVar("sm_hosties_lr_cf_slay", "1", "Slay the loser of a Chicken Fight instantly? 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_ChickenFight_C_Blue 		= AutoExecConfig_CreateConVar("sm_hosties_lr_cf_loser_blue", "0", "What color to turn the loser of a chicken fight into (rgB): x - blue value", 0, true, 0.0, true, 255.0);
	gH_Cvar_LR_ChickenFight_C_Green 	= AutoExecConfig_CreateConVar("sm_hosties_lr_cf_loser_green", "255", "What color to turn the loser of a chicken fight into (rGb): x - green value", 0, true, 0.0, true, 255.0);
	gH_Cvar_LR_ChickenFight_C_Red 		= AutoExecConfig_CreateConVar("sm_hosties_lr_cf_loser_red", "255", "What color to turn the loser of a chicken fight into (only if sm_hosties_lr_cf_slay == 0, set R, G and B values to 255 to disable) (Rgb): x - red value", 0, true, 0.0, true, 255.0);
	gH_Cvar_LR_Dodgeball_CheatCheck 	= AutoExecConfig_CreateConVar("sm_hosties_lr_db_cheatcheck", "1", "Enable health-checker in LR Dodgeball to prevent contestant cheating (healing themselves): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Dodgeball_SpawnTime 		= AutoExecConfig_CreateConVar("sm_hosties_lr_db_flash_duration", "1.4", "The amount of time after a thrown flash before a new flash is given to a contestant: float value - delay in seconds", 0, true, 0.7, true, 6.0);
	gH_Cvar_LR_Dodgeball_Gravity 		= AutoExecConfig_CreateConVar("sm_hosties_lr_db_gravity", "0.6", "What gravity multiplier the dodgeball contestants will get: <1.0 - less/lower, >1.0 - more/higher", 0, true, 0.1, true, 2.0);
	gH_Cvar_LR_HotPotato_MaxTime 		= AutoExecConfig_CreateConVar("sm_hosties_lr_hp_maxtime", "20.0", "Maximum time in seconds the Hot Potato contest will last for (time is randomized): float value - time", 0, true, 8.0, true, 120.0);
	gH_Cvar_LR_HotPotato_MinTime 		= AutoExecConfig_CreateConVar("sm_hosties_lr_hp_mintime", "10.0", "Minimum time in seconds the Hot Potato contest will last for (time is randomized): float value - time", 0, true, 0.0, true, 45.0);
	gH_Cvar_LR_HotPotato_Speed 			= AutoExecConfig_CreateConVar("sm_hosties_lr_hp_speed_multipl", "1.5", "What speed multiplier a hot potato contestant who has the deagle is gonna get: <1.0 - slower, >1.0 - faster", 0, true, 0.8, true, 3.0);
	gH_Cvar_LR_S4S_DoubleShot 			= AutoExecConfig_CreateConVar("sm_hosties_lr_s4s_dblsht_action", "1", "What to do with someone who fires 2 shots in a row in Shot4Shot: 0 - nothing (ignore completely), 1 - Follow rebel punishment cvars", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_NoScope_Sound 			= AutoExecConfig_CreateConVar("sm_hosties_noscope_sound", "sm_hosties/noscopestart1.mp3", "What sound to play when a No Scope Battle starts, relative to the sound-folder: -1 - disable, path - path to sound file", 0);
	gH_Cvar_LR_Sound 					= AutoExecConfig_CreateConVar("sm_hosties_lr_sound", "sm_hosties/lr1.mp3", "What sound to play when LR gets available, relative to the sound-folder (also requires sm_hosties_announce_lr to be 1): -1 - disable, path - path to sound file", 0);
	gH_Cvar_LR_Beacon_Sound 			= AutoExecConfig_CreateConVar("sm_hosties_beacon_sound", "buttons/blip1.wav", "What sound to play each second a beacon is 'ping'ed.", 0);
	gH_Cvar_LR_NoScope_Weapon			= AutoExecConfig_CreateConVar("sm_hosties_lr_ns_weapon", "2", "Weapon to use in a No Scope Battle: 0 - AWP, 1 - scout, 2 - let the terrorist choose, 3 - SG550, 4 - G3SG1", 0, true, 0.0, true, 2.0);
	gH_Cvar_LR_NonContKiller_Action 	= AutoExecConfig_CreateConVar("sm_hosties_lr_p_killed_action", "1", "What to do when a LR-player gets killed by a player not in LR during LR: 0 - just abort LR, 1 - abort LR and slay the attacker", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_GunToss_Marker			= AutoExecConfig_CreateConVar("sm_hosties_lr_gt_marker_enable", "1", "Enable or disable Gun Toss markers", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_GunToss_MarkerMode 		= AutoExecConfig_CreateConVar("sm_hosties_lr_gt_markers", "0", "Deagle marking: 0 - markers straight up where the deagles land, 1 - markers starting where the deagle was dropped ending at the deagle landing point", 0);
	gH_Cvar_LR_GunToss_ShowMeter 		= AutoExecConfig_CreateConVar("sm_hosties_lr_gt_meter", "1", "Displays a distance meter: 0 - do not display, 1 - display", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_GunToss_SlayOnLose 		= AutoExecConfig_CreateConVar("sm_hosties_lr_gt_slayonlose", "0", "Slay the loser instantly in GunToss", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Delay_Enable_Time 		= AutoExecConfig_CreateConVar("sm_hosties_lr_enable_delay", "0.0", "Delay in seconds before a last request can be started: 0.0 - instantly, >0.0 - (float value) delay in seconds", 0, true, 0.0);
	gH_Cvar_LR_Damage 					= AutoExecConfig_CreateConVar("sm_hosties_lr_damage", "0", "Enables that players can not attack players in LR and players in LR can not attack players outside LR: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_NoScope_Delay 			= AutoExecConfig_CreateConVar("sm_hosties_lr_ns_delay", "3", "Delay in seconds before a No Scope Battle begins (to prepare the contestants...)", 0, true, 0.0);
	gH_Cvar_LR_Race_AirPoints 			= AutoExecConfig_CreateConVar("sm_hosties_lr_race_airpoints", "0", "Allow prisoners to set race points in the air.", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Race_NotifyCTs 			= AutoExecConfig_CreateConVar("sm_hosties_lr_race_tell_cts", "1", "Tells all CTs when a T has selected the race option from the LR menu", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Race_CDOnCancel 			= AutoExecConfig_CreateConVar("sm_hosties_lr_race_cd_on_cancel", "1", "Set a cooldown for LR after Race cancel (against exploits)", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Rebel_MaxTs 				= AutoExecConfig_CreateConVar("sm_hosties_lr_rebel_ts", "1", "If the Rebel LR option is enabled, specifies the maximum number of alive terrorists needed for the option to appear in the LR menu.", 0, true, 1.0);
	gH_Cvar_LR_Rebel_MinCTs 			= AutoExecConfig_CreateConVar("sm_hosties_lr_rebel_cts", "1", "If the Rebel LR option is enabled, specifies how minimum number of alive counter-terrorists needed for the option to appear in the LR menu.", 0, true, 1.0);
	gH_Cvar_LR_Rebel_Weapons 			= AutoExecConfig_CreateConVar("sm_hosties_lr_rebel_weapons", "weapon_m249,weapon_deagle", "Weapons to give in rebel", 0);
	gH_Cvar_LR_M4M_MagCapacity 			= AutoExecConfig_CreateConVar("sm_hosties_lr_m4m_capacity", "7", "The number of bullets in each magazine given to Mag4Mag LR contestants", 0, true, 2.0);
	gH_Cvar_LR_KnifeFight_LowGrav 		= AutoExecConfig_CreateConVar("sm_hosties_lr_kf_gravity", "0.6", "The multiplier used for the low-gravity knife fight.", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_KnifeFight_HiSpeed 		= AutoExecConfig_CreateConVar("sm_hosties_lr_kf_speed", "2.2", "The multiplier used for the high-speed knife fight.", 0, true, 1.1);
	gH_Cvar_LR_KnifeFight_Drunk 		= AutoExecConfig_CreateConVar("sm_hosties_lr_kf_drunk", "4", "The multiplier used for how drunk the player will be during the drunken boxing knife fight.", 0, true, 0.0);
	gH_Cvar_Announce_CT_FreeHit 		= AutoExecConfig_CreateConVar("sm_hosties_announce_attack", "1", "Enable or disable announcements when a CT attacks a non-rebelling T: 0 - disable, 1 - console, 2 - chat, 3 - both", 0, true, 0.0, true, 3.0);
	gH_Cvar_Announce_LR 				= AutoExecConfig_CreateConVar("sm_hosties_announce_lr", "1", "Enable or disable chat announcements when Last Requests starts to be available: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Announce_Rebel 				= AutoExecConfig_CreateConVar("sm_hosties_announce_rebel", "0", "Enable or disable chat announcements when a terrorist becomes a rebel: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Announce_RebelDown 			= AutoExecConfig_CreateConVar("sm_hosties_announce_rebel_down", "0", "Enable or disable chat announcements when a rebel is killed: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Announce_Weapon_Attack 		= AutoExecConfig_CreateConVar("sm_hosties_announce_wpn_attack", "0", "Enable or disable an announcement telling that a non-rebelling T has a weapon when he gets attacked by a CT (also requires sm_hosties_announce_attack 1): 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Announce_Shot4Shot 			= AutoExecConfig_CreateConVar("sm_hosties_lr_s4s_shot_taken", "1", "Enable announcements in Shot4Shot or Mag4Mag when a contestant empties their gun: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Announce_Delay_Enable 		= AutoExecConfig_CreateConVar("sm_hosties_announce_lr_delay", "1", "Enable or disable chat announcements to tell that last request delaying is activated and how long the delay is: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_Announce_HotPotato_Eqp 		= AutoExecConfig_CreateConVar("sm_hosties_lr_hp_pickupannounce", "0", "Enable announcement when a Hot Potato contestant picks up the hot potato: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_AutoDisplay 				= AutoExecConfig_CreateConVar("sm_hosties_lr_autodisplay", "0", "Automatically display the LR menu to non-rebelers when they become elgible for LR: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_BlockSuicide 			= AutoExecConfig_CreateConVar("sm_hosties_lr_blocksuicide", "0", "Blocks LR participants from commiting suicide to avoid deaths: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_VictorPoints 			= AutoExecConfig_CreateConVar("sm_hosties_lr_victorpoints", "1", "Amount of frags to reward victor in an LR where other player automatically dies", 0, true, 0.0);
	gH_Cvar_LR_RestoreWeapon_T 			= AutoExecConfig_CreateConVar("sm_hosties_lr_restoreweapon_t", "1", "Restore weapons after LR for T players: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_RestoreWeapon_CT 		= AutoExecConfig_CreateConVar("sm_hosties_lr_restoreweapon_ct", "1", "Restore weapons after LR for CT players: 0 - disable, 1 - enable", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Rebel_HP_per_CT 			= AutoExecConfig_CreateConVar("sm_hosties_rebel_hp_for_ct", "50", "Customize HPs per CT in Rebel as a Terrorist.", 0, true, 0.0);
	gH_Cvar_LR_Rebel_CT_HP 				= AutoExecConfig_CreateConVar("sm_hosties_rebel_ct_hp", "100", "Customize CT player's HP in Rebel", 0, true, 0.0);
	gH_Cvar_LR_Fists_Instead_Knife 		= AutoExecConfig_CreateConVar("sm_hosties_fists_instead_knife", "0", "Forces to use fists instead of knife by Hosties. (Not affects LR games)", 0, true, 0.0, true, 1.0);
	gH_Cvar_LR_Ten_Timer 				= AutoExecConfig_CreateConVar("sm_hosties_ten_second_timers", "1", "Enable or disable the Must Throw in GunToss and Must Jump in Jump Contests timers", 0, true, 0.0, true, 1.0);
	
	HookConVarChange(gH_Cvar_LR_KnifeFight_On,			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_Shot4Shot_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_ChickenFight_On, 		ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_GunToss_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_HotPotato_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_Dodgeball_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_NoScope_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_RockPaperScissors_On, 	ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_Rebel_On, 				ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_Mag4Mag_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_Race_On, 				ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_RussianRoulette_On, 	ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_JumpContest_On, 		ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_ShieldFight_On, 		ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_FistFight_On, 			ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_JuggernoutBattle_On, 	ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_OnlyHS_On, 				ConVarChanged_LastRequest);
	HookConVarChange(gH_Cvar_LR_HEFight_On, 			ConVarChanged_LastRequest);
	
	// Account for late loading
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (EMP_IsValidClient(idx, false, true))
		{
			SDKHook(idx, SDKHook_WeaponDrop, 	OnWeaponDrop);
			SDKHook(idx, SDKHook_WeaponEquip, 	OnWeaponEquip);
			SDKHook(idx, SDKHook_WeaponCanUse, 	OnWeaponDecideUse);
			SDKHook(idx, SDKHook_OnTakeDamage, 	OnTakeDamage);
		}
		g_bIsARebel[idx] = false;
		g_bInLastRequest[idx] = false;
		EMP_FreeHandle(gH_BuildLR[idx]);
	}
}

void LastRequest_Menus(Handle h_TopMenu, TopMenuObject obj_Hosties)
{
	AddToTopMenu(h_TopMenu, "sm_stoplr", TopMenuObject_Item, AdminMenu_StopLR, obj_Hosties, "sm_stoplr", ADMFLAG_SLAY);
}

public void AdminMenu_StopLR(Handle h_TopMenu, TopMenuAction action, TopMenuObject item, int client, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Stop All LastRequests");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		StopActiveLRs(client);
	}
}

void LastRequest_APL()
{
	CreateNative("IsLastRequestAvailable", 		Native_LR_Available);
	CreateNative("AddLastRequestToList", 		Native_LR_AddToList);
	CreateNative("RemoveLastRequestFromList", 	Native_LR_RemoveFromList);
	CreateNative("IsClientRebel", 				Native_IsClientRebel);
	CreateNative("IsClientInLastRequest", 		Native_IsClientInLR);
	CreateNative("ProcessAllLastRequests", 		Native_ProcessLRs);
	CreateNative("ChangeRebelStatus", 			Native_ChangeRebelStatus);
	CreateNative("InitializeLR", 				Native_LR_Initialize);
	CreateNative("CleanupLR", 					Native_LR_Cleanup);
	
	RegPluginLibrary("lastrequest");
}

int Native_ProcessLRs(Handle h_Plugin, int iNumParameters)
{
	Function LoopCallback = GetNativeCell(1);
	AddToForward(gH_Frwd_LR_Process, h_Plugin, LoopCallback);
	int thisType = GetNativeCell(2);
		
	int theLRArraySize = GetArraySize(gH_DArray_LR_Partners);
	for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
	{
		int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
		if (type == thisType)
		{
			Call_StartForward(gH_Frwd_LR_Process);
			Call_PushCell(gH_DArray_LR_Partners);
			Call_PushCell(idx);
			Call_Finish();
		}
	}
	
	RemoveFromForward(gH_Frwd_LR_Process, h_Plugin, LoopCallback);
	return theLRArraySize;
}

int Native_LR_AddToList(Handle h_Plugin, int iNumParameters)
{
	Function StartCall = GetNativeCell(1);
	Function CleanUpCall = GetNativeCell(2);
	AddToForward(gH_Frwd_LR_Start, h_Plugin, StartCall);
	AddToForward(gH_Frwd_LR_CleanUp, h_Plugin, CleanUpCall);
	char sLR_Name[MAX_DISPLAYNAME_SIZE];
	GetNativeString(3, sLR_Name, MAX_DISPLAYNAME_SIZE);
	bool AutoStart = (iNumParameters > 3) ? GetNativeCell(4) : true;
	int iPosition = PushArrayString(gH_DArray_LR_CustomNames, sLR_Name);
	// take the maximum number of LRs + the custom LR index to get int value to push
	iPosition += view_as<int>(LR_Number);
	int iIndex = PushArrayCell(gH_DArray_LastRequests, iPosition);
	SetArrayCell(gH_DArray_LastRequests, iIndex, AutoStart, 1);
	return iPosition;
}

int Native_LR_RemoveFromList(Handle h_Plugin, int iNumParameters)
{
	Function StartCall = GetNativeCell(1);
	Function CleanUpCall = GetNativeCell(2);
	RemoveFromForward(gH_Frwd_LR_Start, h_Plugin, StartCall);
	RemoveFromForward(gH_Frwd_LR_CleanUp, h_Plugin, CleanUpCall);
	char sLR_Name[MAX_DISPLAYNAME_SIZE];
	GetNativeString(3, sLR_Name, MAX_DISPLAYNAME_SIZE);
	int iPosition = FindStringInArray(gH_DArray_LR_CustomNames, sLR_Name);
	if (iPosition == -1)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "LR Name (%s) Not Found", sLR_Name);
	}
	else
	{
		RemoveFromArray(gH_DArray_LR_CustomNames, iPosition);
		iPosition += view_as<int>(LR_Number);
		RemoveFromArray(gH_DArray_LastRequests, iPosition);
	}
	return 1;
}

int Native_LR_Initialize(Handle h_Plugin, int iNumParameters)
{
	if(iNumParameters > 0)
	{
		int LR_Player_Prisoner = 0, oPrisoner = GetNativeCell(1);
		if(oPrisoner != 0)
		{
			if(GetClientTeam(oPrisoner) == CS_TEAM_T)
			{
				LR_Player_Prisoner = oPrisoner;
			}
		}
		if(LR_Player_Prisoner != 0 && g_LR_Player_Guard[LR_Player_Prisoner] != 0)
		{
			if(!IsLastRequestAutoStart(g_selection[LR_Player_Prisoner]))
			{
				int iArrayIndex = PushArrayCell(gH_DArray_LR_Partners, g_selection[LR_Player_Prisoner]);
				SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, LR_Player_Prisoner, view_as<int>(Block_Prisoner));
				SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, g_LR_Player_Guard[LR_Player_Prisoner], view_as<int>(Block_Guard));

				// Fire global
				Call_StartForward(gH_Frwd_LR_StartGlobal);
				Call_PushCell(LR_Player_Prisoner);
				Call_PushCell(g_LR_Player_Guard[LR_Player_Prisoner]);
				// LR type
				Call_PushCell(g_selection[LR_Player_Prisoner]);
				int ignore;
				Call_Finish(view_as<int>(ignore));
				
				// Close datapack
				EMP_FreeHandle(gH_BuildLR[LR_Player_Prisoner]);		
				
				// Beacon players
				if (gH_Cvar_LR_Beacons.BoolValue)
				{
					AddBeacon(LR_Player_Prisoner);
					AddBeacon(g_LR_Player_Guard[LR_Player_Prisoner]);
				}
			}
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "InitializeLR Failure (Invalid client(s) index).");
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "InitializeLR Failure (Wrong number of parameters).");
	}
	return 0;
}

int Native_LR_Cleanup(Handle h_Plugin, int iNumParameters)
{
	if(iNumParameters == 1)
	{
		int LR_Player_Prisoner = GetNativeCell(1);
		//PrintToChatAll("Debug: %d", LR_Player_Prisoner);
		if(IsClientInGame(LR_Player_Prisoner))
		{
			if(!IsLastRequestAutoStart(g_selection[LR_Player_Prisoner]))
			{
				g_bInLastRequest[LR_Player_Prisoner] = false;
				g_bInLastRequest[g_LR_Player_Guard[LR_Player_Prisoner]] = false;
				
				RemoveBeacon(LR_Player_Prisoner);
				RemoveBeacon(g_LR_Player_Guard[LR_Player_Prisoner]);
				
				// Fire global
				Call_StartForward(gH_Frwd_LR_StopGlobal);
				Call_PushCell(LR_Player_Prisoner);
				Call_PushCell(g_LR_Player_Guard[LR_Player_Prisoner]);
				// LR type
				Call_PushCell(g_selection[LR_Player_Prisoner]);
				int ignore;
				Call_Finish(view_as<int>(ignore));
				
				g_LR_Player_Guard[LR_Player_Prisoner] = 0;
			}
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "CleanupLR Failure (Invalid client index or player is already in LR).");
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "CleanupLR Failure (Wrong number of parameters).");
	}
	return 0;
}

int Native_LR_Available(Handle h_Plugin, int iNumParameters)
{
	return g_bIsLRAvailable;
}

int Native_IsClientRebel(Handle h_Plugin, int iNumParameters)
{
	int client = GetNativeCell(1);
	if (client > MaxClients || client < 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	return view_as<bool>(g_bIsARebel[client]);
}

int Native_ChangeRebelStatus(Handle h_Plugin, int iNumParameters)
{
	int client = GetNativeCell(1);
	if (client > MaxClients || client < 0)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	int status = GetNativeCell(2);
	if (status < 0 || status > 1)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid rebel status (%d)", status);
	}
	g_bIsARebel[client] = view_as<bool>(status);
	if(g_bIsARebel[client])
	{
		MarkRebel(client, 0);
	}
	return 1;
}

int Native_IsClientInLR(Handle h_Plugin, int iNumParameters)
{
	int client = GetNativeCell(1);
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Given client index (%d) not in game", client);
	}
	return Local_IsClientInLR(client);
}

void MarkRebel(int client, int victim)
{
	if (gH_Cvar_Announce_Rebel.BoolValue && EMP_IsValidClient(client, false, true))
	{
		if (gH_Cvar_SendGlobalMsgs.BoolValue)
		{
			EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "New Rebel", client);
		}
		else
		{
			CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "New Rebel", client);
			if (EMP_IsValidClient(victim, false, true))
			{
				CPrintToChat(victim, "%s%t", gShadow_Hosties_ChatBanner, "New Rebel", client);
			}
		}
	}
	if (gH_Cvar_ColorRebels.BoolValue)
	{
		SetEntityRenderColor(client, gH_Cvar_ColorRebels_Red.IntValue, gH_Cvar_ColorRebels_Green.IntValue, gH_Cvar_ColorRebels_Blue.IntValue, 255);
	}
}

int Local_IsClientInLR(int client)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	int LR_Player_Prisoner, LR_Player_Guard;
	for (int idx = 0; idx < iArraySize; idx++)
	{
		LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
		LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
		if ((LR_Player_Prisoner == client) || (LR_Player_Guard == client))
		{
			// check if a partner exists
			if ((LR_Player_Prisoner == 0) || (LR_Player_Guard == 0))
			{
				return -1;
			}
			else
			{
				return (LR_Player_Prisoner == client ? LR_Player_Guard : LR_Player_Prisoner);
			}
		}
	}
	return 0;
}

void LastRequest_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundTime = GetConVarInt(g_hRoundTime) * 60;
	if (TickerState == INVALID_HANDLE)
	{
		RoundTimeTicker = CreateTimer(1.0, Timer_RoundTimeLeft, g_RoundTime, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		EMP_StopTimer(RoundTimeTicker);
		RoundTimeTicker = CreateTimer(1.0, Timer_RoundTimeLeft, g_RoundTime, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	g_bAnnouncedThisRound = false;
	
	// Set variable to know that the round has started
	g_bRoundInProgress = true;
	
	// roundstart done, enable LR if there should be no LR delay (credits to Caza for this :p)
	if (gH_Cvar_LR_Delay_Enable_Time.FloatValue > 0.0)
	{
		g_bIsLRAvailable = false;	
		g_DelayLREnableTimer = CreateTimer(gH_Cvar_LR_Delay_Enable_Time.FloatValue, Timer_EnableLR, _, TIMER_FLAG_NO_MAPCHANGE);

		if (gH_Cvar_Announce_Delay_Enable.BoolValue)
		{
			EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Delay Announcement", RoundToNearest(gH_Cvar_LR_Delay_Enable_Time.FloatValue));
		}
	}
	else
	{
		g_bIsLRAvailable = true;
	}
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		g_bIsARebel[idx] = false;
		g_bInLastRequest[idx] = false;
		g_LR_Player_Guard[idx] = 0;
		SetCorrectPlayerColor(idx);
	}
}

public Action Timer_EnableLR(Handle timer)
{
	if (g_DelayLREnableTimer == timer)
	{
		g_bIsLRAvailable = true;
		
		int Ts, CTs, NumCTsAvailable;
		UpdatePlayerCounts(Ts, CTs, NumCTsAvailable);	
	
		// Check if we should send OnAvailableLR forward now
		if (Ts <= gH_Cvar_MaxPrisonersToLR.IntValue && (NumCTsAvailable > 0) && (Ts > 0))
		{
			// do not announce later
			g_bAnnouncedThisRound = true;
			
			Call_StartForward(gH_Frwd_LR_Available);
			// announced = no
			Call_PushCell(false);
			int ignore;
			Call_Finish(view_as<int>(ignore));
		}
	}
	return Plugin_Stop;
}

public Action Command_CancelLR(int client, int args)
{
	StopActiveLRs(client);
	return Plugin_Handled;
}

void StopActiveLRs(int client)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	while (iArraySize > 0)
	{
		CleanupLastRequest(client, iArraySize-1);
		RemoveFromArray(gH_DArray_LR_Partners, iArraySize-1);
		iArraySize--;
	}
	Hosties_ShowActivity(client, "%t", "LR Aborted");
}

void LastRequest_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundTimeTicker = INVALID_HANDLE;

	// Block LRs and reset
	g_bIsLRAvailable = false;
	
	// Set variable to know that the round has ended
	g_bRoundInProgress = false;
	
	// Remove all the LR data
	ClearArray(gH_DArray_LR_Partners);
	ClearArray(gH_DArray_Beacons);
	
	// Stop timers for short rounds
	if (g_DelayLREnableTimer != INVALID_HANDLE)
	{
		g_DelayLREnableTimer = INVALID_HANDLE;
	}
	
	// Cancel menus of all alive prisoners	
	ClosePotentialLRMenus();
}

void LastRequest_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	int LR_Player_Prisoner, LR_Player_Guard;
	if (iArraySize > 0)
	{
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
			LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
			
			if (victim == LR_Player_Prisoner || victim == LR_Player_Guard) 
			{
				if (attacker != LR_Player_Prisoner && attacker != LR_Player_Guard \
					&& attacker && (type != LR_Rebel))
				{
					if (!gH_Cvar_LR_NonContKiller_Action)
					{
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Non LR Kill LR Abort", attacker, victim);
					}
					else
					{
						// follow rebel action
						DecideCheatersFate(attacker, idx);
						return;
					}
				}
            
				CleanupLastRequest(victim, idx);            
				RemoveFromArray(gH_DArray_LR_Partners, idx);            
			}
		}
	}

	int Ts, CTs, NumCTsAvailable;
	UpdatePlayerCounts(Ts, CTs, NumCTsAvailable);
	
	if ((Ts > 0) && gH_Cvar_Announce_RebelDown.BoolValue && g_bIsARebel[victim] && attacker && (attacker != victim))
	{
		if (gH_Cvar_SendGlobalMsgs.BoolValue)
		{
			EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Rebel Kill", attacker, victim);
		}
		else
		{
			CPrintToChat(attacker, "%s%t", gShadow_Hosties_ChatBanner, "Rebel Kill", attacker, victim);
			CPrintToChat(victim, "%s%t", gShadow_Hosties_ChatBanner, "Rebel Kill", attacker, victim);
		}
	}
	
	if (gH_Cvar_LR_AutoDisplay.BoolValue && gH_Cvar_LR_Enable.BoolValue && (Ts > 0) && (NumCTsAvailable > 0) && (Ts <= gH_Cvar_MaxPrisonersToLR.IntValue))
	{
		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (EMP_IsValidClient(idx, false, false, CS_TEAM_T) && !g_bIsARebel[idx])
			{
				FakeClientCommand(idx, "sm_lastrequest"); 
			}
		}
	}
	
	if (!g_bAnnouncedThisRound && gH_Cvar_LR_Enable.BoolValue)
	{
		if ((Ts == gH_Cvar_MaxPrisonersToLR.IntValue) && (NumCTsAvailable > 0) && (Ts > 0) && !BlockLR)
		{
			Call_StartForward(gH_Frwd_LR_Available);
			// announced = yes
			Call_PushCell(gH_Cvar_Announce_LR.BoolValue);
			int ignore;
			Call_Finish(view_as<int>(ignore));
		
			if (gH_Cvar_Announce_LR.BoolValue)
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Available");
				char buffer[PLATFORM_MAX_PATH];
				gH_Cvar_LR_Sound.GetString(buffer, sizeof(buffer));
				
				if ((strlen(buffer) > 0) && (strcmp(buffer, "-1") != 0))
				{
					EmitSoundToAllAny(buffer);
				}
			}
			
			g_bAnnouncedThisRound = true;
		}
	}
}

void LastRequest_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (Local_IsClientInLR(attacker) || Local_IsClientInLR(target))
	{
		int LR_Player_Prisoner, LR_Player_Guard;
		
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			
			if ((type == LR_Rebel) || !attacker || (attacker == target))
			{
				continue;
			}
			
			LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
			LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
			
			// a T outside the group interfered inside this LR by shooting a CT that was in a LR
			// Note that this situation is only possible if "sm_hosties_lr_damage" is set to "0"
			if (target == LR_Player_Guard && attacker != LR_Player_Prisoner && attacker != LR_Player_Guard)
			{
				// take action for rebelers
				if (!g_bIsARebel[attacker] && (GetClientTeam(attacker) == CS_TEAM_T))
				{
					g_bIsARebel[attacker] = true;
					if (gH_Cvar_Announce_Rebel.IntValue && EMP_IsValidClient(attacker, false, true))
					{
						if (gH_Cvar_SendGlobalMsgs.BoolValue)
						{
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "New Rebel", attacker);
						}
						else
						{
							CPrintToChat(attacker, "%s%t", gShadow_Hosties_ChatBanner, "New Rebel", attacker);
							CPrintToChat(target, "%s%t", gShadow_Hosties_ChatBanner, "New Rebel", attacker);
						}
					}
				}
			}
		}
	}
	// if a T attacks a CT and none of them is in a LR
	else if (attacker && target && (GetClientTeam(attacker) == CS_TEAM_T) && (GetClientTeam(target) == CS_TEAM_CT) \
		&& !g_bIsARebel[attacker] && g_bRoundInProgress)
	{
		g_bIsARebel[attacker] = true;
		if (EMP_IsValidClient(attacker, false, true))
		{
			MarkRebel(attacker, target);
		}
	}
	// if a CT attacks a T and none of them is in a LR
	else if (attacker && target && (GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(target) == CS_TEAM_T) \
		&& !g_bIsARebel[target] && g_bRoundInProgress)
	{
		bool bPrisonerHasGun = PlayerHasGun(target);
		
		if (gH_Cvar_Announce_CT_FreeHit.IntValue && target != g_iLastCT_FreeAttacker)
		{
			g_iLastCT_FreeAttacker = target;
			
			if (gH_Cvar_Announce_Weapon_Attack.BoolValue && bPrisonerHasGun)
			{
				if (EMP_IsValidClient(target, false, false))
				{
					for (int idx = 1; idx <= MaxClients; idx++)
					{
						if (EMP_IsValidClient(idx, false, true))
						{
							if(gH_Cvar_Announce_CT_FreeHit.IntValue != 2)
							{
								PrintToConsole(idx, "[Hosties] %t", "CT Attack T Gun", attacker, target);
							}
							if(gH_Cvar_Announce_CT_FreeHit.IntValue >= 2)
							{
								CPrintToChat(idx, "%s%t", gShadow_Hosties_ChatBanner, "CT Attack T Gun", attacker, target);
							}
						}
					}
				}
			}
			else
			{
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx, false, true))
					{
						if(gH_Cvar_Announce_CT_FreeHit.IntValue != 2)
						{
							PrintToConsole(idx, "[Hosties] %t", "Freeattack", attacker, target);
						}
						if(gH_Cvar_Announce_CT_FreeHit.IntValue >= 2)
						{
							CPrintToChat(idx, "%s%t", gShadow_Hosties_ChatBanner, "Freeattack", attacker, target);
						}
					}
				}
			}
		}
	}
}

void LastRequest_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int LR_Player_Prisoner, LR_Player_Guard;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
			LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
			
			if (client == LR_Player_Prisoner || client == LR_Player_Guard)
			{
				CleanupLastRequest(client, idx);
				RemoveFromArray(gH_DArray_LR_Partners, idx);
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Player Disconnect", client);
				if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "%L has disconnected in LR. LR aborted.", client);
			}
		}
	}
}

void CleanupLastRequest(int loser, int arrayIndex)
{
	int type = GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_LRType));
	int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_Prisoner));
	int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_Guard));
	
	g_bInLastRequest[LR_Player_Prisoner] = false;
	g_bInLastRequest[LR_Player_Guard] = false;
	
	RemoveBeacon(LR_Player_Prisoner);
	RemoveBeacon(LR_Player_Guard);
	
	int winner = (loser == LR_Player_Prisoner) ? LR_Player_Guard : LR_Player_Prisoner;
	char LR_Name[64];
	
	switch (type)
	{
		case LR_KnifeFight:
		{
			int KnifeChoice = GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_Global1));
			switch (KnifeChoice)
			{
				case Knife_Drunk, Knife_Drugs:
				{
					if (EMP_IsValidClient(LR_Player_Prisoner, false, true))
					{
						SetEntData(LR_Player_Prisoner, g_Offset_FOV, NORMAL_VISION, 4, true);
						SetEntData(LR_Player_Prisoner, g_Offset_DefFOV, NORMAL_VISION, 4, true);
						ShowOverlayToClient(LR_Player_Prisoner, "");
					}	
					if (EMP_IsValidClient(LR_Player_Guard, false, true))
					{
						SetEntData(LR_Player_Guard, g_Offset_FOV, NORMAL_VISION, 4, true);
						SetEntData(LR_Player_Guard, g_Offset_DefFOV, NORMAL_VISION, 4, true);
						ShowOverlayToClient(LR_Player_Guard, "");
					}
					
					if (g_Game == Game_CSGO)
					{
						ServerCommand("sm_drug #%i 0", GetClientUserId(LR_Player_Prisoner));
						ServerCommand("sm_drug #%i 0", GetClientUserId(LR_Player_Guard));
					}
				}
				case Knife_LowGrav:
				{
					if  (EMP_IsValidClient(LR_Player_Prisoner, false, true))
					{
						SetEntityGravity(LR_Player_Prisoner, 1.0);
					}
					if (EMP_IsValidClient(LR_Player_Guard, false, true))
					{
						SetEntityGravity(LR_Player_Guard, 1.0);
					}
				}
				case Knife_HiSpeed:
				{
					if (EMP_IsValidClient(winner, false, false))
					{
						SetEntPropFloat(winner, Prop_Data, "m_flLaggedMovementValue", 1.0);
					}
					if (EMP_IsValidClient(loser, false, true))
					{
						SetEntPropFloat(loser, Prop_Data, "m_flLaggedMovementValue", 1.0);
					}
				}
				case Knife_ThirdPerson:
				{
					if (EMP_IsValidClient(LR_Player_Prisoner, false, true))
					{
						SetFirstPerson(LR_Player_Prisoner);
					}
					if (EMP_IsValidClient(LR_Player_Guard, false, true))
					{
						SetFirstPerson(LR_Player_Guard);
					}
				}
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Knife Fight.");
		}
		case LR_GunToss:
		{
			int GTdeagle1 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_PrisonerData)));
			int GTdeagle2 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_GuardData)));
			if (IsValidEntity(GTdeagle1))
			{
				SetEntityRenderColor(GTdeagle1, 255, 255, 255);
				SetEntityRenderMode(GTdeagle1, RENDER_NORMAL);
			}
			if (IsValidEntity(GTdeagle2))
			{
				SetEntityRenderColor(GTdeagle2, 255, 255, 255);
				SetEntityRenderMode(GTdeagle2, RENDER_NORMAL);
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Gun Toss.");
		}
		case LR_HotPotato:
		{
			if (EMP_IsValidClient(winner, false, false))
			{
				SetEntPropFloat(winner, Prop_Data, "m_flLaggedMovementValue", 1.0);
				SetEntityMoveType(winner, MOVETYPE_WALK);
			}
			
			int HPdeagle = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_Global4)));
			RemoveBeacon(HPdeagle);
			if (IsValidEntity(HPdeagle))
			{
				SetEntityRenderColor(HPdeagle, 255, 255, 255);
				SetEntityRenderMode(HPdeagle, RENDER_NORMAL);
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Hot Potato.");
		}
		case LR_RussianRoulette:
		{
			if (EMP_IsValidClient(winner, false, false))
			{
				SetEntityMoveType(winner, MOVETYPE_WALK);
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Russian Roulette.");
		}
		case LR_Dodgeball:
		{
			if  (EMP_IsValidClient(winner, false, true))
			{
				SetEntityGravity(LR_Player_Prisoner, 1.0);
			}
			if (EMP_IsValidClient(winner, false, true))
			{
				SetEntityGravity(LR_Player_Guard, 1.0);
			}
			
			if (EMP_IsValidClient(winner, false, false))
			{
				Client_RemoveAllWeapons(winner);
				if(g_Game != Game_CSGO)
				{
					SetEntData(winner, g_Offset_Ammo+(view_as<int>(12)*4), 0, _, true);
				}
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Dodgeball.");
		}
		case LR_Race:
		{
			CloseHandle(GetArrayCell(gH_DArray_LR_Partners, arrayIndex, 9));
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Race.");
		}
		case LR_JumpContest:
		{
			int JumpType = GetArrayCell(gH_DArray_LR_Partners, arrayIndex, view_as<int>(Block_Global2));

			switch (JumpType)
			{
				case Jump_Farthest:
				{
					if (EMP_IsValidClient(winner, false, false))
					{
						SetEntityMoveType(winner, MOVETYPE_WALK);
					}               
				}
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Jump Contest.");
		}
		case LR_JuggernoutBattle:
		{
			LogToFileEx(gShadow_Hosties_LogFile, "Juggernout cleanup started for prisoner");
			if (EMP_IsValidClient(LR_Player_Prisoner, false, false))
			{
				EMP_ResetArmor(LR_Player_Prisoner);
				
				if (GetEngineVersion() == Engine_CSGO)
				{
					if (strlen(BeforeModel[LR_Player_Prisoner]) > 0)
					{
						SetEntityModel(LR_Player_Prisoner, BeforeModel[LR_Player_Prisoner]);
						FormatEx(BeforeModel[LR_Player_Prisoner], sizeof(BeforeModel[]), "");
					}
				}
			}
			
			LogToFileEx(gShadow_Hosties_LogFile, "Juggernout cleanup started for guard");
			if (EMP_IsValidClient(LR_Player_Guard, false, false))
			{
				EMP_ResetArmor(LR_Player_Guard);
			
				if (GetEngineVersion() == Engine_CSGO)
				{
					if (strlen(BeforeModel[LR_Player_Guard]) > 0)
					{
						SetEntityModel(LR_Player_Guard, BeforeModel[LR_Player_Guard]);
						FormatEx(BeforeModel[LR_Player_Guard], sizeof(BeforeModel[]), "");
					}
				}
			}
			
			LogToFileEx(gShadow_Hosties_LogFile, "Juggernout cleanup started for csgo");
			if (GetEngineVersion() == Engine_CSGO)
			{
				if (g_cvSvSuit == INVALID_HANDLE)
					g_cvSvSuit = FindConVar("mp_weapons_allow_heavyassaultsuit");
					
				SetConVarInt(g_cvSvSuit, SuitSetBack, true, false);
			}
			
			LogToFileEx(gShadow_Hosties_LogFile, "Juggernout cleanup started for looper");
			EMP_LoopPlayers(TargetForLang)
			{
				FormatEx(LR_Name, sizeof(LR_Name), "%t", g_sLastRequestPhrase[LR_JuggernoutBattle]);
				CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Won", winner, LR_Name);
			}
		}
		case LR_HEFight, LR_FistFight, LR_OnlyHS:
		{
			EMP_LoopPlayers(TargetForLang)
			{
				FormatEx(LR_Name, sizeof(LR_Name), "%t", g_sLastRequestPhrase[type]);
				CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Won", winner, LR_Name);
			}
		}
		case LR_ShieldFight:
		{
			int Remove;
			if (EMP_IsValidClient(LR_Player_Guard, false, false))
			{
				if (Client_HasWeapon(LR_Player_Guard, "weapon_shield"))
				{
					Remove = Client_GetWeapon(LR_Player_Guard, "weapon_shield");
					RemovePlayerItem(LR_Player_Guard, Remove);
					if (IsValidEntity(Remove)) RemoveEntity(Remove);
				}
			}
			
			if (EMP_IsValidClient(LR_Player_Prisoner, false, false))
			{
				if (Client_HasWeapon(LR_Player_Prisoner, "weapon_shield"))
				{
					Remove = Client_GetWeapon(LR_Player_Prisoner, "weapon_shield");
					RemovePlayerItem(LR_Player_Prisoner, Remove);
					if (IsValidEntity(Remove)) RemoveEntity(Remove);
				}
			}
			
			EMP_LoopPlayers(TargetForLang)
			{
				FormatEx(LR_Name, sizeof(LR_Name), "%t", g_sLastRequestPhrase[type]);
				CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Won", winner, LR_Name);
			}
		}
		default:
		{
			Call_StartForward(gH_Frwd_LR_CleanUp);
			Call_PushCell(type);
			Call_PushCell(LR_Player_Prisoner);
			Call_PushCell(LR_Player_Guard);
			int ignore;
			Call_Finish(view_as<int>(ignore));
			
			if(!IsLastRequestAutoStart(type))
			{
				g_LR_Player_Guard[LR_Player_Prisoner] = 0;
			}
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "Successfull cleanup after LR - Default.");
		}
	}
	
	// Fire global
	Call_StartForward(gH_Frwd_LR_StopGlobal);
	Call_PushCell(LR_Player_Prisoner);
	Call_PushCell(g_LR_Player_Guard[LR_Player_Prisoner]);
	// LR type
	Call_PushCell(g_selection[LR_Player_Prisoner]);
	int ignore;
	Call_Finish(view_as<int>(ignore));
	
	if (EMP_IsValidClient(LR_Player_Prisoner))
	{
		EMP_FreeHandle(gH_BuildLR[LR_Player_Prisoner]);
		
		if (IsPlayerAlive(LR_Player_Prisoner))
		{
			if (g_Game == Game_CSGO)
			{
				int TeamBlock = GetConVarInt(Cvar_TeamBlock);
			
				if (TeamBlock == 1 || TeamBlock == 2)
					BlockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
				else
					UnblockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
			}
			else if (g_Game == Game_CSS)
			{
				BlockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
			}
			
			SetEntPropFloat(LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_WALK);
			
			PerformRestore(LR_Player_Prisoner);

			SetEntityHealth(LR_Player_Prisoner, 100);
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "%L (Prisoner) attribute reset after LR.", LR_Player_Prisoner);
		}
	}
	
	if (EMP_IsValidClient(LR_Player_Guard))
	{
		EMP_FreeHandle(gH_BuildLR[LR_Player_Guard]);
		
		if (IsPlayerAlive(LR_Player_Guard))
		{
			if (g_Game == Game_CSGO)
			{
				int TeamBlock = GetConVarInt(Cvar_TeamBlock);
			
				if (TeamBlock == 1 || TeamBlock == 2)
					BlockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
				else
					UnblockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
			}
			else if (g_Game == Game_CSS)
			{
				BlockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
			}
			
			SetEntPropFloat(LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			SetEntityMoveType(LR_Player_Guard, MOVETYPE_WALK);
			
			PerformRestore(LR_Player_Guard);
			
			SetEntityHealth(LR_Player_Guard, 100);
			
			if (gH_Cvar_Debug.BoolValue) LogToFileEx(gShadow_Hosties_LogFile, "%L (Guard) attribute reset after LR.", LR_Player_Guard);
		}
	}
}

void LastRequest_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_bIsARebel[attacker] && gH_Cvar_RebelOnImpact.BoolValue && (GetClientTeam(attacker) == CS_TEAM_T) && !Local_IsClientInLR(attacker))
	{
		g_bIsARebel[attacker] = true;
		MarkRebel(attacker, 0);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	int LR_Player_Prisoner, LR_Player_Guard;
	for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
	{
		int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
		if (type == LR_NoScope || type == LR_Mag4Mag)
		{
			LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
			LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
			if (client == LR_Player_Prisoner || client == LR_Player_Guard)
			{
				buttons &= ~IN_ATTACK2;
			}
		}
		
		GetLastButton(client, buttons, idx);
	}
	return Plugin_Continue;
}

Action LastRequest_WeaponZoom(Event event, const char[] name, bool dontBroadcast)
{
	if (gH_DArray_LR_Partners != INVALID_HANDLE)
	{
		int iArraySize = GetArraySize(gH_DArray_LR_Partners);
		if (iArraySize > 0)
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			int LR_Player_Prisoner, LR_Player_Guard;
			for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
			{	
				int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
				if (type == LR_NoScope)
				{
					LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
					LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
					if (client == LR_Player_Prisoner || client == LR_Player_Guard)
					{
						SetEntData(client, g_Offset_FOV, 0, 4, true);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void LastRequest_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int LR_Player_Prisoner, LR_Player_Guard, iJumpCount = 0, GTp1dropped, GTp2dropped;
		float Prisoner_Position[3], Guard_Position[3];
		Handle JumpPackPosition;
		
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_JumpContest)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				int JumpType = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				
				switch (JumpType)
				{
					case Jump_TheMost:
					{
						if (client == LR_Player_Prisoner)
						{
							iJumpCount = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData));
							SetArrayCell(gH_DArray_LR_Partners, idx, ++iJumpCount, view_as<int>(Block_PrisonerData));
						}
						else if (client == LR_Player_Guard)
						{
							iJumpCount = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData));
							SetArrayCell(gH_DArray_LR_Partners, idx, ++iJumpCount, view_as<int>(Block_GuardData));
						}					
					}
					case Jump_Farthest:
					{
						if ((client == LR_Player_Prisoner) && !LR_Player_Jumped[LR_Player_Prisoner])
						{
							GetClientAbsOrigin(LR_Player_Prisoner, Before_Jump_pos[LR_Player_Prisoner]);
							LR_Player_Jumped[LR_Player_Prisoner] = true;
						}
						else if ((client == LR_Player_Guard) && !LR_Player_Jumped[LR_Player_Guard])
						{
							GetClientAbsOrigin(LR_Player_Guard, Before_Jump_pos[LR_Player_Guard]);
							LR_Player_Jumped[LR_Player_Guard] = true;
						}
					}
				}
			}
			else if (type == LR_GunToss)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				GTp1dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
				GTp2dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));

				// we want to grab the last jump position *before* they throw their gun
				if (client == LR_Player_Prisoner && !GTp1dropped)
				{
					// record position
					GetClientAbsOrigin(LR_Player_Prisoner, Prisoner_Position);
					JumpPackPosition = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_DataPackHandle));
					#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 8
						SetPackPosition(JumpPackPosition, view_as<DataPackPos>(6));
					#else
						SetPackPosition(JumpPackPosition, 6);
					#endif
					WritePackFloat(JumpPackPosition, Prisoner_Position[0]);
					WritePackFloat(JumpPackPosition, Prisoner_Position[1]);
					WritePackFloat(JumpPackPosition, Prisoner_Position[2]);
				}
				else if (client == LR_Player_Guard && !GTp2dropped)
				{
					GetClientAbsOrigin(LR_Player_Guard, Guard_Position);
					JumpPackPosition = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_DataPackHandle));
					#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 8
						SetPackPosition(JumpPackPosition, view_as<DataPackPos>(9));
					#else
						SetPackPosition(JumpPackPosition, 9);
					#endif
					WritePackFloat(JumpPackPosition, Guard_Position[0]);
					WritePackFloat(JumpPackPosition, Guard_Position[1]);
					WritePackFloat(JumpPackPosition, Guard_Position[2]);
				}
			}
		}
	}
}

void LastRequest_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		int LR_Player_Prisoner, LR_Player_Guard, M4M_Prisoner_Weapon, M4M_Guard_Weapon, M4M_RoundsFired, M4M_Ammo, iClientWeapon, currentAmmo, iAmmoType, Prisoner_Weapon, Guard_Weapon, Prisoner_S4S_Pistol, Guard_S4S_Pistol, S4Slastshot;
		char FiredWeapon[32];
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_Mag4Mag)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				if ((client == LR_Player_Prisoner) || (client == LR_Player_Guard))
				{
					M4M_Prisoner_Weapon = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData));
					M4M_Guard_Weapon = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData));
					M4M_RoundsFired = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
					M4M_Ammo = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global3));
					
					GetEventString(event, "weapon", FiredWeapon, sizeof(FiredWeapon));
					iClientWeapon = GetEntDataEnt2(client, g_Offset_ActiveWeapon);
					
					// set the time to enable burst value to a high value
					SetEntDataFloat(iClientWeapon, g_Offset_SecAttack, GetGameTime() + 9999.0);
					
					if (iClientWeapon != M4M_Prisoner_Weapon && iClientWeapon != M4M_Guard_Weapon && StrContains(FiredWeapon, "knife") == -1)
					{
						DecideCheatersFate(client, idx, -1);
					}
					else if (strcmp(FiredWeapon, "knife") != 0)
					{
						currentAmmo = GetEntData(iClientWeapon, g_Offset_Clip1);
						// check if a shot was actually fired
						if (currentAmmo != M4M_Ammo)
						{
							SetArrayCell(gH_DArray_LR_Partners, idx, currentAmmo, view_as<int>(Block_Global3));
							SetArrayCell(gH_DArray_LR_Partners, idx, ++M4M_RoundsFired, view_as<int>(Block_Global2));
							
							if (M4M_RoundsFired >= gH_Cvar_LR_M4M_MagCapacity.IntValue)
							{
								M4M_RoundsFired = 0;
								SetArrayCell(gH_DArray_LR_Partners, idx, M4M_RoundsFired, view_as<int>(Block_Global2));
								if (gH_Cvar_Announce_Shot4Shot.BoolValue)
								{
									if (gH_Cvar_SendGlobalMsgs.BoolValue)
									{
										EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "M4M Mag Used", client);
									}
									else
									{
										CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "M4M Mag Used", client);
										CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "M4M Mag Used", client);
									}
								}

								// send it to the next player
								if (LR_Player_Prisoner == client)
								{
									SetEntData(M4M_Guard_Weapon, g_Offset_Clip1, gH_Cvar_LR_M4M_MagCapacity.IntValue);
									SetArrayCell(gH_DArray_LR_Partners, idx, LR_Player_Guard, view_as<int>(Block_Global1));
								}
								else if (LR_Player_Guard == client)
								{
									SetEntData(M4M_Prisoner_Weapon, g_Offset_Clip1, gH_Cvar_LR_M4M_MagCapacity.IntValue);
									SetArrayCell(gH_DArray_LR_Partners, idx, LR_Player_Prisoner, view_as<int>(Block_Global1));
								}
								
								if(g_Game == Game_CSGO)
								{
									SetEntProp(M4M_Guard_Weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
									SetEntProp(M4M_Prisoner_Weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
								}
								else
								{
									iAmmoType = GetEntProp(M4M_Prisoner_Weapon, Prop_Send, "m_iPrimaryAmmoType");
									SetEntData(LR_Player_Guard, g_Offset_Ammo+(iAmmoType*4), 0, _, true);
									SetEntData(LR_Player_Prisoner, g_Offset_Ammo+(iAmmoType*4), 0, _, true);
								}
							}
						}
					}
				}			
			}
			else if (type == LR_RussianRoulette)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				if ((client == LR_Player_Prisoner) || (client == LR_Player_Guard))
				{							
					Prisoner_Weapon = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData)));
					Guard_Weapon = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData)));

					if (gH_Cvar_Announce_Shot4Shot.BoolValue)
					{
						if (gH_Cvar_SendGlobalMsgs.BoolValue)
						{
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "S4S Shot Taken", client);
						}
						else
						{
							CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "S4S Shot Taken", client);
							CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "S4S Shot Taken", client);
						}
					}
					
					// give the opposite LR player 1 bullet in their deagle
					if (client == LR_Player_Prisoner)
					{
						// modify deagle 2s ammo
						SetEntData(Guard_Weapon, g_Offset_Clip1, 1);
					}
					else if (client == LR_Player_Guard)
					{
						// modify deagle 1s ammo
						SetEntData(Prisoner_Weapon, g_Offset_Clip1, 1);
					}
					
					if(g_Game == Game_CSGO)
					{
						SetEntProp(Guard_Weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
						SetEntProp(Prisoner_Weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					}
					else
					{
						iAmmoType = GetEntProp(Prisoner_Weapon, Prop_Send, "m_iPrimaryAmmoType");
						SetEntData(LR_Player_Guard, g_Offset_Ammo+(iAmmoType*4), 0, _, true);
						SetEntData(LR_Player_Prisoner, g_Offset_Ammo+(iAmmoType*4), 0, _, true);
					}
					
					ChangeEdictState(Prisoner_Weapon, g_Offset_Clip1);
					ChangeEdictState(Guard_Weapon, g_Offset_Clip1);
				}
			}
			else if (type == LR_Shot4Shot)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				if ((client == LR_Player_Prisoner) || (client == LR_Player_Guard))
				{
					Prisoner_S4S_Pistol = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData));
					Guard_S4S_Pistol = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData));
					S4Slastshot = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
					
					GetEventString(event, "weapon", FiredWeapon, sizeof(FiredWeapon));
					
					iClientWeapon = GetEntDataEnt2(client, g_Offset_ActiveWeapon);
					
					if (iClientWeapon != Prisoner_S4S_Pistol && iClientWeapon != Guard_S4S_Pistol && StrContains(FiredWeapon, "knife") == -1)
					{
						if (g_Game == Game_CSGO) RightKnifeAntiCheat(client, idx);
						DecideCheatersFate(client, idx, -1);
					}
					else if (StrContains(FiredWeapon, "knife") == -1)
					{
						// update who took the last shot
						SetArrayCell(gH_DArray_LR_Partners, idx, client, view_as<int>(Block_Global1));
						
						// check for double shot situation (if they picked up another deagle with more ammo between shots)
						if (gH_Cvar_LR_S4S_DoubleShot.BoolValue && (S4Slastshot == client))
						{
							// this should no longer be possible to do without extra manipulation	
							if (g_Game == Game_CSGO) RightKnifeAntiCheat(client, idx);
							DecideCheatersFate(client, idx, -1);
						}
						else // if we didn't repeat
						{		
							if (gH_Cvar_Announce_Shot4Shot.BoolValue)
							{
								if (gH_Cvar_SendGlobalMsgs.BoolValue)
								{
									EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "S4S Shot Taken", client);
								}
								else
								{
									CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "S4S Shot Taken", client);
									CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "S4S Shot Taken", client);
								}
							}
							
							// give the opposite LR player 1 bullet in their deagle
							if (client == LR_Player_Prisoner)
							{
								// modify deagle 2s ammo
								SetEntData(Guard_S4S_Pistol, g_Offset_Clip1, 1);
							}
							else if (client == LR_Player_Guard)
							{
								// modify deagle 1s ammo
								SetEntData(Prisoner_S4S_Pistol, g_Offset_Clip1, 1);
							}
							
							if(g_Game == Game_CSGO)
							{
								SetEntProp(Guard_S4S_Pistol, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
								SetEntProp(Prisoner_S4S_Pistol, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
							}
							else
							{
								iAmmoType = GetEntProp(Prisoner_S4S_Pistol, Prop_Send, "m_iPrimaryAmmoType");
								SetEntData(LR_Player_Guard, g_Offset_Ammo+(iAmmoType*4), 0, _, true);
								SetEntData(LR_Player_Prisoner, g_Offset_Ammo+(iAmmoType*4), 0, _, true);
							}
							
							// propogate the ammo immediately! (thanks psychonic)
							ChangeEdictState(Prisoner_S4S_Pistol, g_Offset_Clip1);
							ChangeEdictState(Guard_S4S_Pistol, g_Offset_Clip1);
						}
					}
				}	
			}	
			else if (type == LR_NoScope)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				if (client == LR_Player_Prisoner || client == LR_Player_Guard)
				{
					// place delay on zoom
					iClientWeapon = GetEntDataEnt2(client, g_Offset_ActiveWeapon);
					SetEntDataFloat(iClientWeapon, g_Offset_SecAttack, GetGameTime() + 9999.0);
					
					// grab weapon choice
					int NS_Selection = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));					
					switch (NS_Selection)
					{
						case NSW_AWP:
						{
							CreateTimer(1.8, Timer_ResetZoom, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						}
						case NSW_Scout:
						{
							CreateTimer(1.3, Timer_ResetZoom, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						}
						default:
						{
							CreateTimer(0.5, Timer_ResetZoom, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
}

public Action Timer_ResetZoom(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	if (client)
	{
		SetEntData(client, g_Offset_FOV, 0, 4, true);
	}
	return Plugin_Handled;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	//LogMessage("OnTakeDamage - victim: %i | attacker: %i | inflictor: %i | damage: %.1f | weapon: %i", victim, attacker, inflictor, damage, weapon);
	if ((victim != attacker) && (victim > 0) && (victim <= MaxClients) && (attacker > 0) && (attacker <= MaxClients))
	{
		int iArraySize = GetArraySize(gH_DArray_LR_Partners);
		int LR_Player_Prisoner, LR_Player_Guard, Pistol_Prisoner, Pistol_Guard, bullet;
		char UsedWeapon[64];
		
		int iWeapon = weapon; // We don't want to modify the weapon variable, so we'll just make a copy.
		
		if (iArraySize > 0)
		{
			for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				// Check if victim or attacker are not one of the currently checked LR_Player_Prisoner or LR_Player_Guard
				if (victim != LR_Player_Prisoner && victim != LR_Player_Guard && attacker != LR_Player_Prisoner && victim != LR_Player_Guard)
				{
					// Let's improve performance and just skip here instead of checking a lot of useless things.
					continue;
				}
				
				// Now, we are guaranteed at least one of victim, attacker is LR_Player_Prisoner or LR_Player_Guard
				
				int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
				
				// Prevent players that are not in a LastRequest together from damaging each other
				if (gH_Cvar_LR_Damage.BoolValue && type != LR_Rebel) // Ignore this check for the Rebel LastRequest
				{
					// If an in-LR player attacked a non-in-LR player
					if ((attacker == LR_Player_Guard && victim != LR_Player_Prisoner) || (attacker == LR_Player_Prisoner && victim != LR_Player_Guard))
					{
						return Plugin_Handled;
					}
					// If a non-in-LR player attacked an in-LR-player
					else if ((attacker != LR_Player_Guard && victim == LR_Player_Prisoner) || (attacker != LR_Player_Prisoner && victim == LR_Player_Guard))
					{
						return Plugin_Handled;
					}
				}
				else
				{
					// gH_Cvar_LR_Damage not enabled, so let damage between in-LR players and non-in-LR player happen
					
					// If an in-LR player attacked a non-in-LR player
					if ((attacker == LR_Player_Guard && victim != LR_Player_Prisoner) || (attacker == LR_Player_Prisoner && victim != LR_Player_Guard))
					{
						return Plugin_Continue;
					}
					// If a non-in-LR player attacked an in-LR-player
					else if ((attacker != LR_Player_Guard && victim == LR_Player_Prisoner) || (attacker != LR_Player_Prisoner && victim == LR_Player_Guard))
					{
						return Plugin_Continue;
					}
				}
				
				if (Weapon_IsValid(iWeapon))
				{
					GetEntityClassname(iWeapon, UsedWeapon, sizeof(UsedWeapon));
					ReplaceString(UsedWeapon, sizeof(UsedWeapon), "weapon_", "", false); 
				}
				else if (attacker == inflictor) // Only try to get the equipped weapon if it was direct damage (see https://wiki.alliedmods.net/SDKHooks)
				{
					/* CS:S doesn't support the weapon field and will always output -1
					 * CS:GO, on the other hand, supports the weapon fields but not all weapons do.
					 * 
					 * This will try to work around this limitation by getting the currently equipped weapon. */
					GetClientWeapon(attacker, UsedWeapon, sizeof(UsedWeapon)); // Returns the currently equipped weapon classname
					ReplaceString(UsedWeapon, sizeof(UsedWeapon), "weapon_", "", false);
					
					iWeapon = GetEntDataEnt2(attacker, g_Offset_ActiveWeapon); // Get the currently equipped weapon
				}
				else
				{
					UsedWeapon[0] = '\0'; // Makes UsedWeapon an empty string
				}
				
				if (gH_Cvar_Debug.BoolValue)
					LogMessage("OnTakeDamage - victim: %i | attacker: %i | inflictor: %i | damage: %.1f | weapon: %i | iWeapon: %i | UsedWeapon: '%s'", victim, attacker, inflictor, damage, weapon, iWeapon, UsedWeapon);
				
				// if a roulette player is hurting the other contestant
				switch (type)
				{
					case LR_KnifeFight:
					{
						// Prevent indirect damage
						if (attacker != inflictor)
						{
							DecideCheatersFate(attacker, idx, -1);
							return Plugin_Handled;
						}
						
						// Check if weapon used isn't a knife
						if (!IsWeaponClassKnife(UsedWeapon))
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						
						return Plugin_Continue;
					}
					case LR_RussianRoulette:
					{
						// determine if LR weapon is being used
						Pistol_Prisoner = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData)));
						Pistol_Guard = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData)));
						
						if ((iWeapon != Pistol_Prisoner) && (iWeapon != Pistol_Guard))
						{
							//LogMessage("Russian Roulette LR: Cheating detected: Weapon used: %i - Pistol_Prisoner: %i - Pistol_Guard: %i - UsedWeapon: %s", iWeapon, Pistol_Prisoner, Pistol_Guard, UsedWeapon);
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						
						// null any damage
						// damage = 0.0;
						
						// decide if there's a winner
						bullet = GetRandomInt(1,6);
						switch (bullet)
						{
							case 1:
							{
								// KillAndReward(victim, attacker);
								damage = 200.0; // Make sure it one-shots
								EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Russian Roulette - Hit", victim);
							}
							default:
							{
								if (gH_Cvar_SendGlobalMsgs.BoolValue)
								{						
									EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Russian Roulette - Miss");
								}
								else
								{
									CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Russian Roulette - Miss");
									CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Russian Roulette - Miss");
								}
								return Plugin_Handled;
							}
						}
						return Plugin_Changed;
					}
					case LR_RockPaperScissors, LR_Race, LR_JumpContest, LR_ChickenFight, LR_HotPotato:
					{
						DecideCheatersFate(attacker, idx, victim);
						return Plugin_Handled;
					}
					case LR_Dodgeball:
					{
						char sInflictorClass[64];
						
						// If a nade is used, inflictor != attacker
						if (attacker == inflictor || !IsValidEntity(inflictor))
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						
						// Check if the inflictor is indeed a flashbang_projectile
						if (!GetEntityClassname(inflictor, sInflictorClass, sizeof(sInflictorClass)) || !StrEqual(sInflictorClass, "flashbang_projectile")) // Check that what inflicted the damage was a flashbang projectile
						{
							DecideCheatersFate(attacker, idx, -1);
							return Plugin_Handled;
						}
						
						// Also possible to check for DMG_CLUB (A grenade impact (for instance a flash hitting a teammate) will inflict damage of type DMG_CLUB.)
						return Plugin_Continue;
					}
					case LR_Shot4Shot, LR_Mag4Mag, LR_NoScope:
					{
						// Prevent indirect damage
						if (attacker != inflictor)
						{
							DecideCheatersFate(attacker, idx, -1);
							return Plugin_Handled;
						}
						
						Pistol_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData));
						Pistol_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData));
						
						if ((iWeapon != Pistol_Prisoner) && (iWeapon != Pistol_Guard))
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						
						return Plugin_Continue;
					}
					case LR_OnlyHS:
					{
						// determine if LR weapon is being used
						Pistol_Prisoner = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData)));
						Pistol_Guard = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData)));
						
						if ((iWeapon != Pistol_Prisoner) && (iWeapon != Pistol_Guard))
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						
						if (damagetype & CS_DMG_HEADSHOT) // This is the right way to check for headshots, it will take into account the spread and recoil.
						{
							damage = 200.0; // Ensures it will kill
							return Plugin_Changed;
						}
						else
						{
							Weapon_SetPrimaryClip(iWeapon, 99); // Recharges the weapon's clip to avoid running out of bullets
							return Plugin_Handled; // Prevents the shot from counting, removing the slowdown effect and bullet punch.
						}
						
						// Tracing a ray is not the way, as bullets don't always go to the center of the crosshair, especially with recoil, spread, and movement.
						
						/* HERE LIES THE OLD METHOD
						GetClientEyePosition(attacker, start);
						GetClientEyeAngles(attacker, ang);
						
						hTrace = TR_TraceRayFilterEx(start, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitEntity, attacker);
						iHitGroup = TR_GetHitGroup(hTrace);
						delete hTrace;
						
						if (!(iHitGroup == 1))
						{
							damage = 0.0;
							return Plugin_Changed;
						}
						EMP_FreeHandle(hTrace);
						*/
					}
					case LR_HEFight:
					{
						// Check if direct damage has been done. HE Grenades don't deal direct damage.
						if (attacker == inflictor)
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						
						// Prevent all non-explosive damage
						if (!(damagetype & DMG_BLAST))
						{
							DecideCheatersFate(attacker, idx, -1);
							return Plugin_Handled;
						}
						
						// Might be good to also check for the inflictor here, if possible.
						return Plugin_Continue;
					}
					case LR_Rebel:
					{
						return Plugin_Continue;
					}
					case LR_JuggernoutBattle:
					{
						// Verify if indirect damage was used
						if (attacker != inflictor)
						{
							DecideCheatersFate(attacker, idx, -1);
							return Plugin_Handled;
						}
						
						if (GetEngineVersion() == Engine_CSGO)
						{
							if (!StrEqual(UsedWeapon, "negev") && !StrEqual(UsedWeapon, "deagle") && !IsWeaponClassKnife(UsedWeapon))
							{
								DecideCheatersFate(attacker, idx, victim);
								return Plugin_Handled;
							}
						}
						else if (GetEngineVersion() == Engine_CSS)
						{
							if (!StrEqual(UsedWeapon, "m249") && !StrEqual(UsedWeapon, "deagle") && !IsWeaponClassKnife(UsedWeapon))
							{
								DecideCheatersFate(attacker, idx, victim);
								return Plugin_Handled;
							}
						}
						
						return Plugin_Continue;
					}
					case LR_FistFight:
					{
						if (!StrEqual(UsedWeapon, "fists"))
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						return Plugin_Continue;
					}
					case LR_ShieldFight:
					{
						if (!StrEqual(UsedWeapon, "shield"))
						{
							DecideCheatersFate(attacker, idx, victim);
							return Plugin_Handled;
						}
						return Plugin_Continue;
					}
					default:
					{
						return Plugin_Continue;
						
						// This verification is no longer needed because all the checks are now done earlier.
						/*
						if ((victim == LR_Player_Prisoner && attacker == LR_Player_Guard) || (victim == LR_Player_Guard && attacker == LR_Player_Prisoner))
						{
							return Plugin_Continue;
						}
						*/
					}
				}
				// return Plugin_Continue; // Shouldn't be needed, but if a case entry doesn't have this, this line will make sure we exit :)
			}
		}
	}
	return Plugin_Continue;
}  

public Action OnWeaponDecideUse(int client, int weapon)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard, HPdeagle, GTp1done, GTp2done, GTp1dropped, GTp2dropped, GTdeagle1, GTdeagle2;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
			LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
			
			switch (type)
			{
				case LR_RockPaperScissors, LR_Race, LR_JumpContest: // Add LRs which should prevent players from picking any kind of weapon
				{
					// Prevent LR players from picking up weapons
					if ((client == LR_Player_Guard || client == LR_Player_Prisoner))
					{
						return Plugin_Handled;
					}
				}
				case LR_HotPotato:
				{
					HPdeagle = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global4)));
				
					if (client != LR_Player_Guard && client != LR_Player_Prisoner && weapon == HPdeagle)
					{
						return Plugin_Handled;
					}
					else if ((client == LR_Player_Guard || client == LR_Player_Prisoner) && weapon != HPdeagle)
					{
						return Plugin_Handled;			
					}
				}
				case LR_GunToss:
				{
					GTp1done = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global3));
					GTp2done = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global4));
					GTp1dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
					GTp2dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
					GTdeagle1 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData)));
					GTdeagle2 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData)));
					
					if ((weapon == GTdeagle1 && !GTp1dropped) || (weapon == GTdeagle2 && !GTp2dropped) || Entity_ClassNameMatches(weapon, "weapon_knife"))
					{
						return Plugin_Continue;
					}
					else if ((weapon == GTdeagle1 || weapon == GTdeagle2) && (GTp1done && GTp2done))
					{
						if ((f_DoneDistance[LR_Player_Guard] > f_DoneDistance[LR_Player_Prisoner]) && (client  == LR_Player_Guard) && (weapon == GTdeagle2))
						{
							if (gH_Cvar_LR_GunToss_SlayOnLose.BoolValue) EMP_SafeSlay(LR_Player_Prisoner);
							return Plugin_Continue;
						}
						else if ((f_DoneDistance[LR_Player_Guard] < f_DoneDistance[LR_Player_Prisoner]) && (client  == LR_Player_Prisoner) && (weapon == GTdeagle1))
						{
							if (gH_Cvar_LR_GunToss_SlayOnLose.BoolValue) EMP_SafeSlay(LR_Player_Guard);
							return Plugin_Continue;
						}
						else
						{
							return Plugin_Handled;
						}
					}
					else if ((client  == LR_Player_Prisoner) || (client  == LR_Player_Guard))
					{
						return Plugin_Handled;
					}
				}
				case LR_KnifeFight:
				{
					// Prevent LR players from picking up any weapon other than a knife
					if (client == LR_Player_Guard || client == LR_Player_Prisoner)
					{
						char classname[64];
						GetEntityClassname(weapon, classname, sizeof(classname));
						if (!IsWeaponClassKnife(classname))
						{
							return Plugin_Handled;
						}
					}
				}
				case LR_ChickenFight:
				{
					if (client == LR_Player_Guard || client == LR_Player_Prisoner)
					{
						// Prevent LR players from picking up weapons IF loser auto-slay is enabled for this LR
						if (gH_Cvar_LR_ChickenFight_Slay.BoolValue)
						{
							return Plugin_Handled;
						}
						
						// Else, only prevent picking up weapons IF they're not a knife
						char classname[64];
						GetEntityClassname(weapon, classname, sizeof(classname));
						if (!IsWeaponClassKnife(classname))
						{
							return Plugin_Handled;
						}
					}
				}
				case LR_HEFight:
				{
					// Prevent LR players from picking up any weapon other than an HE Grenade
					if ((client == LR_Player_Guard || client == LR_Player_Prisoner) && !Entity_ClassNameMatches(weapon, "weapon_hegrenade"))
					{
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnWeaponEquip(int client, int weapon)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard, HPdeagle, GTp1dropped, GTp2dropped, GTp1done, GTp2done;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
			LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));

			if (client == LR_Player_Prisoner || client == LR_Player_Guard)
			{
				if (type == LR_GunToss)
				{
					GTp1dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
					GTp2dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
					GTp1done = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global3));
					GTp2done = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global4));
					
					if ((client == LR_Player_Prisoner || client == LR_Player_Guard) && Entity_ClassNameMatches(weapon, "weapon_knife"))
					{
						return Plugin_Continue;
					}
					
					if (client == LR_Player_Prisoner && GTp1dropped && !GTp1done)
					{
						if (Entity_ClassNameMatches(weapon, "weapon_deagle"))
						{
							SetArrayCell(gH_DArray_LR_Partners, idx, true, view_as<int>(Block_Global3));
							return Plugin_Continue;
						}		
					}
					else if (client == LR_Player_Guard && GTp2dropped && !GTp2done)
					{
						if (Entity_ClassNameMatches(weapon, "weapon_deagle"))
						{
							SetArrayCell(gH_DArray_LR_Partners, idx, true, view_as<int>(Block_Global4));
							return Plugin_Continue;
						}
					}
					
					if (Entity_ClassNameMatches(weapon, "weapon_deagle"))
					{
						if ((GTp1done && GTp2done) && (GTp1dropped && GTp2dropped))
						{
							if ((f_DoneDistance[LR_Player_Guard] > f_DoneDistance[LR_Player_Prisoner]) && (client == LR_Player_Guard))
							{
								return Plugin_Continue;
							}
							else if ((f_DoneDistance[LR_Player_Guard] < f_DoneDistance[LR_Player_Prisoner]) && (client == LR_Player_Prisoner))
							{
								return Plugin_Continue;
							}
							else
							{
								return Plugin_Handled;
							}
						}
					}
					else
					{
						return Plugin_Handled;
					}
				}
				else if (type == LR_HotPotato)
				{
					HPdeagle = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global4)));
					if (weapon == HPdeagle)
					{
						SetArrayCell(gH_DArray_LR_Partners, idx, client, view_as<int>(Block_Global1)); // HPloser
						if (gH_Cvar_LR_HotPotato_Mode.IntValue != 2)
						{
							SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", gH_Cvar_LR_HotPotato_Speed.FloatValue);
							// reset other player's speed
							SetEntPropFloat((client == LR_Player_Prisoner ? LR_Player_Guard : LR_Player_Prisoner), 
								Prop_Data, "m_flLaggedMovementValue", 1.0);
						}
						
						if (gH_Cvar_Announce_HotPotato_Eqp.BoolValue)
						{
							if (gH_Cvar_SendGlobalMsgs.BoolValue)
							{
								EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Hot Potato PickUp", client);
							}
							else
							{
								CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Hot Potato Pickup", client);
								CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Hot Potato Pickup", client);
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action OnWeaponDrop(int client, int weapon)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard, GTp1dropped, GTp2dropped, GTdeagle1, GTdeagle2;
		Handle PositionDataPack;
		float GTp1droppos[3], GTp2droppos[3];
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_RussianRoulette)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				if (client == LR_Player_Prisoner || client == LR_Player_Guard)
				{
					return Plugin_Handled;
				}
			}
			else if (type == LR_ShieldFight)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				if (client == LR_Player_Prisoner || client == LR_Player_Guard)
				{
					return Plugin_Handled;
				}
			}
			else if (type == LR_GunToss)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				GTp1dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
				GTp2dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				
				if (client == LR_Player_Prisoner || client == LR_Player_Guard)
				{
					GTdeagle1 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData)));
					GTdeagle2 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData)));
					
					if (((client == LR_Player_Prisoner && GTp1dropped) || 
						(client == LR_Player_Guard && GTp2dropped)))
					{
						if (IsValidEntity(weapon))
						{
							if (Entity_ClassNameMatches(weapon, "weapon_deagle"))
							{
								CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Already Dropped Deagle");
								return Plugin_Handled;
							}
						}
					}
					else
					{
						PositionDataPack = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_DataPackHandle));
						if (client == LR_Player_Prisoner)
						{
							if (IsValidEntity(GTdeagle1))
							{
								SetEntData(GTdeagle1, g_Offset_Clip1, 250);
							}
							
							if (weapon == GTdeagle1)
							{
								GetClientAbsOrigin(LR_Player_Prisoner, GTp1droppos);
								#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 8
									SetPackPosition(PositionDataPack, view_as<DataPackPos>(12));
								#else
									SetPackPosition(PositionDataPack, 12);
								#endif
								WritePackFloat(PositionDataPack, GTp1droppos[0]);
								WritePackFloat(PositionDataPack, GTp1droppos[1]);
								WritePackFloat(PositionDataPack, GTp1droppos[2]);
								
								SetArrayCell(gH_DArray_LR_Partners, idx, true, view_as<int>(Block_Global1));
								
								if (gH_Cvar_LR_Ten_Timer.BoolValue)
								{
									CreateTimer(10.0, Timer_EnemyMustThrow, TIMER_FLAG_NO_MAPCHANGE);
									CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "GT Throw Warning");
								}
							}
						}
						else if (client == LR_Player_Guard)
						{
							if (IsValidEntity(GTdeagle2))
							{
								SetEntData(GTdeagle2, g_Offset_Clip1, 250);
							}

							if (weapon == GTdeagle2)
							{
								GetClientAbsOrigin(LR_Player_Guard, GTp2droppos);
								#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 8
									SetPackPosition(PositionDataPack, view_as<DataPackPos>(15));
								#else
									SetPackPosition(PositionDataPack, 15);
								#endif
								WritePackFloat(PositionDataPack, GTp2droppos[0]);
								WritePackFloat(PositionDataPack, GTp2droppos[1]);
								WritePackFloat(PositionDataPack, GTp2droppos[2]);
								
								SetArrayCell(gH_DArray_LR_Partners, idx, true, view_as<int>(Block_Global2));
								
								if (gH_Cvar_LR_Ten_Timer.BoolValue)
								{
									CreateTimer(10.0, Timer_EnemyMustThrow, TIMER_FLAG_NO_MAPCHANGE);
									CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "GT Throw Warning");
								}
							}
						}
						
						if (g_GunTossTimer == INVALID_HANDLE && (weapon == GTdeagle1 || weapon == GTdeagle2))
						{
							if (g_Game == Game_CSS)
							{
								g_GunTossTimer = CreateTimer(0.1, Timer_GunToss, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							}
							else if (g_Game == Game_CSGO)
							{
								g_GunTossTimer = CreateTimer(1.0, Timer_GunToss, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}	}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_EnemyMustThrow(Handle timer)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard, GTp1dropped, GTp2dropped;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_GunToss)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				GTp1dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
				GTp2dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				
				if (GTp1dropped && !GTp2dropped)
				{
					KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "GT No Throw", LR_Player_Prisoner, LR_Player_Guard);
				}
				else if (!GTp1dropped && GTp2dropped)
				{
					KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "GT No Throw", LR_Player_Guard, LR_Player_Prisoner);
				}
			}
		}
	}
	return Plugin_Stop;
}

void OnPreThink(int client)
{
	if (gH_DArray_LR_Partners != INVALID_HANDLE)
	{
		int iArraySize = GetArraySize(gH_DArray_LR_Partners);
		if (iArraySize > 0)
		{
			int LR_Player_Prisoner, LR_Player_Guard;
			for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
			{
				int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
				if (type == LR_KnifeFight)
				{
					int KnifeChoice = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
					if(KnifeChoice == Knife_ThirdPerson)
					{
						LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
						LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
						
						if (client == LR_Player_Prisoner || client == LR_Player_Guard)
						{
							SetThirdPerson(client);
						}
					}
				}
			}
		}
	}
}

void LastRequest_OnMapStart()
{
	// Precache any materials needed
	if (g_Game == Game_CSS)
	{
		BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
		LaserSprite = PrecacheModel("materials/sprites/lgtning.vmt");
		LaserHalo = PrecacheModel("materials/sprites/plasmahalo.vmt");
	}
	else if (g_Game == Game_CSGO)
	{
		BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
		LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		LaserHalo = PrecacheModel("materials/sprites/light_glow02.vmt");
	}
	
	// Fix for problems with g_BeaconTimer not being set to null on timer terminating (TIMER_FLAG_NO_MAPCHANGE)
	if (g_BeaconTimer != INVALID_HANDLE)
	{
		g_BeaconTimer = INVALID_HANDLE;
	}
	// Fix for the same problem with g_CountdownTimer
	if (g_CountdownTimer != INVALID_HANDLE)
	{
		g_CountdownTimer = INVALID_HANDLE;
	}
}

void LastRequest_OnConfigsExecuted()
{
	if (!g_bPushedToMenu)
	{
		int iIndex = 0;
		// Check LRs
		if (gH_Cvar_LR_KnifeFight_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_KnifeFight);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_Shot4Shot_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_Shot4Shot);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_GunToss_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_GunToss);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_ChickenFight_On.IntValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_ChickenFight);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_HotPotato_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_HotPotato);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_Dodgeball_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_Dodgeball);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_NoScope_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_NoScope);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_RockPaperScissors_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_RockPaperScissors);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_Rebel_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_Rebel);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_Mag4Mag_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_Mag4Mag);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_Race_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_Race);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_RussianRoulette_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_RussianRoulette);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_JumpContest_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_JumpContest);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_ShieldFight_On.BoolValue && g_Game == Game_CSGO)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_ShieldFight);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_FistFight_On.BoolValue && g_Game == Game_CSGO)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_FistFight);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_JuggernoutBattle_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_JuggernoutBattle);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_OnlyHS_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_OnlyHS);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
		if (gH_Cvar_LR_HEFight_On.BoolValue)
		{
			iIndex = PushArrayCell(gH_DArray_LastRequests, LR_HEFight);
			SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
		}
	}
	g_bPushedToMenu = true;
	
	// check for -1 for backward compatibility
	MediaType soundfile = type_Sound;
	char buffer[PLATFORM_MAX_PATH];
	gH_Cvar_LR_NoScope_Sound.GetString(buffer, sizeof(buffer));
	if ((strlen(buffer) > 0) && strcmp(buffer, "-1") != 0)
	{		
		CacheTheFile(buffer, soundfile);
	}
	gH_Cvar_LR_Sound.GetString(buffer, sizeof(buffer));
	if ((strlen(buffer) > 0) && strcmp(buffer, "-1") != 0)
	{
		CacheTheFile(buffer, soundfile);
	}
	gH_Cvar_LR_Beacon_Sound.GetString(buffer, sizeof(buffer));
	if ((strlen(buffer) > 0) && strcmp(buffer, "-1") != 0)
	{
		CacheTheFile(buffer, soundfile);
	}

	if (gH_Cvar_LR_BlockSuicide.BoolValue && !g_bListenersAdded)
	{
		AddCommandListener(Suicide_Check, "kill");
		AddCommandListener(Suicide_Check, "explode");
		AddCommandListener(Suicide_Check, "jointeam");
		AddCommandListener(Suicide_Check, "spectate");
		g_bListenersAdded = true;
	}
	else if (!gH_Cvar_LR_BlockSuicide.BoolValue && g_bListenersAdded)
	{
		RemoveCommandListener(Suicide_Check, "kill");
		RemoveCommandListener(Suicide_Check, "explode");
		RemoveCommandListener(Suicide_Check, "jointeam");
		RemoveCommandListener(Suicide_Check, "spectate");
		g_bListenersAdded = false;
	}
}

public void ConVarChanged_Setting(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == gH_Cvar_LR_BlockSuicide)
	{
		if (gH_Cvar_LR_BlockSuicide.BoolValue && !g_bListenersAdded)
		{
			AddCommandListener(Suicide_Check, "kill");
			AddCommandListener(Suicide_Check, "explode");
			AddCommandListener(Suicide_Check, "jointeam");
			AddCommandListener(Suicide_Check, "spectate");
			g_bListenersAdded = true;
		}
		else if (!gH_Cvar_LR_BlockSuicide.BoolValue && g_bListenersAdded)
		{
			RemoveCommandListener(Suicide_Check, "kill");
			RemoveCommandListener(Suicide_Check, "explode");
			RemoveCommandListener(Suicide_Check, "jointeam");
			RemoveCommandListener(Suicide_Check, "spectate");
			g_bListenersAdded = false;
		}
		
	}
}

public Action Suicide_Check(int client, const char[] command, int args)
{
	if (EMP_IsValidClient(client, false, true) && Local_IsClientInLR(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void UpdateLastRequestArray(int entry)
{
	int iArrayIndex = FindValueInArray(gH_DArray_LastRequests, entry);
	if (iArrayIndex == -1)
	{
		int iIndex = PushArrayCell(gH_DArray_LastRequests, entry);
		SetArrayCell(gH_DArray_LastRequests, iIndex, true, 1);
	}
	else
	{
		RemoveFromArray(gH_DArray_LastRequests, iArrayIndex);
	}
}

public void ConVarChanged_LastRequest(Handle cvar, const char[] oldValue, const char[] newValue)
{
	// Perform boolean checking
	int iNewValue = StringToInt(newValue);
	int iOldValue = StringToInt(oldValue);
	if (iNewValue == iOldValue || !g_bPushedToMenu)
	{
		return;
	}
	
	if (cvar == gH_Cvar_LR_KnifeFight_On)
	{
		UpdateLastRequestArray(LR_KnifeFight);
	}
	else if (cvar == gH_Cvar_LR_Shot4Shot_On)
	{
		UpdateLastRequestArray(LR_Shot4Shot);
	}
	else if (cvar == gH_Cvar_LR_GunToss_On)
	{
		UpdateLastRequestArray(LR_GunToss);
	}
	else if (cvar == gH_Cvar_LR_ChickenFight_On)
	{
		UpdateLastRequestArray(LR_ChickenFight);
	}
	else if (cvar == gH_Cvar_LR_HotPotato_On)
	{
		UpdateLastRequestArray(LR_HotPotato);
	}
	else if (cvar == gH_Cvar_LR_Dodgeball_On)
	{
		UpdateLastRequestArray(LR_Dodgeball);
	}
	else if (cvar == gH_Cvar_LR_NoScope_On)
	{
		UpdateLastRequestArray(LR_NoScope);
	}
	else if (cvar == gH_Cvar_LR_RockPaperScissors_On)
	{
		UpdateLastRequestArray(LR_RockPaperScissors);
	}
	else if (cvar == gH_Cvar_LR_Rebel_On)
	{
		UpdateLastRequestArray(LR_Rebel);
	}
	else if (cvar == gH_Cvar_LR_Mag4Mag_On)
	{
		UpdateLastRequestArray(LR_Mag4Mag);
	}
	else if (cvar == gH_Cvar_LR_Race_On)
	{
		UpdateLastRequestArray(LR_Race);
	}
	else if (cvar == gH_Cvar_LR_RussianRoulette_On)
	{
		UpdateLastRequestArray(LR_RussianRoulette);
	}
	else if (cvar == gH_Cvar_LR_JumpContest_On)
	{
		UpdateLastRequestArray(LR_JumpContest);
	}
	else if (cvar == gH_Cvar_LR_ShieldFight_On && g_Game == Game_CSGO)
	{
		UpdateLastRequestArray(LR_ShieldFight);
	}
	else if (cvar == gH_Cvar_LR_FistFight_On && g_Game == Game_CSGO)
	{
		UpdateLastRequestArray(LR_FistFight);
	}
	else if (cvar == gH_Cvar_LR_JuggernoutBattle_On)
	{
		UpdateLastRequestArray(LR_JuggernoutBattle);
	}
	else if (cvar == gH_Cvar_LR_OnlyHS_On)
	{
		UpdateLastRequestArray(LR_OnlyHS);
	}
	else if (cvar == gH_Cvar_LR_HEFight_On)
	{
		UpdateLastRequestArray(LR_HEFight);
	}
}

bool IsLastRequestAutoStart(int game)
{
	int iArrayIndex = FindValueInArray(gH_DArray_LastRequests, game);
	if (iArrayIndex == -1)
	{
		return false;
	}
	else
	{
		return view_as<bool>(GetArrayCell(gH_DArray_LastRequests, iArrayIndex, 1));
	}
}

void LastRequest_ClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponDecideUse);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
	if (g_Game == Game_CSGO)
	{
		SDKHook(client, SDKHook_PreThink, OnPreThink);
	}
}

public Action Command_LastRequest(int client, int args)
{
	if (gH_Cvar_LR_Enable.BoolValue)
	{
		if (!BlockLR)
		{
			if (!LR_Player_OnCD[client] || !gH_Cvar_LR_Race_CDOnCancel.BoolValue)
			{
				if (g_bIsLRAvailable)
				{
					if (!g_bInLastRequest[client])
					{
						if (EMP_IsValidClient(client, false, false, CS_TEAM_T))
						{
							if (g_bIsARebel[client] && !gH_Cvar_RebelHandling.IntValue)
							{
								CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Rebel Not Allowed");
							}
							else
							{
								if ((g_Game == Game_CSGO && GameRules_GetProp("m_bWarmupPeriod") == 0) || g_Game == Game_CSS)
								{
									// check the number of terrorists still alive
									int Ts, CTs, NumCTsAvailable;
									UpdatePlayerCounts(Ts, CTs, NumCTsAvailable);

									if (Ts <= gH_Cvar_MaxPrisonersToLR.IntValue || gH_Cvar_MaxPrisonersToLR.IntValue == 0)
									{
										if (CTs > 0)
										{
											if (NumCTsAvailable > 0)
											{
												if (g_Game == Game_CSGO)
												{
													int RoundTime = GetConVarInt(g_hRoundTime) * 60;
													int GraceTime = GetConVarInt(g_cvGraceTime);
													int FreezeTime = GetConVarInt(g_cvFreezeTime);
													
													int ToCheckTime = (RoundTime - GraceTime - FreezeTime);
												
													if (g_RoundTime < ToCheckTime)
													{
														DisplayLastRequestMenu(client, Ts, CTs);
													}
													else
													{
														CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Grace TimeBlock");
													}
												}
												else if (g_Game == Game_CSS)
												{
													DisplayLastRequestMenu(client, Ts, CTs);
												}
											}
											else
											{
												CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR No CTs Available");
											}
										}
										else
										{
											CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "No CTs Alive");
										}
									}
									else
									{
										CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Many Ts");
									}
								}
								else
								{
									CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Blocked Warmup");
								}
							}
						}
						else
						{
							CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Not Alive Or In Wrong Team");
						}
					}
					else
					{
						CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Another LR In Progress");
					}
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Race CoolDown");
			}
		}
		else
		{
			CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Block EventDay");
		}
	}
	else
	{
		CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
	}

	return Plugin_Handled;
}

public Action Timer_RoundTimeLeft(Handle timer, int RoundTime)
{
	if (g_RoundTime != 0)
	{
		g_RoundTime = g_RoundTime - 1;
		
		if (g_bBW)
			BlockLR = (IsEventDayActive()) ? true : false;
		
		if (g_bMYJB)
		{
			if (GetFeatureStatus(FeatureType_Native, "MyJailbreak_IsEventDayRunning") == FeatureStatus_Available)
			{
				BlockLR = (MyJailbreak_IsEventDayRunning()) ? true : false;
			}
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

void DisplayLastRequestMenu(int client, int Ts, int CTs)
{
	gH_BuildLR[client] = CreateDataPack();
	Handle menu = CreateMenu(LR_Selection_Handler);
	SetMenuTitle(menu, "%t", "LR Choose", client);
	
	char sDataField[MAX_DATAENTRY_SIZE];
	char sTitleField[MAX_DISPLAYNAME_SIZE];
	int iLR_ArraySize = GetArraySize(gH_DArray_LastRequests);
	int iCustomCount = 0;
	int iCustomLR_Size = GetArraySize(gH_DArray_LR_CustomNames);
	int entry;
	for (int iLR_Index = 0; iLR_Index < iLR_ArraySize; iLR_Index++)
	{
		entry = GetArrayCell(gH_DArray_LastRequests, iLR_Index);
		if (entry < LR_Number)
		{
			if (entry != LR_Rebel || (entry == LR_Rebel && Ts <= gH_Cvar_LR_Rebel_MaxTs.IntValue && CTs >= gH_Cvar_LR_Rebel_MinCTs.IntValue))
			{
				FormatEx(sDataField, sizeof(sDataField), "%d", entry);
				FormatEx(sTitleField, sizeof(sTitleField), "%t", g_sLastRequestPhrase[entry], client);
				AddMenuItem(menu, sDataField, sTitleField);
			}
		}
		else
		{
			if (iCustomCount < iCustomLR_Size)
			{
				FormatEx(sDataField, sizeof(sDataField), "%d", entry);
				GetArrayString(gH_DArray_LR_CustomNames, iCustomCount, sTitleField, MAX_DISPLAYNAME_SIZE);
				AddMenuItem(menu, sDataField, sTitleField);
				iCustomCount++;
			}
		}
	}
	
	SetMenuExitButton(menu, gH_Cvar_LR_KillTimeouts.BoolValue ? false : true);
	DisplayMenu(menu, client, gH_Cvar_LR_MenuTime.IntValue);
}

int LR_Selection_Handler(Handle menu, MenuAction action, int client, int iButtonChoice)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (g_bIsLRAvailable)
			{
				if (!g_bInLastRequest[client])
				{
					if (EMP_IsValidClient(client, false, false, CS_TEAM_T))
					{
						char sData[MAX_DATAENTRY_SIZE];
						GetMenuItem(menu, iButtonChoice, sData, sizeof(sData));
						int choice = StringToInt(sData);
						g_LRLookup[client] = choice;
						
						switch (choice)
						{
							case LR_KnifeFight:
							{
								Handle KnifeFightMenu = CreateMenu(SubLRType_MenuHandler);								
								SetMenuTitle(KnifeFightMenu, "%t", "Knife Fight Selection Menu", client);
								
								char sSubTypeName[MAX_DISPLAYNAME_SIZE];
								char sDataField[MAX_DATAENTRY_SIZE];
								FormatEx(sDataField, sizeof(sDataField), "%d", Knife_Vintage);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Knife_Vintage", client);
								AddMenuItem(KnifeFightMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Knife_Drunk);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Knife_Drunk", client);
								AddMenuItem(KnifeFightMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Knife_Drugs);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Knife_Drugs", client);
								AddMenuItem(KnifeFightMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Knife_LowGrav);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Knife_LowGrav", client);
								AddMenuItem(KnifeFightMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Knife_HiSpeed);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Knife_HiSpeed", client);
								AddMenuItem(KnifeFightMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Knife_ThirdPerson);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Knife_ThirdPerson", client);
								AddMenuItem(KnifeFightMenu, sDataField, sSubTypeName);
								
								SetMenuExitBackButton(KnifeFightMenu, true);
								DisplayMenu(KnifeFightMenu, client, 10);
							}
							case LR_Shot4Shot, LR_Mag4Mag:
							{
								Handle SubWeaponMenu = CreateMenu(SubLRType_MenuHandler);
								SetMenuTitle(SubWeaponMenu, "%t", "Pistol Selection Menu", client);
								
								char sSubTypeName[MAX_DISPLAYNAME_SIZE];
								char sDataField[MAX_DATAENTRY_SIZE];
								FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_Deagle);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_Deagle", client);
								AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_P228);
								if (g_Game == Game_CSS)
								{
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_P228", client);
								}
								else if (g_Game == Game_CSGO)
								{
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_P250", client);
								}
								AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);								
								FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_Glock);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_Glock", client);
								AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);		
								FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_FiveSeven);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_FiveSeven", client);
								AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);		
								FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_Dualies);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_Dualies", client);
								AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);		
								FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_USP);
								if (g_Game == Game_CSS)
								{
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_USP", client);
								}
								else if (g_Game == Game_CSGO)
								{
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_P2000", client);
								}
								AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);
								if (g_Game == Game_CSGO)
								{
									FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_Tec9);
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_Tec9", client);
									AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);
									FormatEx(sDataField, sizeof(sDataField), "%d", Pistol_Revolver);
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Pistol_Revolver", client);
									AddMenuItem(SubWeaponMenu, sDataField, sSubTypeName);
								}
								
								SetMenuExitBackButton(SubWeaponMenu, true);
								DisplayMenu(SubWeaponMenu, client, 10);
							}					
							case LR_NoScope:
							{
								if (gH_Cvar_LR_NoScope_Weapon.IntValue == 2)
								{
									Handle NSweaponMenu = CreateMenu(SubLRType_MenuHandler);
									SetMenuTitle(NSweaponMenu, "%t", "NS Weapon Chooser Menu", client);

									char sSubTypeName[MAX_DISPLAYNAME_SIZE];
									char sDataField[MAX_DATAENTRY_SIZE];
									FormatEx(sDataField, sizeof(sDataField), "%d", NSW_AWP);
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "NSW_AWP", client);	
									AddMenuItem(NSweaponMenu, sDataField, sSubTypeName);
									FormatEx(sDataField, sizeof(sDataField), "%d", NSW_Scout);
									if (g_Game == Game_CSS)
									{
										FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "NSW_Scout", client);
									}
									else if (g_Game == Game_CSGO)
									{
										FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "NSW_SSG08", client);
									}
									AddMenuItem(NSweaponMenu, sDataField, sSubTypeName);
									FormatEx(sDataField, sizeof(sDataField), "%d", NSW_SG550);
									if (g_Game == Game_CSS)
									{
										FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "NSW_SG550", client);
									}
									else if (g_Game == Game_CSGO)
									{
										FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "NSW_SCAR20", client);
									}
									AddMenuItem(NSweaponMenu, sDataField, sSubTypeName);
									FormatEx(sDataField, sizeof(sDataField), "%d", NSW_G3SG1);
									FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "NSW_G3SG1", client);	
									AddMenuItem(NSweaponMenu, sDataField, sSubTypeName);
			
									SetMenuExitButton(NSweaponMenu, true);
									DisplayMenu(NSweaponMenu, client, 10);							
								}
								else
								{
									CreateMainPlayerHandler(client);
								}
							}
							case LR_Race:
							{								
								// create menu for T to choose start point
								Handle racemenu1 = CreateMenu(RaceStartPointHandler);
								SetMenuTitle(racemenu1, "%t", "Find a Starting Location", client);
								char sMenuText[MAX_DISPLAYNAME_SIZE];
								FormatEx(sMenuText, sizeof(sMenuText), "%t", "Use Current Position", client);
								AddMenuItem(racemenu1, "startloc", sMenuText);
								SetMenuExitButton(racemenu1, true);
								DisplayMenu(racemenu1, client, MENU_TIME_FOREVER);						
								
								if (gH_Cvar_LR_Race_NotifyCTs.BoolValue)
								{
									for (int idx = 1; idx <= MaxClients; idx++)
									{
										if (EMP_IsValidClient(idx, false, false, CS_TEAM_CT))
										{
											CPrintToChat(idx, "%s%t", gShadow_Hosties_ChatBanner, "Race Could Start Soon", client);
										}
									}
								}
							}
							case LR_Rebel:
							{
								int gametype = g_LRLookup[client];
								int iArrayIndex = PushArrayCell(gH_DArray_LR_Partners, gametype);
								SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, client, view_as<int>(Block_Prisoner));
								SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, client, view_as<int>(Block_Guard));
								g_bInLastRequest[client] = true;
								g_bIsARebel[client] = true;
								InitializeGame(iArrayIndex);
							}
							case LR_JumpContest:
							{
								Handle SubJumpMenu = CreateMenu(SubLRType_MenuHandler);
								SetMenuTitle(SubJumpMenu, "%t", "Jump Contest Menu", client);
								
								char sSubTypeName[MAX_DISPLAYNAME_SIZE];
								char sDataField[MAX_DATAENTRY_SIZE];
								
								FormatEx(sDataField, sizeof(sDataField), "%d", Jump_TheMost);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Jump_TheMost", client);
								AddMenuItem(SubJumpMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", Jump_Farthest);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Jump_Farthest", client);
								AddMenuItem(SubJumpMenu, sDataField, sSubTypeName);								
								FormatEx(sDataField, sizeof(sDataField), "%d", Jump_BrinkOfDeath);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "%t", "Jump_BrinkOfDeath", client);
								AddMenuItem(SubJumpMenu, sDataField, sSubTypeName);		
								
								SetMenuExitBackButton(SubJumpMenu, true);
								DisplayMenu(SubJumpMenu, client, 10);
							}
							case LR_OnlyHS:
							{
								Handle SubOHSMenu = CreateMenu(SubLRType_MenuHandler);
								SetMenuTitle(SubOHSMenu, "%t", "Only Headshot", client);
								
								char sSubTypeName[MAX_DISPLAYNAME_SIZE];
								char sDataField[MAX_DATAENTRY_SIZE];
								
								FormatEx(sDataField, sizeof(sDataField), "%d", OHS_AWP);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "AWP", client);
								AddMenuItem(SubOHSMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", OHS_Deagle);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "Desert Eagle", client);
								AddMenuItem(SubOHSMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", OHS_Fiveseven);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "Fiveseven", client);
								AddMenuItem(SubOHSMenu, sDataField, sSubTypeName);
								FormatEx(sDataField, sizeof(sDataField), "%d", OHS_AK);
								FormatEx(sSubTypeName, sizeof(sSubTypeName), "AK-47", client);
								AddMenuItem(SubOHSMenu, sDataField, sSubTypeName);
								
								SetMenuExitBackButton(SubOHSMenu, true);
								DisplayMenu(SubOHSMenu, client, 10);
							}
							default:
							{
								CreateMainPlayerHandler(client);
							}
						}
					}
					else
					{
						CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Not Alive Or In Wrong Team");
					}
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Another LR In Progress");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
			}
		}
		case MenuAction_End:
		{
			if (EMP_IsValidClient(client))
			{
				EMP_FreeHandle(gH_BuildLR[client]);
			}
			EMP_FreeHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (gH_Cvar_LR_KillTimeouts.BoolValue)
			{
				if (g_Game == Game_CSGO)
				{
					CreateTimer(0.1, Timer_SafeSlay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					EMP_SafeSlay(client);
				}
			}
		}
	}
	return 0;
}

void CreateMainPlayerHandler(int client)
{
	Handle playermenu = CreateMenu(MainPlayerHandler);
	SetMenuTitle(playermenu, "%t", "Choose A Player", client);

	int iNumCTsAvailable = 0;
	int iUserId = 0;
	char sClientName[MAX_DISPLAYNAME_SIZE];
	char sDataField[MAX_DATAENTRY_SIZE];
	for(int i = 1; i <= MaxClients; i++)
	{
		// if player is alive and CT and not in another LR
		if (EMP_IsValidClient(i, false, false, CS_TEAM_CT) && !g_bInLastRequest[i]) //30W
		{
			FormatEx(sClientName, sizeof(sClientName), "%N", i);
			iUserId = GetClientUserId(i);
			FormatEx(sDataField, sizeof(sDataField), "%d", iUserId);
			AddMenuItem(playermenu, sDataField, sClientName);
			iNumCTsAvailable++;
		}
	}

	if (iNumCTsAvailable == 0)
	{
		CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR No CTs Available");
		if (EMP_IsValidClient(client))
		{
			EMP_FreeHandle(gH_BuildLR[client]);
		}
		EMP_FreeHandle(playermenu);
	}
	else
	{
		SetMenuExitButton(playermenu, true);
		DisplayMenu(playermenu, client, gH_Cvar_LR_MenuTime.IntValue);
	}
}

int SubLRType_MenuHandler(Handle SelectionMenu, MenuAction action, int client, int iMenuChoice)
{
	if (action == MenuAction_Select)
	{
		if (g_bIsLRAvailable)
		{
			if (!g_bInLastRequest[client])
			{
				if (EMP_IsValidClient(client, false, false, CS_TEAM_T))
				{
					char sDataField[MAX_DATAENTRY_SIZE];	
					GetMenuItem(SelectionMenu, iMenuChoice, sDataField, sizeof(sDataField));
					int iSelection = StringToInt(sDataField);
					WritePackCell(gH_BuildLR[client], iSelection);
					CreateMainPlayerHandler(client);
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Not Alive Or In Wrong Team");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Slow Another LR In Progress");
			}
		}
		else
		{
			CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
		}
	}
	else if (action == MenuAction_End)
	{
		if (EMP_IsValidClient(client))
		{
			EMP_FreeHandle(gH_BuildLR[client]);
		}
		EMP_FreeHandle(SelectionMenu);
	}
	return 0;
}

int RaceEndPointHandler(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (g_bIsLRAvailable)
		{
			if (!g_bInLastRequest[client])
			{
				if (EMP_IsValidClient(client, false, false, CS_TEAM_T))
				{
					if (gH_Cvar_LR_Race_AirPoints.BoolValue || (GetEntityFlags(client) & FL_ONGROUND))
					{
						// use this location
						float f_EndLocation[3];
						GetClientAbsOrigin(client, f_EndLocation);
						f_EndLocation[2] += 10;
						
						WritePackFloat(gH_BuildLR[client], f_EndLocation[0]);
						WritePackFloat(gH_BuildLR[client], f_EndLocation[1]);
						WritePackFloat(gH_BuildLR[client], f_EndLocation[2]);
						
						// get start location
						float f_StartLocation[3];
						ResetPack(gH_BuildLR[client]);
						f_StartLocation[0] = ReadPackFloat(gH_BuildLR[client]);
						f_StartLocation[1] = ReadPackFloat(gH_BuildLR[client]);
						f_StartLocation[2] = ReadPackFloat(gH_BuildLR[client]);
						
						// check how far the requested end is from the start
						float distanceBetweenPoints = GetVectorDistance(f_StartLocation, f_EndLocation, false);
						
						if (distanceBetweenPoints > 300.0)
						{
							TE_SetupBeamRingPoint(f_EndLocation, 100.0, 130.0, BeamSprite, HaloSprite, 0, 15, 20.0, 7.0, 0.0, greenColor, 1, 0);
							TE_SendToAll();
							
							// allow them to choose a player finally
							CreateMainPlayerHandler(client);
						}
						else
						{
							CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Race Points too Close");
							CreateRaceEndPointMenu(client);
						}
					}
					else
					{
						CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Must Be On Ground");
						CreateRaceEndPointMenu(client);
					}
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Not Alive Or In Wrong Team");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Slow Another LR In Progress");
			}
		}
		else
		{
			CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
		}
	}
	else if (action == MenuAction_End)
	{
		if (EMP_IsValidClient(client))
		{
			EMP_FreeHandle(gH_BuildLR[client]);
		}
		EMP_FreeHandle(menu);
	}
	return 0;
}

int RaceStartPointHandler(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (g_bIsLRAvailable)
		{
			if (!g_bInLastRequest[client])
			{
				if (EMP_IsValidClient(client, false, false, CS_TEAM_T))
				{
					if (gH_Cvar_LR_Race_AirPoints.BoolValue || (GetEntityFlags(client) & FL_ONGROUND))
					{
						// use this location
						float f_StartPoint[3];
						GetClientAbsOrigin(client, f_StartPoint);
						f_StartPoint[2] += 10;

						TE_SetupBeamRingPoint(f_StartPoint, 100.0, 130.0, BeamSprite, HaloSprite, 0, 15, 30.0, 7.0, 0.0, yellowColor, 1, 0);
						TE_SendToAll();
						
						// write start point
						WritePackFloat(gH_BuildLR[client], f_StartPoint[0]);
						WritePackFloat(gH_BuildLR[client], f_StartPoint[1]);
						WritePackFloat(gH_BuildLR[client], f_StartPoint[2]);
						
						CreateRaceEndPointMenu(client);
					}
					else
					{
						CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Must Be On Ground");
					}
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Not Alive Or In Wrong Team");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Slow Another LR In Progress");
			}
		}
		else
		{
			CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
		}
	}
	else if (action == MenuAction_End)
	{
		if (EMP_IsValidClient(client))
		{
			if (gH_BuildLR[client] != INVALID_HANDLE)
			{
				EMP_FreeHandle(gH_BuildLR[client]);
				
				if (gH_Cvar_LR_Race_NotifyCTs.BoolValue)
				{
					for (int idx = 1; idx <= MaxClients; idx++)
					{
						if (EMP_IsValidClient(client, false, false, CS_TEAM_CT))
						{
							CPrintToChat(idx, "%s%t", gShadow_Hosties_ChatBanner, "Race Aborted", client);
						}
					}
				}
				
				if (gH_Cvar_LR_Race_CDOnCancel.BoolValue)
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Race CoolDown");
					LR_Player_OnCD[client] = true;
					CreateTimer(10.0, Timer_RaceCD, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		EMP_FreeHandle(menu);
	}
	return 0;
}

public Action Timer_RaceCD(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Race CoolDown Done");
	LR_Player_OnCD[client] = false;
	return Plugin_Stop;
}

void CreateRaceEndPointMenu(int client)
{
	Handle EndPointMenu = CreateMenu(RaceEndPointHandler);
	SetMenuTitle(EndPointMenu, "%t", "Choose an End Point", client);
	char sMenuText[MAX_DISPLAYNAME_SIZE];
	FormatEx (sMenuText, sizeof(sMenuText), "%t", "Use Current Position", client);
	AddMenuItem(EndPointMenu, "endpoint", sMenuText);
	SetMenuExitButton(EndPointMenu, true);
	DisplayMenu(EndPointMenu, client, MENU_TIME_FOREVER);
}

int MainPlayerHandler(Handle playermenu, MenuAction action, int client, int iButtonChoice)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (g_bIsLRAvailable)
			{
				if (!g_bInLastRequest[client])
				{
					char sData[MAX_DATAENTRY_SIZE];
					GetMenuItem(playermenu, iButtonChoice, sData, sizeof(sData));
					int ClientIdxOfCT = GetClientOfUserId(StringToInt(sData));
					
					if (EMP_IsValidClient(client, false, false, CS_TEAM_T))
					{
						// check the number of terrorists still alive
						int Ts, CTs, iNumCTsAvailable;
						UpdatePlayerCounts(Ts, CTs, iNumCTsAvailable);
						
						if (Ts <= gH_Cvar_MaxPrisonersToLR.IntValue || gH_Cvar_MaxPrisonersToLR.IntValue == 0)
						{
							if (CTs > 0)
							{
								if (iNumCTsAvailable > 0)
								{
									if (EMP_IsValidClient(ClientIdxOfCT, false, false, CS_TEAM_CT)) //30W
									{
										if (!g_bIsARebel[client] || (gH_Cvar_RebelHandling.IntValue == 2))
										{
											if (!g_bInLastRequest[ClientIdxOfCT])
											{
												int game = g_LRLookup[client];
												if ((game == LR_HotPotato || game == LR_RussianRoulette) && IsClientTooNearObstacle(client))
												{
													CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Near Obstruction");
												}
												// player isn't on ground
												else if ((game == LR_JumpContest) && !(GetEntityFlags(client) & FL_ONGROUND|FL_INWATER))
												{
													CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Must Be On Ground");
												}
												// make sure they're not ducked
												else if ((game == LR_JumpContest) && (GetEntityFlags(client) & FL_DUCKING))
												{
													CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Near Obstruction");
												}
												else if (IsLastRequestAutoStart(game))
												{
													// lock in this LR pair
													int iArrayIndex = PushArrayCell(gH_DArray_LR_Partners, game);
													SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, client, view_as<int>(Block_Prisoner));
													SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, ClientIdxOfCT, view_as<int>(Block_Guard));
													g_bInLastRequest[client] = true;
													g_bInLastRequest[ClientIdxOfCT] = true;
													InitializeGame(iArrayIndex);
												}
												else
												{
													int iArrayIndex = PushArrayCell(gH_DArray_LR_Partners, game);
													SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, client, view_as<int>(Block_Prisoner));
													SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, ClientIdxOfCT, view_as<int>(Block_Guard));
													g_bInLastRequest[client] = true;
													g_bInLastRequest[ClientIdxOfCT] = true;
													InitializeGame(iArrayIndex);
												}
											}
											else
											{
												CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Another LR In Progress");
											}
										}
										else
										{
											// if rebel, send a menu to the CT asking for permission
											Handle askmenu = CreateMenu(MainAskHandler);
											char lrname[MAX_DISPLAYNAME_SIZE];
											if (g_LRLookup[client] < LR_Number)
											{
												FormatEx(lrname, sizeof(lrname), "%t", g_sLastRequestPhrase[g_LRLookup[client]], ClientIdxOfCT);		
											}
											else
											{
												GetArrayString(gH_DArray_LR_CustomNames, view_as<int>(g_LRLookup[client] - LR_Number), lrname, MAX_DISPLAYNAME_SIZE);
											}
											SetMenuTitle(askmenu, "%t", "Rebel Ask CT For LR", ClientIdxOfCT, client, lrname);
	
											char yes[8];
											char no[8];
											FormatEx(yes, sizeof(yes), "%t", "Yes", ClientIdxOfCT);
											FormatEx(no, sizeof(no), "%t", "No", ClientIdxOfCT);
											AddMenuItem(askmenu, "yes", yes);
											AddMenuItem(askmenu, "no", no);
	
											g_LR_PermissionLookup[ClientIdxOfCT] = client;
											SetMenuExitButton(askmenu, true);
											DisplayMenu(askmenu, ClientIdxOfCT, 6);

											CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Asking For Permission", ClientIdxOfCT);
										}
									}
									else
									{
										CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not With Bot");
									}
								}
								else
								{
									CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR No CTs Available");
								}
							}
							else
							{
								CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "No CTs Alive");
							}
						}
						else
						{
							CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Many Ts");
						}
					}
					else
					{
						CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Target Is Not Alive Or In Wrong Team");
					}
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Another LR In Progress");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
			}	
		}
		case MenuAction_End:
		{
			if (EMP_IsValidClient(client))
			{
				EMP_FreeHandle(gH_BuildLR[client]);
			}
			EMP_FreeHandle(playermenu);
		}
	}
	return 0;
}

int MainAskHandler(Handle askmenu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (g_bIsLRAvailable)
			{
				// client here is the guard
				if (!g_bInLastRequest[g_LR_PermissionLookup[client]])
				{
					if (EMP_IsValidClient(g_LR_PermissionLookup[client], false, false))
					{
						if (EMP_IsValidClient(client, false, false, CS_TEAM_CT))
						{
							// param2, 0 -> yes
							if (param2 == 0 || (client != 0 && !IsFakeClient(client)))
							{
								if (!g_bInLastRequest[client])
								{
									if (Team_GetClientCount(CS_TEAM_T, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE) <= gH_Cvar_MaxPrisonersToLR.IntValue || gH_Cvar_MaxPrisonersToLR.IntValue == 0)
									{								
										int game = g_LRLookup[g_LR_PermissionLookup[client]];
										
										// lock in this LR pair
										int iArrayIndex = PushArrayCell(gH_DArray_LR_Partners, game);
										SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, g_LR_PermissionLookup[client], view_as<int>(Block_Prisoner));
										SetArrayCell(gH_DArray_LR_Partners, iArrayIndex, client, view_as<int>(Block_Guard));
										InitializeGame(iArrayIndex);
										
										if(IsLastRequestAutoStart(game))
										{
											g_bInLastRequest[client] = true;
											g_bInLastRequest[g_LR_PermissionLookup[client]] = true;
										}
									}
									else
									{
										CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Many Ts");
									}
								}
								else
								{
									CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Slow Another LR In Progress");
								}
							}
							else
							{
								CPrintToChat(g_LR_PermissionLookup[client], "%s%t", gShadow_Hosties_ChatBanner, "Declined LR Request", client);
							}
						}
						else
						{
							CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Not Alive Or In Wrong Team");
						}
					}
					else
					{
						CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Partner Died");
					}
				}
				else
				{
					CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "Too Slow Another LR In Progress");
				}
			}
			else
			{
				CPrintToChat(client, "%s%t", gShadow_Hosties_ChatBanner, "LR Not Available");
			}
		}
		case MenuAction_Cancel:
		{
			if (IsClientInGame(g_LR_PermissionLookup[client]))
			{
				CPrintToChat(g_LR_PermissionLookup[client], "%s%t", gShadow_Hosties_ChatBanner, "LR Request Decline Or Too Long", client);
			}
		}
		case MenuAction_End:
		{
			if (EMP_IsValidClient(client))
			{
				EMP_FreeHandle(gH_BuildLR[g_LR_PermissionLookup[client]]);
			}
			EMP_FreeHandle(askmenu);
		}
	}
	return 0;
}

void InitializeGame(int iPartnersIndex)
{
	// grab the info
	int selection = GetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, view_as<int>(Block_LRType));
	int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, view_as<int>(Block_Prisoner));
	int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, view_as<int>(Block_Guard));
	
	// Beacon players
	if (gH_Cvar_LR_Beacons.BoolValue && selection != LR_Rebel && selection != LR_RussianRoulette && IsLastRequestAutoStart(selection))
	{
		AddBeacon(LR_Player_Prisoner);
		AddBeacon(LR_Player_Guard);
	}
	
	// log the event for stats engines
	if (selection < LR_Number)
	{
		LogToGame("\"%L\" started a LR game (\"%s\") with \"%L\"", LR_Player_Prisoner, g_sLastRequestPhrase[selection], LR_Player_Guard);
	}
	else
	{
		char LR_Name[MAX_DISPLAYNAME_SIZE];
		GetArrayString(gH_DArray_LR_CustomNames, view_as<int>(selection - LR_Number), LR_Name, MAX_DISPLAYNAME_SIZE);
		LogToGame("\"%L\" started a LR game (\"%s\") with \"%L\"", LR_Player_Prisoner, LR_Name, LR_Player_Guard);
	}
	
	if (EMP_IsValidClient(LR_Player_Prisoner))
	{
		SetEntPropFloat(LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityGravity(LR_Player_Prisoner, 1.0);
		
		if (g_Game == Game_CSGO)
		{
			SetEntProp(LR_Player_Prisoner, Prop_Send, "m_passiveItems", 0, 1, 1);
		}
	}
	
	if (EMP_IsValidClient(LR_Player_Guard))
	{
		SetEntPropFloat(LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityGravity(LR_Player_Guard, 1.0);
		
		if (g_Game == Game_CSGO)
		{
			SetEntProp(LR_Player_Guard, Prop_Send, "m_passiveItems", 0, 1, 1);
		}
	}
	
	if (selection != LR_Rebel)
	{
		if (gH_Cvar_LR_RestoreWeapon_T.BoolValue)
			LR_SaveWeapons(LR_Player_Prisoner);
		else
			Client_RemoveAllWeapons(LR_Player_Prisoner);
			
		if (gH_Cvar_LR_RestoreWeapon_CT.BoolValue)
			LR_SaveWeapons(LR_Player_Guard);
		else
			Client_RemoveAllWeapons(LR_Player_Guard);
	}
	
	switch (selection)
	{
		case LR_KnifeFight:
		{
			ResetPack(gH_BuildLR[LR_Player_Prisoner]);
			int KnifeChoice = ReadPackCell(gH_BuildLR[LR_Player_Prisoner]);
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, KnifeChoice, view_as<int>(Block_Global1));
			
			switch (KnifeChoice)
			{
				case Knife_Drunk:
				{
					SetEntData(LR_Player_Prisoner, g_Offset_FOV, 105, 4, true);
					SetEntData(LR_Player_Prisoner, g_Offset_DefFOV, 105, 4, true);	
					ShowOverlayToClient(LR_Player_Prisoner, "effects/strider_pinch_dudv");
					SetEntData(LR_Player_Guard, g_Offset_FOV, 105, 4, true);
					SetEntData(LR_Player_Guard, g_Offset_DefFOV, 105, 4, true);	
					ShowOverlayToClient(LR_Player_Guard, "effects/strider_pinch_dudv");
					if (g_BeerGogglesTimer == INVALID_HANDLE)
					{
						g_BeerGogglesTimer = CreateTimer(1.0, Timer_BeerGoggles, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case Knife_LowGrav:
				{
					SetEntityGravity(LR_Player_Prisoner, gH_Cvar_LR_KnifeFight_LowGrav.FloatValue);
					SetEntityGravity(LR_Player_Guard, gH_Cvar_LR_KnifeFight_LowGrav.FloatValue);
				}
				case Knife_HiSpeed:
				{
					SetEntPropFloat(LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", gH_Cvar_LR_KnifeFight_HiSpeed.FloatValue);
					SetEntPropFloat(LR_Player_Guard, Prop_Data, "m_flLaggedMovementValue", gH_Cvar_LR_KnifeFight_HiSpeed.FloatValue);
				}
				case Knife_ThirdPerson:
				{
					SetThirdPerson(LR_Player_Prisoner);
					SetThirdPerson(LR_Player_Guard);
				}
				case Knife_Drugs:
				{
					ShowOverlayToClient(LR_Player_Prisoner, "models/effects/portalfunnel_sheet");
					ShowOverlayToClient(LR_Player_Guard, "models/effects/portalfunnel_sheet");
					
					if (g_Game == Game_CSGO)
					{
						ServerCommand("sm_drug #%i 1", GetClientUserId(LR_Player_Prisoner));
						ServerCommand("sm_drug #%i 1", GetClientUserId(LR_Player_Guard));
					}
				}
			}

			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
		}
		case LR_Shot4Shot:
		{
			// grab weapon choice
			ResetPack(gH_BuildLR[LR_Player_Prisoner]);
			int PistolChoice = ReadPackCell(gH_BuildLR[LR_Player_Prisoner]);
	
			int Pistol_Prisoner, Pistol_Guard;
			switch (PistolChoice)
			{
				case Pistol_Deagle:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 0 ,0);
				}
				case Pistol_P228:
				{
					if (g_Game == Game_CSS)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_p228", true, 0, 0, 0 ,0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_p228", true, 0, 0, 0 ,0);
					}
					else if (g_Game == Game_CSGO)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_p250", true, 0, 0, 0 ,0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_p250", true, 0, 0, 0 ,0);
					}
				}
				case Pistol_Glock:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_glock", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_glock", true, 0, 0, 0 ,0);
				}
				case Pistol_FiveSeven:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_fiveseven", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_fiveseven", true, 0, 0, 0 ,0);
				}
				case Pistol_Dualies:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_elite", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_elite", true, 0, 0, 0 ,0);
				}
				case Pistol_USP:
				{
					if(g_Game == Game_CSS)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_usp", true, 0, 0, 0 ,0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_usp", true, 0, 0, 0 ,0);
					}
					else if(g_Game == Game_CSGO)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_usp_silencer", true, 0, 0, 0 ,0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_usp_silencer", true, 0, 0, 0 ,0);
					}
				}
				case Pistol_Tec9:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_tec9", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_tec9", true, 0, 0, 0 ,0);
				}
				case Pistol_Revolver:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_revolver", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_revolver", true, 0, 0, 0 ,0);
				}
				default:
				{
					LogError("hit default S4S");
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 0 ,0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 0 ,0);
				}
			}

			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Pistol_Prisoner, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Pistol_Guard, view_as<int>(Block_GuardData));
			
			// randomize who starts first
			int s4sPlayerFirst = GetRandomInt(0, 1);
			if (s4sPlayerFirst == 0)
			{
				SetEntData(Pistol_Guard, g_Offset_Clip1, 1);
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, LR_Player_Prisoner, view_as<int>(Block_Global1));
				if (gH_Cvar_SendGlobalMsgs.BoolValue)
				{
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
				}
				else
				{
					CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
					CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
				}
			}
			else
			{
				SetEntData(Pistol_Prisoner, g_Offset_Clip1, 1);			
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, LR_Player_Guard, view_as<int>(Block_Global1));
				if (gH_Cvar_SendGlobalMsgs.BoolValue)
				{
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
				}
				else
				{
					CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
					CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);				
				}
			}
		}
		case LR_FistFight:
		{
			int PrisonerW = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_fists");
			int GuardW = EMP_EquipWeapon(LR_Player_Guard, "weapon_fists");
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, PrisonerW, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, GuardW, view_as<int>(Block_GuardData));
		}
		case LR_JuggernoutBattle:
		{
			if (GetEngineVersion() == Engine_CSGO)
			{
				GetEntPropString(LR_Player_Prisoner, Prop_Data, "m_ModelName", BeforeModel[LR_Player_Prisoner], sizeof(BeforeModel[]));
				GetEntPropString(LR_Player_Guard, Prop_Data, "m_ModelName", BeforeModel[LR_Player_Guard], sizeof(BeforeModel[]));
			
				if (g_cvSvSuit == INVALID_HANDLE)
					g_cvSvSuit = FindConVar("mp_weapons_allow_heavyassaultsuit");
			
				SuitSetBack = GetConVarInt(g_cvSvSuit);		
				SetConVarInt(g_cvSvSuit, 1, true, false);
			
				GivePlayerItem(LR_Player_Prisoner, "item_heavyassaultsuit");
				GivePlayerItem(LR_Player_Guard, "item_heavyassaultsuit");
				
				EMP_GiveWeapon(LR_Player_Prisoner, "weapon_negev");
				EMP_GiveWeapon(LR_Player_Guard, "weapon_negev");
				
				SetEntityHealth(LR_Player_Prisoner, 100);
				SetEntityHealth(LR_Player_Guard, 100);
			}
			else if (GetEngineVersion() == Engine_CSS)
			{
				EMP_GiveWeapon(LR_Player_Prisoner, "weapon_m249");
				EMP_GiveWeapon(LR_Player_Guard, "weapon_m249");
				
				Client_SetArmor(LR_Player_Prisoner, 500);
				Client_SetArmor(LR_Player_Guard, 500);
				
				SetEntityHealth(LR_Player_Prisoner, 500);
				SetEntityHealth(LR_Player_Guard, 500);
			}
			
			EMP_GiveWeapon(LR_Player_Prisoner, "weapon_deagle");
			EMP_GiveWeapon(LR_Player_Guard, "weapon_deagle");
			
			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
			
			LogToFileEx(gShadow_Hosties_LogFile, "Juggernout initialize completed");
		}
		case LR_ShieldFight:
		{
			int PrisonerW = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_shield");
			int GuardW = EMP_EquipWeapon(LR_Player_Guard, "weapon_shield");
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, PrisonerW, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, GuardW, view_as<int>(Block_GuardData));
			
			CreateTimer(1.0, TimerTick_Equipper, iPartnersIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		case LR_GunToss:
		{
			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
		
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, false, view_as<int>(Block_Global1)); // GTp1dropped
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, false, view_as<int>(Block_Global2)); // GTp2dropped
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, false, view_as<int>(Block_Global3)); // GTp1done
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, false, view_as<int>(Block_Global4)); // GTp2done
			
			Handle DataPackPosition = CreateDataPack();
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, DataPackPosition, view_as<int>(Block_DataPackHandle)); // position handle
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0); // GTdeagle1lastpos
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0); // GTdeagle2lastpos
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0); // 
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0); // 
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0); // player 1 last jump position
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0);
			WritePackFloat(DataPackPosition, 0.0); // player 2 last jump position

			int GTdeagle1 = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 0, 0);
			int GTdeagle2 = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 0, 0);
			int Prisoner_GunEntRef = EntIndexToEntRef(GTdeagle1);
			int Guard_GunEntRef = EntIndexToEntRef(GTdeagle2);
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Prisoner_GunEntRef, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Guard_GunEntRef, view_as<int>(Block_GuardData));

			SetEntityRenderMode(GTdeagle1, RENDER_TRANSCOLOR);
			SetEntityRenderColor(GTdeagle1, 255, 0, 0);
			SetEntityRenderMode(GTdeagle2, RENDER_TRANSCOLOR);
			SetEntityRenderColor(GTdeagle2, 0, 0, 255);
		}
		case LR_ChickenFight:
		{
			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
		
			if (g_ChickenFightTimer == INVALID_HANDLE)
			{
				g_ChickenFightTimer = CreateTimer(0.2, Timer_ChickenFight, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}

			BlockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
			BlockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
		}
		case LR_HotPotato:
		{
			// always give potato to the prisoner
			int potatoClient = LR_Player_Prisoner;
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, potatoClient, view_as<int>(Block_Global1)); // HPloser

			// create the potato deagle
			int HPdeagle = EMP_EquipWeapon(potatoClient, "weapon_deagle", true, 0, 0, 0, 0);
			
			int HPDeagke_GunEntRef = EntIndexToEntRef(HPdeagle);
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, HPDeagke_GunEntRef, view_as<int>(Block_Global4));

			SetEntityRenderMode(HPdeagle, RENDER_TRANSCOLOR);
			SetEntityRenderColor(HPdeagle, 255, 255, 0);

			float p1pos[3], p2pos[3];
			GetClientAbsOrigin(LR_Player_Prisoner, p1pos);
			
			float f_PrisonerAngles[3], f_SubtractFromPrisoner[3];
			GetClientEyeAngles(LR_Player_Prisoner, f_PrisonerAngles);			
			// zero out pitch/yaw
			f_PrisonerAngles[0] = 0.0;			
			GetAngleVectors(f_PrisonerAngles, f_SubtractFromPrisoner, NULL_VECTOR, NULL_VECTOR);
			float f_GuardDirection[3];
			f_GuardDirection = f_SubtractFromPrisoner;
			if (g_Game == Game_CSS)
			{
				ScaleVector(f_SubtractFromPrisoner, -70.0);
			}
			else if (g_Game == Game_CSGO)
			{
				ScaleVector(f_SubtractFromPrisoner, -115.0);
			}
			MakeVectorFromPoints(f_SubtractFromPrisoner, p1pos, p2pos);

			if (g_Game == Game_CSGO)
			{
				p1pos[2] -= 20.0;
			}
			
			// create 'unique' ID for this hot potato
			int uniqueID = GetRandomInt(1, 31337);
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, uniqueID, view_as<int>(Block_Global3));
			
			// create timer to end hot potato
			float rndEnd = GetRandomFloat(gH_Cvar_LR_HotPotato_MinTime.FloatValue, gH_Cvar_LR_HotPotato_MaxTime.FloatValue);
			CreateTimer(rndEnd, Timer_HotPotatoDone, uniqueID, TIMER_FLAG_NO_MAPCHANGE);

			if (gH_Cvar_LR_HotPotato_Mode.IntValue == 2)
			{
				SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
				SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);
				ScaleVector(f_GuardDirection, -1.0);
				TeleportEntity(LR_Player_Guard, p2pos, f_GuardDirection, view_as<float>({0.0, 0.0, 0.0}));
				TeleportEntity(LR_Player_Prisoner, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
			}
			else
			{
				if (gH_Cvar_LR_HotPotato_Mode.IntValue == 1)
				{
					if (gH_Cvar_NoBlock.BoolValue)
					{
						UnblockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
						UnblockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
					}
					TeleportEntity(LR_Player_Guard, p2pos, f_GuardDirection, NULL_VECTOR);
				}
				
				SetEntPropFloat(LR_Player_Prisoner, Prop_Data, "m_flLaggedMovementValue", gH_Cvar_LR_HotPotato_Speed.FloatValue);				
			}
			TeleportEntity(HPdeagle, p1pos, NULL_VECTOR, NULL_VECTOR);
			
			if (gH_Cvar_LR_Beacons.BoolValue)
			{
				AddBeacon(HPdeagle);
			}
		}
		case LR_Dodgeball:
		{
			// bug fix...
			if(g_Game != Game_CSGO)
			{
				SetEntData(LR_Player_Prisoner, g_Offset_Ammo + (12 * 4), 0, _, true);
				SetEntData(LR_Player_Guard, g_Offset_Ammo + (12 * 4), 0, _, true);
			}

			BlockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
			BlockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);

			// set HP
			SetEntData(LR_Player_Prisoner, g_Offset_Health, 1);
			SetEntData(LR_Player_Guard, g_Offset_Health, 1);

			// give flashbangs
			EMP_EquipWeapon(LR_Player_Guard, "weapon_flashbang");
			EMP_EquipWeapon(LR_Player_Prisoner, "weapon_flashbang");

			SetEntityGravity(LR_Player_Prisoner, gH_Cvar_LR_Dodgeball_Gravity.FloatValue);
			SetEntityGravity(LR_Player_Guard, gH_Cvar_LR_Dodgeball_Gravity.FloatValue);
			
			// timer making sure DB contestants stay @ 1 HP (if enabled by cvar)
			if ((g_DodgeballTimer == INVALID_HANDLE) && gH_Cvar_LR_Dodgeball_CheatCheck.BoolValue)
			{
				g_DodgeballTimer = CreateTimer(1.0, Timer_DodgeballCheckCheaters, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		case LR_OnlyHS:
		{
			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
			
			ResetPack(gH_BuildLR[LR_Player_Prisoner]);
			int WeaponChoice = ReadPackCell(gH_BuildLR[LR_Player_Prisoner]);
			
			int OHS_Prisoner, OHS_Guard;
			switch (WeaponChoice)
			{
				case OHS_AWP:
				{
					OHS_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_awp", true, 0, 0, 99, 0);
					OHS_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_awp", true, 0, 0, 99, 0);
				}
				case OHS_Deagle:
				{
					OHS_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 99, 0);
					OHS_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 99, 0);
				}
				case OHS_Fiveseven:
				{
					OHS_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_fiveseven", true, 0, 0, 99, 0);
					OHS_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_fiveseven", true, 0, 0, 99, 0);
				}
				case OHS_AK:
				{
					OHS_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_ak47", true, 0, 0, 99, 0);
					OHS_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_ak47", true, 0, 0, 99, 0);
				}
			}
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, OHS_Prisoner, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, OHS_Guard, view_as<int>(Block_GuardData));
		}
		case LR_HEFight:
		{
			EMP_EquipWeapon(LR_Player_Prisoner, "weapon_hegrenade");
			EMP_EquipWeapon(LR_Player_Guard, "weapon_hegrenade");
			
			CreateTimer(1.0, TimerTick_Equipper, iPartnersIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		case LR_NoScope:
		{
			// give knives
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);

			int WeaponChoice;
			switch (gH_Cvar_LR_NoScope_Weapon.IntValue)
			{
				case 0:
				{
					WeaponChoice = NSW_AWP;
				}
				case 1:
				{
					WeaponChoice = NSW_Scout;
				}
				case 2:
				{
					ResetPack(gH_BuildLR[LR_Player_Prisoner]);
					WeaponChoice = ReadPackCell(gH_BuildLR[LR_Player_Prisoner]);			
				}
				case 3:
				{
					WeaponChoice = NSW_SG550;
				}
				case 4:
				{
					WeaponChoice = NSW_G3SG1;
				}
			}
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, WeaponChoice, view_as<int>(Block_Global2));

			if (gH_Cvar_LR_NoScope_Delay.IntValue > 0)
			{
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, gH_Cvar_LR_NoScope_Delay.IntValue, view_as<int>(Block_Global1));
				if (g_CountdownTimer == INVALID_HANDLE)
				{
					g_CountdownTimer = CreateTimer(1.0, Timer_Countdown, iPartnersIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			// launch now if there's no countdown requested
			else
			{				
				int NSW_Prisoner, NSW_Guard;
				switch (WeaponChoice)
				{
					case NSW_AWP:
					{
						NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_awp", true, 0, 0, 99, 0);
						NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_awp", true, 0, 0, 99, 0);
					}
					case NSW_Scout:
					{
						if (g_Game == Game_CSS)
						{
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_scout", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_scout", true, 0, 0, 99, 0);
						}
						else if (g_Game == Game_CSGO)
						{
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_ssg08", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_ssg08", true, 0, 0, 99, 0);
						}
					}
					case NSW_SG550:
					{
						if (g_Game == Game_CSS)
						{
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_sg550", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_sg550", true, 0, 0, 99, 0);
						}
						else if (g_Game == Game_CSGO)
						{
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_scar20", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_scar20", true, 0, 0, 99, 0);
						}
					}
					case NSW_G3SG1:
					{
						NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_g3sg1", true, 0, 0, 99, 0);
						NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_g3sg1", true, 0, 0, 99, 0);
					}
					default:
					{
						LogError("hit default NS");
						NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_awp", true, 0, 0, 99, 0);
						NSW_Guard = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_awp", true, 0, 0, 99, 0);
					}
				}
				
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, NSW_Prisoner, view_as<int>(Block_PrisonerData));
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, NSW_Guard, view_as<int>(Block_GuardData));
				
				// place delay on zoom
				SetEntDataFloat(NSW_Prisoner, g_Offset_SecAttack, GetGameTime() + 9999.0);
				SetEntDataFloat(NSW_Guard, g_Offset_SecAttack, GetGameTime() + 9999.0);
				
				char buffer[PLATFORM_MAX_PATH];
				gH_Cvar_LR_NoScope_Sound.GetString(buffer, sizeof(buffer));
				if ((strlen(buffer) > 0) && strcmp(buffer, "-1") != 0)
				{
					EmitSoundToAllAny(buffer);
				}			
			}
		}
		case LR_RockPaperScissors:
		{
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, -1, view_as<int>(Block_Global1));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, -1, view_as<int>(Block_Global2));
			Handle rpsmenu1 = CreateMenu(RPSmenuHandler);
			SetMenuTitle(rpsmenu1, "%t", "Rock Paper Scissors", LR_Player_Prisoner);
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, rpsmenu1, view_as<int>(Block_PrisonerData));

			char r1[32], p1[64], s1[64];
			FormatEx(r1, sizeof(r1), "%t", "Rock", LR_Player_Prisoner);
			FormatEx(p1, sizeof(p1), "%t", "Paper", LR_Player_Prisoner);
			FormatEx(s1, sizeof(s1), "%t", "Scissors", LR_Player_Prisoner);
			AddMenuItem(rpsmenu1, "0", r1);
			AddMenuItem(rpsmenu1, "1", p1);
			AddMenuItem(rpsmenu1, "2", s1);

			SetMenuExitButton(rpsmenu1, true);
			DisplayMenu(rpsmenu1, LR_Player_Prisoner, 15);

			Handle rpsmenu2 = CreateMenu(RPSmenuHandler);
			SetMenuTitle(rpsmenu2, "%t", "Rock Paper Scissors", LR_Player_Guard);
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, rpsmenu2, view_as<int>(Block_GuardData));

			char r2[32], p2[64], s2[64];
			FormatEx(r2, sizeof(r2), "%t", "Rock", LR_Player_Guard);
			FormatEx(p2, sizeof(p2), "%t", "Paper", LR_Player_Guard);
			FormatEx(s2, sizeof(s2), "%t", "Scissors", LR_Player_Guard);
			AddMenuItem(rpsmenu2, "0", r2);
			AddMenuItem(rpsmenu2, "1", p2);
			AddMenuItem(rpsmenu2, "2", s2);

			SetMenuExitButton(rpsmenu2, true);
			DisplayMenu(rpsmenu2, LR_Player_Guard, 15);
		}
		case LR_Rebel:
		{
			// strip weapons from T rebelling
			Client_RemoveAllWeapons(LR_Player_Prisoner);

			// give knife and deagle
			EMP_EquipKnife(LR_Player_Prisoner);
			
			char Weapons[64], buffer[32];
			char WeaponList[16][32];
			gH_Cvar_LR_Rebel_Weapons.GetString(Weapons, sizeof(Weapons));
			int weapon_count = ExplodeString(Weapons, ",", WeaponList, sizeof(WeaponList), sizeof(WeaponList[]));
			for (int Tidx = 0; Tidx < weapon_count; Tidx++)
			{
				FormatEx(buffer, sizeof(buffer), WeaponList[Tidx]);
				if (!Client_HasWeapon(LR_Player_Prisoner, buffer))
					EMP_GiveWeapon(LR_Player_Prisoner, buffer);
			}

			// find number of alive CTs
			int numCTsAlive = Team_GetClientCount(CS_TEAM_CT, CLIENTFILTER_NOBOTS|CLIENTFILTER_INGAME|CLIENTFILTER_ALIVE);
			int hp = 100+(numCTsAlive*gH_Cvar_LR_Rebel_HP_per_CT.IntValue);
			SetEntData(LR_Player_Prisoner, g_Offset_Health, hp);
			
			LOOP_CLIENTS(TargetForSetHP, CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_NOBOTS|CLIENTFILTER_ALIVE|CLIENTFILTER_TEAMTWO)
				SetEntData(TargetForSetHP, g_Offset_Health, gH_Cvar_LR_Rebel_CT_HP.IntValue);
			
			// announce LR
			EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Has Chosen to Rebel!", LR_Player_Prisoner);
		}
		case LR_Mag4Mag:
		{
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, 0, view_as<int>(Block_Global2)); // M4MroundsFired
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, 0, view_as<int>(Block_Global3)); // M4Mammo
			
			// grab weapon choice
			ResetPack(gH_BuildLR[LR_Player_Prisoner]);
			int PistolChoice = ReadPackCell(gH_BuildLR[LR_Player_Prisoner]);
	
			EMP_EquipKnife(LR_Player_Prisoner);
			EMP_EquipKnife(LR_Player_Guard);
	
			int Pistol_Prisoner, Pistol_Guard;
			switch (PistolChoice)
			{
				case Pistol_Deagle:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 0, 0);
				}
				case Pistol_P228:
				{
					if (g_Game == Game_CSS)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_p228", true, 0, 0, 0, 0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_p228", true, 0, 0, 0, 0);
					}
					else if (g_Game == Game_CSGO)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_p250", true, 0, 0, 0, 0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_p250", true, 0, 0, 0, 0);
					}
				}
				case Pistol_Glock:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_glock", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_glock", true, 0, 0, 0, 0);
				}
				case Pistol_FiveSeven:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_fiveseven", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_fiveseven", true, 0, 0, 0, 0);
				}
				case Pistol_Dualies:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_elite", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_elite", true, 0, 0, 0, 0);
				}
				case Pistol_USP:
				{
					if (g_Game == Game_CSS)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_usp", true, 0, 0, 0, 0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_usp", true, 0, 0, 0, 0);
					}
					else if (g_Game == Game_CSGO)
					{
						Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_usp_silencer", true, 0, 0, 0, 0);
						Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_usp_silencer", true, 0, 0, 0, 0);
					}
				}
				case Pistol_Tec9:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_tec9", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_tec9", true, 0, 0, 0, 0);
				}
				case Pistol_Revolver:
				{
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_revolver", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_revolver", true, 0, 0, 0, 0);
				}
				default:
				{
					LogError("hit default S4S");
					Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 0, 0);
					Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 0, 0);
				}
			}
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Pistol_Prisoner, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Pistol_Guard, view_as<int>(Block_GuardData));
			
			SetEntDataFloat(Pistol_Prisoner, g_Offset_SecAttack, GetGameTime() + 9999.0);
			SetEntDataFloat(Pistol_Guard, g_Offset_SecAttack, GetGameTime() + 9999.0);
			
			int m4mPlayerFirst = GetRandomInt(0, 1);
			if (m4mPlayerFirst == 0)
			{
				SetEntData(Pistol_Guard, g_Offset_Clip1, gH_Cvar_LR_M4M_MagCapacity.IntValue);
				if (gH_Cvar_SendGlobalMsgs.BoolValue)
				{
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
				}
				else
				{
					CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
					CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
				}
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, LR_Player_Guard, view_as<int>(Block_Global1)); // S4Slastshot
			}
			else
			{
				SetEntData(Pistol_Prisoner, g_Offset_Clip1, gH_Cvar_LR_M4M_MagCapacity.IntValue);			
				if (gH_Cvar_SendGlobalMsgs.BoolValue)
				{
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
				}
				else
				{
					CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
					CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
				}
				SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, LR_Player_Prisoner, view_as<int>(Block_Global1));
			}
		}
		case LR_Race:
		{
			if (!gH_Cvar_NoBlock.BoolValue)
			{
				UnblockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
				UnblockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
			}
			
			SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
			SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);
			
			//  teleport both players to the start of the race
			float f_StartLocation[3], f_EndLocation[3];
			ResetPack(gH_BuildLR[LR_Player_Prisoner]);
			f_StartLocation[0] = ReadPackFloat(gH_BuildLR[LR_Player_Prisoner]);
			f_StartLocation[1] = ReadPackFloat(gH_BuildLR[LR_Player_Prisoner]);
			f_StartLocation[2] = ReadPackFloat(gH_BuildLR[LR_Player_Prisoner]);
			
			f_EndLocation[0] = ReadPackFloat(gH_BuildLR[LR_Player_Prisoner]);
			f_EndLocation[1] = ReadPackFloat(gH_BuildLR[LR_Player_Prisoner]);
			f_EndLocation[2] = ReadPackFloat(gH_BuildLR[LR_Player_Prisoner]);
			
			Handle ThisDataPack = CreateDataPack();
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, ThisDataPack, 9);
			WritePackFloat(ThisDataPack, f_EndLocation[0]);
			WritePackFloat(ThisDataPack, f_EndLocation[1]);
			WritePackFloat(ThisDataPack, f_EndLocation[2]);
			
			TeleportEntity(LR_Player_Prisoner, f_StartLocation, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
			TeleportEntity(LR_Player_Guard, f_StartLocation, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
			
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, 3, view_as<int>(Block_Global1));
			// fire timer for race begin countdown
			if (g_CountdownTimer == INVALID_HANDLE)
			{
				g_CountdownTimer = CreateTimer(1.0, Timer_Countdown, iPartnersIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		case LR_RussianRoulette:
		{
			float p1pos[3], p2pos[3];
			GetClientAbsOrigin(LR_Player_Prisoner, p1pos);
			
			float f_PrisonerAngles[3], f_SubtractFromPrisoner[3];
			GetClientEyeAngles(LR_Player_Prisoner, f_PrisonerAngles);
			// zero out pitch/yaw
			f_PrisonerAngles[0] = 0.0;			
			GetAngleVectors(f_PrisonerAngles, f_SubtractFromPrisoner, NULL_VECTOR, NULL_VECTOR);
			float f_GuardDirection[3];
			f_GuardDirection = f_SubtractFromPrisoner;
			ScaleVector(f_SubtractFromPrisoner, -70.0);			
			MakeVectorFromPoints(f_SubtractFromPrisoner, p1pos, p2pos);

			SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
			SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);			
			ScaleVector(f_GuardDirection, -1.0);			
			TeleportEntity(LR_Player_Guard, p2pos, f_GuardDirection, view_as<float>({0.0, 0.0, 0.0}));
			TeleportEntity(LR_Player_Prisoner, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));

			int Pistol_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_deagle", true, 0, 0, 0, 0);
			int Pistol_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_deagle", true, 0, 0, 0, 0);
			int Pistol_PrisonerEntRef = EntIndexToEntRef(Pistol_Prisoner);
			int Pistol_GuardEntRef = EntIndexToEntRef(Pistol_Guard);
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Pistol_PrisonerEntRef, view_as<int>(Block_PrisonerData));
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, Pistol_GuardEntRef, view_as<int>(Block_GuardData));
			
			// randomize who starts first
			if (GetRandomInt(0, 1) == 0)
			{
				SetEntData(Pistol_Guard, g_Offset_Clip1, 1);
				if (gH_Cvar_SendGlobalMsgs.BoolValue)
				{
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
				}
				else
				{
					CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
					CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Guard);
				}
			}
			else
			{
				SetEntData(Pistol_Prisoner, g_Offset_Clip1, 1);
				if (gH_Cvar_SendGlobalMsgs.BoolValue)
				{
					EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
				}
				else
				{
					CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);
					CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "Randomly Chose First Player", LR_Player_Prisoner);				
				}
			}
		}
		case LR_JumpContest:
		{
			int JumpChoice;
			ResetPack(gH_BuildLR[LR_Player_Prisoner]);
			JumpChoice = ReadPackCell(gH_BuildLR[LR_Player_Prisoner]);
			SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, JumpChoice, view_as<int>(Block_Global2));

			UnblockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
			UnblockEntity(LR_Player_Guard, g_Offset_CollisionGroup);

			switch (JumpChoice)
			{
				case Jump_TheMost:
				{
					// reset jump counts
					SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, 0, view_as<int>(Block_PrisonerData));
					SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, 0, view_as<int>(Block_GuardData));
					// set countdown timer
					SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, 3, view_as<int>(Block_Global1));
					
					if (g_CountdownTimer == INVALID_HANDLE)
					{
						g_CountdownTimer = CreateTimer(1.0, Timer_Countdown, iPartnersIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
					
					float Prisoner_Position[3];
					GetClientAbsOrigin(LR_Player_Prisoner, Prisoner_Position);
					TeleportEntity(LR_Player_Guard, Prisoner_Position, NULL_VECTOR, NULL_VECTOR);
				}
				case Jump_Farthest:
				{
					Before_Jump_pos[LR_Player_Guard][0] = 0.0;
					Before_Jump_pos[LR_Player_Guard][1] = 0.0;
					Before_Jump_pos[LR_Player_Guard][2] = 0.0;
					Before_Jump_pos[LR_Player_Prisoner][0] = 0.0;
					Before_Jump_pos[LR_Player_Prisoner][1] = 0.0;
					Before_Jump_pos[LR_Player_Prisoner][2] = 0.0;
					
					After_Jump_pos[LR_Player_Guard][0] = 0.0;
					After_Jump_pos[LR_Player_Guard][1] = 0.0;
					After_Jump_pos[LR_Player_Guard][2] = 0.0;
					After_Jump_pos[LR_Player_Prisoner][0] = 0.0;
					After_Jump_pos[LR_Player_Prisoner][1] = 0.0;
					After_Jump_pos[LR_Player_Prisoner][2] = 0.0;
					
					LR_Player_Jumped[LR_Player_Guard] = false;
					LR_Player_Jumped[LR_Player_Prisoner] = false;
					
					LR_Player_Landed[LR_Player_Guard] = false;
					LR_Player_Landed[LR_Player_Prisoner] = false;			
					
					// start detection timer
					if (g_FarthestJumpTimer == INVALID_HANDLE)
					{
						g_FarthestJumpTimer = CreateTimer(0.1, Timer_FarthestJumpDetector, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case Jump_BrinkOfDeath:
				{
					float Prisoner_Position[3];
					GetClientAbsOrigin(LR_Player_Prisoner, Prisoner_Position);
					TeleportEntity(LR_Player_Guard, Prisoner_Position, NULL_VECTOR, NULL_VECTOR);
					
					UnblockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
					UnblockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
					
					// timer to quit the LR
					CreateTimer(22.0, Timer_JumpContestOver, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			
			char JumpTranslation[64];
			EMP_LoopPlayers(TargetForLang)
			{
				switch (JumpChoice) //To set everyone's own language for the message
				{
					case Jump_TheMost:
					{
						FormatEx(JumpTranslation, sizeof(JumpTranslation), "%t", "Jump_TheMost");
					}
					case Jump_Farthest:
					{
						FormatEx(JumpTranslation, sizeof(JumpTranslation), "%t", "Jump_Farthest");
					}
					case Jump_BrinkOfDeath:
					{
						FormatEx(JumpTranslation, sizeof(JumpTranslation), "%t", "Jump_BrinkOfDeath");
					}
				}

				CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Start Selected Game", LR_Player_Prisoner, JumpTranslation, LR_Player_Guard);
			}
		}
		default:
		{
			Call_StartForward(gH_Frwd_LR_Start);
			Call_PushCell(gH_DArray_LR_Partners);
			Call_PushCell(iPartnersIndex);
			int ignore;
			Call_Finish(view_as<int>(ignore));
			
			if(!IsLastRequestAutoStart(selection))
			{
				g_LR_Player_Guard[LR_Player_Prisoner] = LR_Player_Guard;
				g_selection[LR_Player_Prisoner] = selection;
				
				RemoveFromArray(gH_DArray_LR_Partners, iPartnersIndex);
			}
		}
	}
	
	if (selection != LR_Rebel && selection != LR_JumpContest && selection < BASE_LR_Number)
	{
		char LR_Name[32];
		EMP_LoopPlayers(TargetForLang)
		{
			FormatEx(LR_Name, sizeof(LR_Name), "%t", g_sLastRequestPhrase[selection]);
			CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Start Selected Game", LR_Player_Prisoner, LR_Name, LR_Player_Guard);
		}
	}
	
	CreateTimer(0.3, Timer_StripZeus, iPartnersIndex, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	if (EMP_IsValidClient(LR_Player_Prisoner, false, false))
	{
		if (selection != LR_Rebel && selection != LR_JuggernoutBattle)
		{
			if (selection != LR_Dodgeball) SetEntityHealth(LR_Player_Prisoner, 100);
			
			EMP_ResetArmor(LR_Player_Prisoner);
		}
	}
	
	if (EMP_IsValidClient(LR_Player_Guard, false, false))
	{
		if (selection != LR_Rebel && selection != LR_JuggernoutBattle)
		{
			if (selection != LR_Dodgeball) SetEntityHealth(LR_Player_Guard, 100);
			
			EMP_ResetArmor(LR_Player_Guard);
		}
	}
	
	if(IsLastRequestAutoStart(selection))
	{
		// Fire global
		Call_StartForward(gH_Frwd_LR_StartGlobal);
		Call_PushCell(LR_Player_Prisoner);
		Call_PushCell(LR_Player_Guard);
		// LR type
		Call_PushCell(selection);
		int ignore;
		Call_Finish(view_as<int>(ignore));
		
		// Close datapack
		EMP_FreeHandle(gH_BuildLR[LR_Player_Prisoner]);		
	}
}

Action Timer_FarthestJumpDetector(Handle timer)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard;
		float Prisoner_Distance, Guard_Distance;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_JumpContest)
			{
				int subType = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				if (subType == Jump_Farthest)
				{								
					LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
					LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));					

					if (LR_Player_Jumped[LR_Player_Prisoner] && (GetEntityFlags(LR_Player_Prisoner) & FL_ONGROUND) && !LR_Player_Landed[LR_Player_Prisoner])
					{
						SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_NONE);
						LR_Player_Landed[LR_Player_Prisoner] = true;
						
						GetClientAbsOrigin(LR_Player_Prisoner, After_Jump_pos[LR_Player_Prisoner]);
						
						if (gH_Cvar_LR_Ten_Timer.BoolValue)
						{
							CreateTimer(10.0, Timer_EnemyMustJump, TIMER_FLAG_NO_MAPCHANGE);
							CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "JF Jump Warning");
						}
					}
					
					if (LR_Player_Jumped[LR_Player_Guard] && (GetEntityFlags(LR_Player_Guard) & FL_ONGROUND) && !LR_Player_Landed[LR_Player_Guard])
					{
						SetEntityMoveType(LR_Player_Guard, MOVETYPE_NONE);
						LR_Player_Landed[LR_Player_Guard] = true;
						
						GetClientAbsOrigin(LR_Player_Guard, After_Jump_pos[LR_Player_Guard]);
						
						if (gH_Cvar_LR_Ten_Timer.BoolValue)
						{
							CreateTimer(10.0, Timer_EnemyMustJump, TIMER_FLAG_NO_MAPCHANGE);
							CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "JF Jump Warning");
						}
					}
					
					if (LR_Player_Landed[LR_Player_Prisoner] && LR_Player_Landed[LR_Player_Guard])
					{
						Prisoner_Distance = GetVectorDistance(Before_Jump_pos[LR_Player_Prisoner], After_Jump_pos[LR_Player_Prisoner]);
						Guard_Distance = GetVectorDistance(Before_Jump_pos[LR_Player_Guard], After_Jump_pos[LR_Player_Guard]);
						
						if (Prisoner_Distance > Guard_Distance)
						{
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Farthest Jump Won", LR_Player_Prisoner, LR_Player_Guard, Prisoner_Distance, Guard_Distance);
							KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
						}
						
						else if (Guard_Distance >= Prisoner_Distance)
						{
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Farthest Jump Won", LR_Player_Guard, LR_Player_Prisoner, Guard_Distance, Prisoner_Distance);
							KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
						}	
					}
				}
			}
		}
	}
	else
	{
		g_FarthestJumpTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action Timer_EnemyMustJump(Handle timer)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int jumptype, LR_Player_Prisoner, LR_Player_Guard;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{		
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_JumpContest)
			{
				jumptype = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));					
				switch (jumptype)
				{
					case Jump_Farthest:
					{
						if (LR_Player_Jumped[LR_Player_Prisoner] && !LR_Player_Jumped[LR_Player_Guard])
						{
							KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "JF No Jump", LR_Player_Prisoner, LR_Player_Guard);
						}
						else if (!LR_Player_Jumped[LR_Player_Prisoner] && LR_Player_Jumped[LR_Player_Guard])
						{
							KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "JF No Jump", LR_Player_Guard, LR_Player_Prisoner);
						}
					}
				}
			}
		}
	}
	return Plugin_Stop;
}

Action Timer_JumpContestOver(Handle timer)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int jumptype, LR_Player_Prisoner, LR_Player_Guard, Guard_JumpCount, Prisoner_JumpCount, Prisoner_Health, Guard_Health, loser, winner, random;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{		
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_JumpContest)
			{
				jumptype = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));					
				switch (jumptype)
				{
					case Jump_TheMost:
					{						
						Guard_JumpCount = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData));
						Prisoner_JumpCount = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData));
						
						if (Prisoner_JumpCount > Guard_JumpCount)
						{
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Won Jump Contest", LR_Player_Prisoner);
							KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
						}
						else
						{
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Won Jump Contest", LR_Player_Guard);
							KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
						}
					}
					case Jump_BrinkOfDeath:
					{
						Prisoner_Health = GetClientHealth(LR_Player_Prisoner);
						Guard_Health = GetClientHealth(LR_Player_Guard);
						
						loser = (Prisoner_Health > Guard_Health) ? LR_Player_Prisoner : LR_Player_Guard;
						winner = (Prisoner_Health > Guard_Health) ? LR_Player_Guard : LR_Player_Prisoner;
						
						// TODO *** consider adding this as an option (random or abort)
						if (Prisoner_Health == Guard_Health)
						{
							random = GetRandomInt(0,1);
							winner = (random) ? LR_Player_Prisoner : LR_Player_Guard;
							loser = (random) ? LR_Player_Guard : LR_Player_Prisoner;
						}
						
						KillAndReward(loser, winner);
						
						if (IsPlayerAlive(winner))
						{
							SetEntityHealth(winner, 100);
							if (!gH_Cvar_NoBlock.BoolValue)
							{
								BlockEntity(winner, g_Offset_CollisionGroup);
							}
						}						
						
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Won Jump Contest", winner);
					}
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action Timer_Beacon(Handle timer)
{
	int iNumOfBeacons = GetArraySize(gH_DArray_Beacons);
	if (iNumOfBeacons <= 0)
	{
		g_BeaconTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	static int iTimerCount = 1;
	if (iTimerCount > 99999)
	{
		iTimerCount = 1;
	}
	iTimerCount++;
	
	if (gH_Cvar_LR_HelpBeams.BoolValue)
	{
		int LR_Player_Prisoner, LR_Player_Guard, clients[2];
		float Prisoner_Pos[3], Guard_Pos[3], distance;
		for (int LRindex = 0; LRindex < GetArraySize(gH_DArray_LR_Partners); LRindex++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, LRindex, view_as<int>(Block_LRType));
			
			if (type != LR_Rebel)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, LRindex, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, LRindex, view_as<int>(Block_Guard));
				
				clients[0] = LR_Player_Prisoner;
				clients[1] = LR_Player_Guard;
				
				// setup beam
				GetClientEyePosition(LR_Player_Prisoner, Prisoner_Pos);
				Prisoner_Pos[2] -= 40.0;
				GetClientEyePosition(LR_Player_Guard, Guard_Pos);
				Guard_Pos[2] -= 40.0;
				distance = GetVectorDistance(Prisoner_Pos, Guard_Pos);
				
				if (distance > gH_Cvar_LR_HelpBeams_Distance.FloatValue)
				{
					TE_SetupBeamPoints(Prisoner_Pos, Guard_Pos, LaserSprite, LaserHalo, 1, 1, 0.1, 5.0, 5.0, 0, 10.0, greyColor, 255);			
					TE_Send(clients, 2);
					TE_SetupBeamPoints(Guard_Pos, Prisoner_Pos, LaserSprite, LaserHalo, 1, 1, 0.1, 5.0, 5.0, 0, 10.0, greyColor, 255);			
					TE_Send(clients, 2);
				}
			}
		}
	}
	
	int modTime = RoundToCeil(10.0 * gH_Cvar_LR_Beacon_Interval.FloatValue);
	if ((iTimerCount % modTime) == 0)
	{
		int iEntityIndex, team;
		float f_Origin[3];
		char buffer[PLATFORM_MAX_PATH];
		for (int idx = 0; idx < iNumOfBeacons; idx++)
		{
			iEntityIndex = GetArrayCell(gH_DArray_Beacons, idx);
			if (IsValidEntity(iEntityIndex))
			{
				GetEntPropVector(iEntityIndex, Prop_Data, "m_vecOrigin", f_Origin);
				f_Origin[2] += 10.0;
				TE_SetupBeamRingPoint(f_Origin, 10.0, 375.0, BeamSprite, HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
				TE_SendToAll();
				// check if it's a weapon or player
				if (iEntityIndex < MaxClients+1)
				{
					team = GetClientTeam(iEntityIndex);
					if (team == CS_TEAM_T)
					{
						TE_SetupBeamRingPoint(f_Origin, 10.0, 375.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
						TE_SendToAll();
					}
					else if (team == CS_TEAM_CT)
					{
						TE_SetupBeamRingPoint(f_Origin, 10.0, 375.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
						TE_SendToAll();
					}
				}
				else
				{
					TE_SetupBeamRingPoint(f_Origin, 10.0, 375.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, yellowColor, 10, 0);
					TE_SendToAll();
				}
				
				gH_Cvar_LR_Beacon_Sound.GetString(buffer, sizeof(buffer));
				EmitAmbientSoundAny(buffer, f_Origin, iEntityIndex, SNDLEVEL_RAIDSIREN);	
			}
			else
			{
				RemoveFromArray(gH_DArray_Beacons, idx);
			}
		}
	}
	
	return Plugin_Continue;
}

void AddBeacon(int entityIndex)
{
	if (IsValidEntity(entityIndex))
	{
		PushArrayCell(gH_DArray_Beacons, entityIndex);
	}
	
	if (g_BeaconTimer == INVALID_HANDLE)
	{
		g_BeaconTimer = CreateTimer(0.1, Timer_Beacon, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

void RemoveBeacon(int entityIndex)
{
	int iBeaconIndex = FindValueInArray(gH_DArray_Beacons, entityIndex);
	if (iBeaconIndex != -1)
	{
		RemoveFromArray(gH_DArray_Beacons, iBeaconIndex);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
    int iArraySize = GetArraySize(gH_DArray_LR_Partners);
    bool bIsDodgeball = false;
    if (iArraySize > 0)
    {
        for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
        {
            int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
            if (type == LR_Dodgeball)
            {
                bIsDodgeball = true;
            }
        }
    }
    if (bIsDodgeball && strcmp(classname, "flashbang_projectile") == 0)
    {
        SDKHook(entity, SDKHook_Spawn, OnEntitySpawnedFix);
    }
}

Action OnEntitySpawnedFix(int entity)
{
    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    int iArraySize = GetArraySize(gH_DArray_LR_Partners);
    if (iArraySize > 0)
    {
        int LR_Player_Prisoner, LR_Player_Guard;
        for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
        {
            LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
            LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
            
            if (client == LR_Player_Prisoner || client == LR_Player_Guard)
            {
                CreateTimer(0.0, Timer_RemoveThinkTick, entity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    return Plugin_Continue;
}

Action Timer_RemoveThinkTick(Handle timer, any entity)
{
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	CreateTimer(gH_Cvar_LR_Dodgeball_SpawnTime.FloatValue, Timer_RemoveFlashbang, entity, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

Action Timer_RemoveFlashbang(Handle timer, any entity)
{
	if (IsValidEntity(entity))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		RemoveEntity(entity);
		
		if (EMP_IsValidClient(client, false, false) && Local_IsClientInLR(client))
		{
			EMP_EquipWeapon(client, "weapon_flashbang");
		}
	}
	return Plugin_Stop;
}

public Action Timer_Countdown(Handle timer, int iPartnersIndex)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize == 0)
	{
		g_CountdownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	bool bCountdownUsed = false;
	int LR_Player_Prisoner, LR_Player_Guard, countdown, clients[2], NSW_Prisoner, NSW_Guard;
	Handle PositionPack;
	float LR_Prisoner_Position[3], f_EndLocation[3];
	char buffer[PLATFORM_MAX_PATH], sCommand[PLATFORM_MAX_PATH];
	
	for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
	{
		int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
		
		if (type != LR_Race && type != LR_NoScope && type != LR_JumpContest)
		{
			continue;
		}
		
		LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
		LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
		countdown = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
		if (countdown > 0)
		{
			bCountdownUsed = true;
			
			PrintCenterText(LR_Player_Prisoner, "%t", "LR Countdown", countdown);
			PrintCenterText(LR_Player_Guard, "%t", "LR Countdown", countdown);
			SetArrayCell(gH_DArray_LR_Partners, idx, --countdown, view_as<int>(Block_Global1));
			
			// set up laser beams for race points
			if (type == LR_Race && gH_Cvar_LR_Race_NotifyCTs.BoolValue)
			{
				PositionPack = GetArrayCell(gH_DArray_LR_Partners, idx, 9);
				ResetPack(PositionPack);
				f_EndLocation[0] = ReadPackFloat(PositionPack);
				f_EndLocation[1] = ReadPackFloat(PositionPack);
				f_EndLocation[2] = ReadPackFloat(PositionPack);
				GetClientAbsOrigin(LR_Player_Prisoner, LR_Prisoner_Position);
				
				clients[0] = LR_Player_Prisoner;
				clients[1] = LR_Player_Guard;
				
				TE_SetupBeamPoints(f_EndLocation, LR_Prisoner_Position, LaserSprite, LaserHalo, 1, 1, 1.1, 5.0, 5.0, 0, 10.0, redColor, 200);			
				TE_Send(clients, 2);
				TE_SetupBeamPoints(LR_Prisoner_Position, f_EndLocation, LaserSprite, LaserHalo, 1, 1, 1.1, 5.0, 5.0, 0, 10.0, redColor, 200);			
				TE_Send(clients, 2);
			}
		}
		else if (countdown == 0)
		{
			bCountdownUsed = true;
			SetArrayCell(gH_DArray_LR_Partners, idx, --countdown, view_as<int>(Block_Global1));	
			switch (type)
			{
				case LR_Race:
				{
					SetEntityMoveType(LR_Player_Prisoner, MOVETYPE_WALK);
					SetEntityMoveType(LR_Player_Guard, MOVETYPE_WALK);
					
					UnblockEntity(LR_Player_Guard, g_Offset_CollisionGroup);
					UnblockEntity(LR_Player_Prisoner, g_Offset_CollisionGroup);
					
					// make timer to check the race winner
					if (g_RaceTimer == INVALID_HANDLE)
					{
						g_RaceTimer = CreateTimer(0.1, Timer_Race, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					}			
				}
				case LR_NoScope:
				{
					Client_RemoveAllWeapons(LR_Player_Prisoner);
					Client_RemoveAllWeapons(LR_Player_Guard);
					
					// grab weapon choice
					int NS_Selection = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));					
					switch (NS_Selection)
					{
						case NSW_AWP:
						{
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_awp", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_awp", true, 0, 0, 99, 0);
						}
						case NSW_Scout:
						{
							if(g_Game == Game_CSS)
							{
								NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_scout", true, 0, 0, 99, 0);
								NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_scout", true, 0, 0, 99, 0);
							}
							else if(g_Game == Game_CSGO)
							{
								NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_ssg08", true, 0, 0, 99, 0);
								NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_ssg08", true, 0, 0, 99, 0);
							}
						}
						case NSW_SG550:
						{
							if(g_Game == Game_CSS)
							{
								NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_sg550", true, 0, 0, 99, 0);
								NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_sg550", true, 0, 0, 99, 0);
							}
							else if(g_Game == Game_CSGO)
							{
								NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_scar20", true, 0, 0, 99, 0);
								NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_scar20", true, 0, 0, 99, 0);
							}
						}
						case NSW_G3SG1:
						{
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_g3sg1", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_g3sg1", true, 0, 0, 99, 0);
						}
						default:
						{
							LogError("hit default NS");
							NSW_Prisoner = EMP_EquipWeapon(LR_Player_Prisoner, "weapon_awp", true, 0, 0, 99, 0);
							NSW_Guard = EMP_EquipWeapon(LR_Player_Guard, "weapon_awp", true, 0, 0, 99, 0);
						}
					}

					SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, NSW_Prisoner, view_as<int>(Block_PrisonerData));
					SetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, NSW_Guard, view_as<int>(Block_GuardData));
					
					// place delay on zoom
					SetEntDataFloat(NSW_Prisoner, g_Offset_SecAttack, GetGameTime() + 9999.0);
					SetEntDataFloat(NSW_Guard, g_Offset_SecAttack, GetGameTime() + 9999.0);
					
					gH_Cvar_LR_NoScope_Sound.GetString(buffer, sizeof(buffer));
					if ((strlen(buffer) > 0) && strcmp(buffer, "-1") != 0)
					{
						if (g_Game == Game_CSS)
						{
							EmitSoundToAll(buffer);
						}
						else
						{
							for (int idx2 = 1; idx2 <= MaxClients; idx2++)
							{
								if (EMP_IsValidClient(idx2, false, true))
								{
									FormatEx(sCommand, sizeof(sCommand), "play *%s", buffer);
									ClientCommand(idx2, sCommand);
								}
							}
						}
					}
				}
				case LR_JumpContest:
				{
					CreateTimer(13.0, Timer_JumpContestOver, _, TIMER_FLAG_NO_MAPCHANGE);			
				}
			}
		}
	}
	
	if (bCountdownUsed == false)
	{
		g_CountdownTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timer_Race(Handle timer)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	bool bIsRace = false;
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard;
		float LR_Prisoner_Position[3], LR_Guard_Position[3], f_EndLocation[3];
		Handle PositionPack;
		
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_Race)
			{
				bIsRace = true;
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				PositionPack = GetArrayCell(gH_DArray_LR_Partners, idx, 9);
				ResetPack(PositionPack);
				f_EndLocation[0] = ReadPackFloat(PositionPack);
				f_EndLocation[1] = ReadPackFloat(PositionPack);
				f_EndLocation[2] = ReadPackFloat(PositionPack);
				GetClientAbsOrigin(LR_Player_Prisoner, LR_Prisoner_Position);
				GetClientAbsOrigin(LR_Player_Guard, LR_Guard_Position);
				// check how close they are to the end point
				f_DoneDistance[LR_Player_Prisoner] = GetVectorDistance(LR_Prisoner_Position, f_EndLocation, false);
				f_DoneDistance[LR_Player_Guard] = GetVectorDistance(LR_Guard_Position, f_EndLocation, false);
				
				if (f_DoneDistance[LR_Player_Prisoner] < 75.0 || f_DoneDistance[LR_Player_Guard] < 75.0)
				{
					if (f_DoneDistance[LR_Player_Prisoner] < f_DoneDistance[LR_Player_Guard])
					{
						KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Race Won", LR_Player_Prisoner);
					}
					else
					{
						KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Race Won", LR_Player_Guard);
					}
				}
				
				// update end location beam
				TE_SetupBeamRingPoint(f_EndLocation, 100.0, 110.0, BeamSprite, HaloSprite, 0, 15, 0.2, 7.0, 1.0, greenColor, 1, 0);
				TE_SendToAll();					
			}
		}
	}
	
	if (!bIsRace)
	{
		g_RaceTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

int RPSmenuHandler(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		// find out which LR this is for
		int LR_Player_Prisoner, LR_Player_Guard, RPS_Prisoner_Choice, RPS_Guard_Choice;
		char RPSr[64], RPSp[64], RPSs[64], RPSc1[64], RPSc2[64], r1[32], p1[64], s1[64];
		Handle rpsmenu1, rpsmenu2;
		
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_RockPaperScissors)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));	
				if (client == LR_Player_Prisoner || client == LR_Player_Guard)
				{
					RPS_Prisoner_Choice = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
					RPS_Guard_Choice = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
					
					if (client == LR_Player_Prisoner)
					{
						RPS_Prisoner_Choice = param2;
						SetArrayCell(gH_DArray_LR_Partners, idx, RPS_Prisoner_Choice, 5);
					}
					else if (client == LR_Player_Guard)
					{
						RPS_Guard_Choice = param2;
						SetArrayCell(gH_DArray_LR_Partners, idx, RPS_Guard_Choice, view_as<int>(Block_Global2));
					}
					
					if ((RPS_Guard_Choice != -1) && (RPS_Prisoner_Choice != -1))
					{
						// decide who wins -- rock 0 paper 1 scissors 2
						FormatEx(RPSr, sizeof(RPSr), "%t", "Rock", LR_Player_Prisoner);
						FormatEx(RPSp, sizeof(RPSp), "%t", "Paper", LR_Player_Prisoner);
						FormatEx(RPSs, sizeof(RPSs), "%t", "Scissors", LR_Player_Prisoner);
		
						switch (RPS_Prisoner_Choice)
						{
							case 0:
							{
								strcopy(RPSc1, sizeof(RPSc1), RPSr);
							}
							case 1:
							{
								strcopy(RPSc1, sizeof(RPSc1), RPSp);
							}
							case 2:
							{
								strcopy(RPSc1, sizeof(RPSc1), RPSs);
							}
						}
						switch (RPS_Guard_Choice)
						{
							case 0:
							{
								strcopy(RPSc2, sizeof(RPSc2), RPSr);
							}
							case 1:
							{
								strcopy(RPSc2, sizeof(RPSc2), RPSp);
							}
							case 2:
							{
								strcopy(RPSc2, sizeof(RPSc2), RPSs);
							}
						}
		
						if (RPS_Prisoner_Choice == RPS_Guard_Choice) // tie
						{
							if (client == LR_Player_Prisoner)
							{
								if (gH_Cvar_SendGlobalMsgs.BoolValue)
								{
									EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Tie", LR_Player_Prisoner, RPSc2, LR_Player_Guard, RPSc1);
								}
								else
								{
									CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Tie", LR_Player_Prisoner, RPSc2, LR_Player_Guard, RPSc1);
									CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Tie", LR_Player_Prisoner, RPSc2, LR_Player_Guard, RPSc1);
								}
							}
							else
							{
								if (gH_Cvar_SendGlobalMsgs.BoolValue)
								{
									EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Tie", LR_Player_Guard, RPSc1, LR_Player_Prisoner, RPSc2);
								}
								else
								{
									CPrintToChat(LR_Player_Guard, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Tie", LR_Player_Guard, RPSc1, LR_Player_Prisoner, RPSc2);
									CPrintToChat(LR_Player_Prisoner, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Tie", LR_Player_Guard, RPSc1, LR_Player_Prisoner, RPSc2);
								}
							}
							
							// redo menu
							SetArrayCell(gH_DArray_LR_Partners, idx, -1, view_as<int>(Block_Global1));
							SetArrayCell(gH_DArray_LR_Partners, idx, -1, view_as<int>(Block_Global2));
							rpsmenu1 = CreateMenu(RPSmenuHandler);
							SetMenuTitle(rpsmenu1, "%t", "Rock Paper Scissors", LR_Player_Prisoner);
							SetArrayCell(gH_DArray_LR_Partners, idx, rpsmenu1, view_as<int>(Block_PrisonerData));
				
							FormatEx(r1, sizeof(r1), "%t", "Rock", LR_Player_Prisoner);
							FormatEx(p1, sizeof(p1), "%t", "Paper", LR_Player_Prisoner);
							FormatEx(s1, sizeof(s1), "%t", "Scissors", LR_Player_Prisoner);
							AddMenuItem(rpsmenu1, "0", r1);
							AddMenuItem(rpsmenu1, "1", p1);
							AddMenuItem(rpsmenu1, "2", s1);
				
							SetMenuExitButton(rpsmenu1, true);
							DisplayMenu(rpsmenu1, LR_Player_Prisoner, 15);

							rpsmenu2 = CreateMenu(RPSmenuHandler);
							SetMenuTitle(rpsmenu2, "%t", "Rock Paper Scissors", LR_Player_Guard);
							SetArrayCell(gH_DArray_LR_Partners, idx, rpsmenu2, view_as<int>(Block_GuardData));
				
							FormatEx(r1, sizeof(r1), "%t", "Rock", LR_Player_Guard);
							FormatEx(p1, sizeof(p1), "%t", "Paper", LR_Player_Guard);
							FormatEx(s1, sizeof(s1), "%t", "Scissors", LR_Player_Guard);
							AddMenuItem(rpsmenu2, "0", r1);
							AddMenuItem(rpsmenu2, "1", p1);
							AddMenuItem(rpsmenu2, "2", s1);
				
							SetMenuExitButton(rpsmenu2, true);
							DisplayMenu(rpsmenu2, LR_Player_Guard, 15);
						}
						// if THIS player has won
						else if ((RPS_Guard_Choice == 0 && RPS_Prisoner_Choice == 2) || (RPS_Guard_Choice == 1 && RPS_Prisoner_Choice == 0) || (RPS_Guard_Choice == 2 && RPS_Prisoner_Choice == 1))
						{
							KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Done", LR_Player_Prisoner, RPSc1, LR_Player_Guard, RPSc2, LR_Player_Guard);
						}
						// otherwise THIS player has lost
						else
						{
							KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
							EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS Done", LR_Player_Prisoner, RPSc1, LR_Player_Guard, RPSc2, LR_Player_Prisoner);
						}				
					}				
				}		
			}			
		}

	}
	else if (action == MenuAction_Cancel)
	{
		int LR_Player_Prisoner, LR_Player_Guard;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_RockPaperScissors)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));	
				if (client == LR_Player_Prisoner || client == LR_Player_Guard)
				{
					if (EMP_IsValidClient(client, false, false))
					{
						if (g_Game == Game_CSGO)
						{
							CreateTimer(0.1, Timer_SafeSlay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						}
						else
						{
							EMP_SafeSlay(client);
						}
						
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR RPS No Answer", client);
					}
				}	
			}
		}
	}
	else if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
	return 0;
}

Action Timer_DodgeballCheckCheaters(Handle timer)
{
	// is there still a gun toss LR going on?
	bool bDodgeball = false;
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	int LR_Player_Prisoner, LR_Player_Guard;
	if (iArraySize > 0)
	{
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_Dodgeball)
			{
				bDodgeball = true;
				
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				if (IsValidEntity(LR_Player_Prisoner) && (GetClientHealth(LR_Player_Prisoner) > 1))
				{
					SetEntityHealth(LR_Player_Prisoner, 1);
				}
				if (IsValidEntity(LR_Player_Guard) && (GetClientHealth(LR_Player_Guard) > 1))
				{
					SetEntityHealth(LR_Player_Guard, 1);
				}
			}
		}
	}
	else
		return Plugin_Stop;
	
	if (!bDodgeball)
	{
		g_DodgeballTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timer_HotPotatoDone(Handle timer, any HotPotato_ID)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize > 0)
	{
		int thisHotPotato_ID, LR_Player_Prisoner, LR_Player_Guard, HPloser, HPwinner;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			thisHotPotato_ID = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global3));			
			if ((type == LR_HotPotato) && (HotPotato_ID == thisHotPotato_ID))
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				HPloser = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
				HPwinner = ((HPloser == LR_Player_Prisoner) ? LR_Player_Guard : LR_Player_Prisoner);
				
				KillAndReward(HPloser, HPwinner);
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "HP Win", HPwinner, HPloser);
				
				if (gH_Cvar_LR_HotPotato_Mode.IntValue != 2)
				{
					SetEntPropFloat(HPwinner, Prop_Data, "m_flLaggedMovementValue", 1.0);
				}
			}
		}
	}
	return Plugin_Stop;
}

// Gun Toss distance meter and BeamSprite application
public Action Timer_GunToss(Handle timer)
{
	// is there still a gun toss LR going on?
	int iNumGunTosses = 0;
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	
	char sHintTextGlobal[200];
	
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard, GTp1done, GTp2done, GTp1dropped, GTp2dropped, GTdeagle1, GTdeagle2;
		float GTdeagle1pos[3], GTdeagle2pos[3], GTdeagle1lastpos[3], GTdeagle2lastpos[3], GTp1droppos[3], GTp2droppos[3], GTp1jumppos[3], GTp2jumppos[3], fBeamWidth, fRefreshRate, beamStartP1[3], beamStartP2[3], f_SubtractVec[3] =  {0.0, 0.0, -30.0};
		Handle PositionDataPack;
		
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_GunToss)
			{
				iNumGunTosses++;
				
				GTp1done = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global3));
				GTp2done = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global4));
				GTp1dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
				GTp2dropped = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global2));
				GTdeagle1 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_PrisonerData)));
				GTdeagle2 = EntRefToEntIndex(GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_GuardData)));
				PositionDataPack = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_DataPackHandle));
				ResetPack(PositionDataPack);
				GTdeagle1lastpos[0] = ReadPackFloat(PositionDataPack);
				GTdeagle1lastpos[1] = ReadPackFloat(PositionDataPack);
				GTdeagle1lastpos[2] = ReadPackFloat(PositionDataPack);
				GTdeagle2lastpos[0] = ReadPackFloat(PositionDataPack);
				GTdeagle2lastpos[1] = ReadPackFloat(PositionDataPack);
				GTdeagle2lastpos[2] = ReadPackFloat(PositionDataPack);
				
				GTp1droppos[0] = ReadPackFloat(PositionDataPack);
				GTp1droppos[1] = ReadPackFloat(PositionDataPack);
				GTp1droppos[2] = ReadPackFloat(PositionDataPack);
				GTp2droppos[0] = ReadPackFloat(PositionDataPack);
				GTp2droppos[1] = ReadPackFloat(PositionDataPack);
				GTp2droppos[2] = ReadPackFloat(PositionDataPack);

				GTp1jumppos[0] = ReadPackFloat(PositionDataPack);
				GTp1jumppos[1] = ReadPackFloat(PositionDataPack);
				GTp1jumppos[2] = ReadPackFloat(PositionDataPack);
				GTp2jumppos[0] = ReadPackFloat(PositionDataPack);
				GTp2jumppos[1] = ReadPackFloat(PositionDataPack);
				GTp2jumppos[2] = ReadPackFloat(PositionDataPack);
				
				if(IsValidEntity(GTdeagle1))
				{
					GetEntPropVector(GTdeagle1, Prop_Data, "m_vecOrigin", GTdeagle1pos);
					if (GTp1dropped && !GTp1done)
					{
						if (GetVectorDistance(GTdeagle1lastpos, GTdeagle1pos) < 3.00)
						{
							GTp1done = true;
							SetArrayCell(gH_DArray_LR_Partners, idx, GTp1done, view_as<int>(Block_Global3));
						}
						else
						{
							GTdeagle1lastpos[0] = GTdeagle1pos[0];
							GTdeagle1lastpos[1] = GTdeagle1pos[1];
							GTdeagle1lastpos[2] = GTdeagle1pos[2];
							#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 8
								SetPackPosition(PositionDataPack, view_as<DataPackPos>(0));
							#else
								SetPackPosition(PositionDataPack, 0);
							#endif
							WritePackFloat(PositionDataPack, GTdeagle1lastpos[0]);
							WritePackFloat(PositionDataPack, GTdeagle1lastpos[1]);
							WritePackFloat(PositionDataPack, GTdeagle1lastpos[2]);
						}
					}
					else if (GTp1dropped && GTp1done)
					{
						fBeamWidth = (g_Game == Game_CSS ? 10.0 : 2.0);
						fRefreshRate = (g_Game == Game_CSS ? 0.1 : 1.0);
						
						if (gH_Cvar_LR_GunToss_Marker.BoolValue)
						{
							switch (gH_Cvar_LR_GunToss_MarkerMode.IntValue)
							{
								case 0:
								{
									MakeVectorFromPoints(f_SubtractVec, GTdeagle1lastpos, beamStartP1);
									TE_SetupBeamPoints(beamStartP1, GTdeagle1lastpos, BeamSprite, 0, 0, 0, fRefreshRate, fBeamWidth, fBeamWidth, 7, 0.0, redColor, 0);
								}
								case 1:
								{
									TE_SetupBeamPoints(GTp1droppos, GTdeagle1lastpos, BeamSprite, 0, 0, 0, fRefreshRate, fBeamWidth, fBeamWidth, 7, 0.0, redColor, 0);
								}
							}
		
							TE_SendToAll();		
						}
					}
				}
				
				if(IsValidEntity(GTdeagle2))
				{
					GetEntPropVector(GTdeagle2, Prop_Data, "m_vecOrigin", GTdeagle2pos);
					if (GTp2dropped && !GTp2done)
					{					
						if (GetVectorDistance(GTdeagle2lastpos, GTdeagle2pos) < 3.00)
						{
							GTp2done = true;
							SetArrayCell(gH_DArray_LR_Partners, idx, GTp2done, view_as<int>(Block_Global4));						
						}
						else
						{
							GTdeagle2lastpos[0] = GTdeagle2pos[0];
							GTdeagle2lastpos[1] = GTdeagle2pos[1];
							GTdeagle2lastpos[2] = GTdeagle2pos[2];
	
							#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 8
								SetPackPosition(PositionDataPack, view_as<DataPackPos>(3));
							#else
								SetPackPosition(PositionDataPack, 3);
							#endif
							WritePackFloat(PositionDataPack, GTdeagle2lastpos[0]);
							WritePackFloat(PositionDataPack, GTdeagle2lastpos[1]);
							WritePackFloat(PositionDataPack, GTdeagle2lastpos[2]);
						}
					}
					else if (GTp2dropped && GTp2done)
					{
						fBeamWidth = (g_Game == Game_CSS ? 10.0 : 2.0);
						fRefreshRate = (g_Game == Game_CSS ? 0.1 : 1.0);
						
						if (gH_Cvar_LR_GunToss_Marker.BoolValue)
						{
							switch (gH_Cvar_LR_GunToss_MarkerMode.IntValue)
							{
								case 0:
								{
									MakeVectorFromPoints(f_SubtractVec, GTdeagle2lastpos, beamStartP2);
									TE_SetupBeamPoints(beamStartP2, GTdeagle2lastpos, BeamSprite, 0, 0, 0, fRefreshRate, fBeamWidth, fBeamWidth, 7, 0.0, blueColor, 0);
								}
								case 1:
								{
									TE_SetupBeamPoints(GTp2droppos, GTdeagle2lastpos, BeamSprite, 0, 0, 0, fRefreshRate, fBeamWidth, fBeamWidth, 7, 0.0, blueColor, 0);
								}
							}
							
							TE_SendToAll();	
						}						
					}
				}
				
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				// broadcast distance
				if (gH_Cvar_LR_GunToss_ShowMeter.IntValue)
				{
					if (GTp2dropped)
					{
						f_DoneDistance[LR_Player_Guard] = GetVectorDistance(GTp2jumppos, GTdeagle2lastpos);
					}
					else
					{
						f_DoneDistance[LR_Player_Guard] = 0.0;
					}
					
					if (GTp1dropped)
					{
						f_DoneDistance[LR_Player_Prisoner] = GetVectorDistance(GTp1jumppos, GTdeagle1lastpos);
					}
					else
					{
						f_DoneDistance[LR_Player_Prisoner] = 0.0;
					}

					if (!gH_Cvar_SendGlobalMsgs.BoolValue)
					{
						if (g_Game == Game_CSS)
						{
							PrintHintText(LR_Player_Prisoner, "%t\n \n%N: %3.1f \n%N: %3.1f", "Distance Meter", LR_Player_Prisoner, f_DoneDistance[LR_Player_Prisoner], LR_Player_Guard, f_DoneDistance[LR_Player_Guard]);
							PrintHintText(LR_Player_Guard, "%t\n \n%N: %3.1f \n%N: %3.1f", "Distance Meter", LR_Player_Prisoner, f_DoneDistance[LR_Player_Prisoner], LR_Player_Guard, f_DoneDistance[LR_Player_Guard]);
						}
						else if (g_Game == Game_CSGO)
						{
							PrintHintText(LR_Player_Prisoner, "%t\n%N: %3.1f \n%N: %3.1f", "Distance Meter", LR_Player_Prisoner, f_DoneDistance[LR_Player_Prisoner], LR_Player_Guard, f_DoneDistance[LR_Player_Guard]);
							PrintHintText(LR_Player_Guard, "%t\n%N: %3.1f \n%N: %3.1f", "Distance Meter", LR_Player_Prisoner, f_DoneDistance[LR_Player_Prisoner], LR_Player_Guard, f_DoneDistance[LR_Player_Guard]);
						}
					}
					else
					{
						if (g_Game == Game_CSS)
						{
							Format(sHintTextGlobal, sizeof(sHintTextGlobal), "%s \n \n %N: %3.1f \n %N: %3.1f", sHintTextGlobal, LR_Player_Prisoner, f_DoneDistance[LR_Player_Prisoner], LR_Player_Guard, f_DoneDistance[LR_Player_Guard]);
						}
						else if (g_Game == Game_CSGO)
						{
							Format(sHintTextGlobal, sizeof(sHintTextGlobal), "%s \n %N: %3.1f \n %N: %3.1f", sHintTextGlobal, LR_Player_Prisoner, f_DoneDistance[LR_Player_Prisoner], LR_Player_Guard, f_DoneDistance[LR_Player_Guard]);
						}
					}
				}
			}
		}
	}
	
	if (gH_Cvar_LR_GunToss_ShowMeter.IntValue && gH_Cvar_SendGlobalMsgs.BoolValue && (iNumGunTosses > 0))
	{
		PrintHintTextToAll("%t %s", "Distance Meter", sHintTextGlobal);
	}
	
	if (iNumGunTosses <= 0)
	{
		g_GunTossTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_ChickenFight(Handle timer)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	bool bIsChickenFight = false;
	if (iArraySize > 0)
	{
		int LR_Player_Prisoner, LR_Player_Guard, p1EntityBelow, p2EntityBelow;
		for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
		{	
			int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
			if (type == LR_ChickenFight)
			{
				bIsChickenFight = true;
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				p1EntityBelow = GetEntDataEnt2(LR_Player_Prisoner, g_Offset_GroundEnt);
				p2EntityBelow = GetEntDataEnt2(LR_Player_Guard, g_Offset_GroundEnt);
				
				if (p1EntityBelow == LR_Player_Guard)
				{
					if (gH_Cvar_LR_ChickenFight_Slay.BoolValue)
					{
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Chicken Fight Win And Slay", LR_Player_Prisoner, LR_Player_Guard);
						KillAndReward(LR_Player_Guard, LR_Player_Prisoner);
					}
					else
					{
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Chicken Fight Win", LR_Player_Prisoner);
						CPrintToChat(LR_Player_Prisoner, "Chicken Fight Kill Loser", LR_Player_Guard);
						
						EMP_EquipKnife(LR_Player_Prisoner);
						
						SetEntityRenderColor(LR_Player_Guard, gH_Cvar_LR_ChickenFight_C_Red.IntValue, gH_Cvar_LR_ChickenFight_C_Green.IntValue, gH_Cvar_LR_ChickenFight_C_Blue.IntValue, 255);
						
						bIsChickenFight = false;
					}
				}
				else if (p2EntityBelow == LR_Player_Prisoner)
				{
					if (gH_Cvar_LR_ChickenFight_Slay.BoolValue)
					{
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Chicken Fight Win And Slay", LR_Player_Guard, LR_Player_Prisoner);
						KillAndReward(LR_Player_Prisoner, LR_Player_Guard);
					}
					else
					{
						EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "Chicken Fight Win", LR_Player_Guard);
						CPrintToChat(LR_Player_Guard, "Chicken Fight Kill Loser", LR_Player_Prisoner);
						
						EMP_EquipKnife(LR_Player_Guard);
						
						SetEntityRenderColor(LR_Player_Prisoner, gH_Cvar_LR_ChickenFight_C_Red.IntValue, gH_Cvar_LR_ChickenFight_C_Green.IntValue, gH_Cvar_LR_ChickenFight_C_Blue.IntValue, 255);
							
						bIsChickenFight = false;
					}
				}
			}
		}
	}
		
	if (!bIsChickenFight)
	{
		g_ChickenFightTimer = INVALID_HANDLE;
		return Plugin_Stop;	
	}
	
	return Plugin_Continue;
}

void DecideCheatersFate(int rebeller, int LRIndex, int victim = 0)
{
	// Grab the current LR and get the rebel action. Rebel action overrides are now discontinued.
	int rebelAction;	
	int type = GetArrayCell(gH_DArray_LR_Partners, LRIndex, view_as<int>(Block_LRType));
	switch (type)
	{
		/*
		case LR_KnifeFight:
		{
			rebelAction = gH_Cvar_LR_KnifeFight_Rebel.IntValue+1;
		}
		case LR_ChickenFight:
		{
			rebelAction = gH_Cvar_LR_ChickenFight_Rebel.IntValue+1;
		}
		case LR_HotPotato:
		{
			rebelAction = gH_Cvar_LR_HotPotato_Rebel.IntValue+1;
		}
		*/
		default:
		{
			rebelAction = gH_Cvar_CheatAction.IntValue;
		}
	}
	
	if (rebelAction == 0)
	{
		return;
	}
	
	char sWeaponName[32];
	int iClientWeapon = GetEntDataEnt2(rebeller, g_Offset_ActiveWeapon);
	if (IsValidEdict(iClientWeapon))
	{
		GetEdictClassname(iClientWeapon, sWeaponName, sizeof(sWeaponName));
		ReplaceString(sWeaponName, sizeof(sWeaponName), "weapon_", "");
	}
	else
	{
		FormatEx(sWeaponName, sizeof(sWeaponName), "unknown");
	}
	
	
	switch (rebelAction)
	{
		case 1:
		{
			if (IsPlayerAlive(rebeller))
			{
				Client_RemoveAllWeapons(rebeller);
			}
			CleanupLastRequest(rebeller, LRIndex);
			RemoveFromArray(gH_DArray_LR_Partners, LRIndex);
			if (victim == 0)
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Interference Abort - No Victim", rebeller, sWeaponName);
			}
			else if (victim == -1)
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Cheating Abort", rebeller);
			}
			else
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Interference Abort", rebeller, victim, sWeaponName);	
			}	
		}
		case 2:
		{
			if (IsPlayerAlive(rebeller))
			{
				if (g_Game == Game_CSGO)
				{
					CreateTimer(0.1, Timer_SafeSlay, GetClientUserId(rebeller), TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					EMP_SafeSlay(rebeller);
				}
			}
			if (victim == 0)
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Interference Slay - No Victim", rebeller, sWeaponName);
			}
			else if (victim == -1)
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Cheating Slay", rebeller);
			}
			else
			{
				EMP_LoopPlayers(TargetForLang) CPrintToChat(TargetForLang, "%s%t", gShadow_Hosties_ChatBanner, "LR Interference Slay", rebeller, victim, sWeaponName);	
			}		
		}
	}
}

Action Timer_SafeSlay(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	EMP_SafeSlay(client);
	return Plugin_Stop;
}

Action Timer_BeerGoggles(Handle timer)
{
	int timerCount = 1;
	timerCount++;
	if (timerCount > 160)
	{
		timerCount = 1;
	}
	
	float vecPunch[3];
	float drunkMultiplier = float(gH_Cvar_LR_KnifeFight_Drunk.IntValue);
	
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize == 0)
	{
		g_BeerGogglesTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	int LR_Player_Prisoner, LR_Player_Guard;
	for (int idx = 0; idx < GetArraySize(gH_DArray_LR_Partners); idx++)
	{
		int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
		if (type == LR_KnifeFight)
		{
			int KnifeChoice = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Global1));
			if (KnifeChoice == Knife_Drunk)
			{
				LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
				LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
				
				switch (timerCount % 4)
				{
					case 0:
					{
						vecPunch[0] = drunkMultiplier*5.0;
						vecPunch[1] = drunkMultiplier*5.0;
						vecPunch[2] = drunkMultiplier*-5.0;
					}
					case 1:
					{
						vecPunch[0] = drunkMultiplier*-5.0;
						vecPunch[1] = drunkMultiplier*-5.0;
						vecPunch[2] = drunkMultiplier*5.0;
					}
					case 2:
					{
						vecPunch[0] = drunkMultiplier*5.0;
						vecPunch[1] = drunkMultiplier*-5.0;
						vecPunch[2] = drunkMultiplier*5.0;
					}
					case 3:
					{
						vecPunch[0] = drunkMultiplier*-5.0;
						vecPunch[1] = drunkMultiplier*5.0;
						vecPunch[2] = drunkMultiplier*-5.0;
					}					
				}
				SetEntDataVector(LR_Player_Prisoner, g_Offset_PunchAngle, vecPunch, true);	
				SetEntDataVector(LR_Player_Guard, g_Offset_PunchAngle, vecPunch, true);
			}
		}
	}
	return Plugin_Continue;
}

void KillAndReward(int loser, int victor)
{
	Client_RemoveAllWeapons(loser);
	
	if (g_Game == Game_CSGO)
	{
		CreateTimer(0.1, Timer_SafeSlay, GetClientUserId(loser), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		EMP_SafeSlay(loser);
	}
	
	if (EMP_IsValidClient(victor, false, true))
	{
		if (g_Game == Game_CSS)
		{
			int iFrags = GetEntProp(victor, Prop_Data, "m_iFrags");
			iFrags += gH_Cvar_LR_VictorPoints.IntValue;
			SetEntProp(victor, Prop_Data, "m_iFrags", iFrags);
		}
		else if (g_Game == Game_CSGO)
		{
			int iResourceEntity = GetPlayerResourceEntity();
			if (iResourceEntity != -1)
			{
				int iScore = GetEntProp(iResourceEntity, Prop_Send, "m_iScore", _, victor);
				iScore += gH_Cvar_LR_VictorPoints.IntValue*2;
				SetEntProp(iResourceEntity, Prop_Send, "m_iScore", iScore, _, victor);
			}
		}
	}
}

void GetLastButton(int client, int &buttons, int idx)
{
	int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
	int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
	
	if (EMP_IsValidClient(client, false, false))
	{
		if (client == LR_Player_Prisoner || client == LR_Player_Guard)
		{
			int button;
			char classname[32];
			for (int i = 0; i < MAX_BUTTONS; i++)
			{
				button = (1 << i);
				if ((buttons & button))
				{
					if (!(g_LastButtons[client] & button))
					{
						if (button == IN_ATTACK2 || button == IN_ATTACK)
						{
							Client_GetActiveWeaponName(client, classname, 32);
							if (IsWeaponClassKnife(classname))
							{
								g_TriedToStab[client] = true;
							}
							else
							{
								g_TriedToStab[client] = false;
							}
						}
					}
				}
			}
		}
	}
	
	g_LastButtons[client] = buttons;
}

public Action Timer_StripZeus(Handle timer, int idx)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize == 0)
		return Plugin_Stop;
	
	int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
	int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
	
	if (!EMP_IsValidClient(LR_Player_Prisoner, false, false) || !IsClientInLastRequest(LR_Player_Prisoner) || !EMP_IsValidClient(LR_Player_Guard, false, false) || !IsClientInLastRequest(LR_Player_Guard))
		return Plugin_Stop;
	
	if (Client_HasWeapon(LR_Player_Prisoner, "weapon_taser"))
		Client_RemoveWeapon(LR_Player_Prisoner, "weapon_taser", false);
		
	if (Client_HasWeapon(LR_Player_Guard, "weapon_taser"))
		Client_RemoveWeapon(LR_Player_Guard, "weapon_taser", false);
	
	return Plugin_Continue;
}

void RightKnifeAntiCheat(int client, int idx)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize == 0)
		return;
		
	int type = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_LRType));
	int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Prisoner));
	int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, idx, view_as<int>(Block_Guard));
	
	if (client == LR_Player_Prisoner || client == LR_Player_Guard && EMP_IsValidClient(client))
	{		
		if (!((type == LR_KnifeFight) && !(type == LR_Rebel)) && ((type == LR_JumpContest) || (type == LR_Race) || (type == LR_ChickenFight) || (type == LR_Dodgeball) || \
			(type == LR_HotPotato) || (type == LR_Shot4Shot) || (type == LR_Mag4Mag) || (type == LR_NoScope) || (type == LR_RockPaperScissors) ||\
			(type == LR_RussianRoulette)))
		{
			if (EMP_IsValidClient(client, false, false))
			{
				if (g_TriedToStab[client] == true)
				{					
					DecideCheatersFate(client, idx);
					g_TriedToStab[client] = false;
				}
			}
		}		
	}
}

void UpdatePlayerCounts(int &Prisoners, int &Guards, int &iNumGuardsAvailable)
{
	for (int client=1; client <= MaxClients; client++)
	{
		if (!Client_MatchesFilter(client, CLIENTFILTER_INGAMEAUTH|CLIENTFILTER_NOBOTS|CLIENTFILTER_ALIVE)) //30W
			continue;

		if (GetClientTeam(client) == CS_TEAM_T)
			Prisoners++;

		else if (GetClientTeam(client) == CS_TEAM_CT)
		{
			Guards++;
			
			if (!g_bInLastRequest[client])
				iNumGuardsAvailable++;
		}
	}
}

void LastRequest_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetCorrectPlayerColor(client);
	
	if (g_Game == Game_CSGO)
	{
		int TeamBlock = GetConVarInt(Cvar_TeamBlock);
		
		if (TeamBlock == 1 || TeamBlock == 2)
			BlockEntity(client, g_Offset_CollisionGroup);
		else
			UnblockEntity(client, g_Offset_CollisionGroup);
	}
}

stock void PerformRestore(int client)
{
	if (EMP_IsValidClient(client, false, false))
	{
		Client_RemoveAllWeapons(client);
		
		if (gH_Cvar_LR_RestoreWeapon_CT.BoolValue && g_Game == Game_CSGO)
			LR_RestoreWeapons(client);

		if (gH_Cvar_LR_Fists_Instead_Knife.BoolValue)
		{
			int weapon;
			while((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1)
			{
				if (IsValidEntity(weapon))
				{
					RemovePlayerItem(client, weapon);
					RemoveEntity(weapon);
				}
			}
			
			EMP_EquipWeapon(client, "weapon_fists");
		}
		else if (GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == -1)
		{
			EMP_EquipKnife(client);
		}
	}
}

public bool TraceRayDontHitEntity(int entity,int mask, any data)
{
	if (entity == data) return false;
	return true;
}

public Action TimerTick_Equipper(Handle timer, int iPartnersIndex)
{
	int iArraySize = GetArraySize(gH_DArray_LR_Partners);
	if (iArraySize == 0)
		return Plugin_Stop;
		
	int type = GetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, view_as<int>(Block_LRType));
	int LR_Player_Prisoner = GetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, view_as<int>(Block_Prisoner));
	int LR_Player_Guard = GetArrayCell(gH_DArray_LR_Partners, iPartnersIndex, view_as<int>(Block_Guard)); //szejetjek masi :3 (mostmár én is programágus vagyok hahi)
	
	if (type != LR_ShieldFight && type != LR_HEFight) return Plugin_Stop;
	
	if (!EMP_IsValidClient(LR_Player_Guard, false, false) || !EMP_IsValidClient(LR_Player_Prisoner, false, false) || !IsClientInLastRequest(LR_Player_Prisoner) || !IsClientInLastRequest(LR_Player_Guard))
		return Plugin_Stop;

	if (type == LR_ShieldFight)
	{
		if (!Client_HasWeapon(LR_Player_Prisoner, "weapon_shield"))
			EMP_EquipWeapon(LR_Player_Prisoner, "weapon_shield");
		
		if (!Client_HasWeapon(LR_Player_Guard, "weapon_shield"))
			EMP_EquipWeapon(LR_Player_Guard, "weapon_shield");
	}
	else if (type == LR_HEFight)
	{
		if (!Client_HasWeapon(LR_Player_Prisoner, "weapon_hegrenade"))
			EMP_EquipWeapon(LR_Player_Prisoner, "weapon_hegrenade");
		
		if (!Client_HasWeapon(LR_Player_Guard, "weapon_hegrenade"))
			EMP_EquipWeapon(LR_Player_Guard, "weapon_hegrenade");
	}

	return Plugin_Continue;
}

void LR_SaveWeapons(int target)
{
	LR_C_WeaponCount[target] = 0;
	LR_C_FlashCounter[target] = GetEntProp(target, Prop_Data, "m_iAmmo", _, FlashbangOffset);
	if (EMP_IsValidClient(target, false, false))
	{
		int wep;
		for(int slot = 0; slot <= 4; slot++)
		{
			if(GetPlayerWeaponSlot(target, slot) > -1)
			{
				wep = GetPlayerWeaponSlot(target, slot);
				LR_SetWeaponClassname(wep, LR_C_sWeapon[target][slot], 64);
				RemovePlayerItem(target, wep);
				RemoveEdict(wep);
				LR_C_WeaponCount[target]++;
			}
			else LR_C_sWeapon[target][slot] = "";
		}
	}
	Client_RemoveAllWeapons(target);
}

void LR_RestoreWeapons(int target)
{
	if (EMP_IsValidClient(target))
	{
		char weapon_class[32];
		for (int g = 0; g <= LR_C_WeaponCount[target]; g++)
		{
			Format(weapon_class, sizeof(weapon_class), LR_C_sWeapon[target][g]);
			if (!StrEqual(weapon_class, "weapon_flashbang"))
			{
				if (String_StartsWith(weapon_class, "weapon_"))
				{
					if (!Client_HasWeapon(target, weapon_class))
					{
						if (StrEqual(weapon_class, "weapon_usp"))
							EMP_GiveWeapon(target, "weapon_usp_silencer");
						else
							EMP_GiveWeapon(target, weapon_class);
						FormatEx(LR_C_sWeapon[target][g], sizeof(LR_C_sWeapon[]), NULL_STRING);
					}
				}
			}
			else
			{
				for (int x = 1; x <= LR_C_FlashCounter[target]; x++)
				{
					EMP_GiveWeapon(target, weapon_class);
					FormatEx(LR_C_sWeapon[target][g], sizeof(LR_C_sWeapon[]), NULL_STRING);
				}
			}
		}
		
		C_WeaponCount[target] = 0;
	}
}

void LR_SetWeaponClassname(int weapon, char[] buffer, int size) 
{ 
	if (Weapon_IsValid(weapon))
	{
		if (GetEngineVersion() == Engine_CSGO) 
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
		else
		{
			GetEdictClassname(weapon, buffer, size);
		}
	}
}

void SetCorrectPlayerColor(int client)
{
	if (!EMP_IsValidClient(client, false, false))
	{
		return;
	}

	if (g_bIsARebel[client] && gH_Cvar_ColorRebels.IntValue)
	{
		SetEntityRenderColor(client, gH_Cvar_ColorRebels_Red.IntValue, gH_Cvar_ColorRebels_Green.IntValue, gH_Cvar_ColorRebels_Blue.IntValue, 255);
	}
	else
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

/* Returns whether the passed classname is a knife or not.
 * ---
 * const char[] classname	The classname to check. It doesn't have to contain "weapon_".
 * -
 * return bool				true if the passed classname contains "knife" or "bayonet", false if not. */
bool IsWeaponClassKnife(const char[] classname)
{
	return ((StrContains(classname, "knife", false) != -1) || (StrContains(classname, "bayonet", false) != -1));
}