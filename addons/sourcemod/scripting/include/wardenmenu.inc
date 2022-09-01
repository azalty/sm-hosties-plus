/*
* https://github.com/condolent/Better-Warden
*/

#if defined wardenmenuincluded
 #endinput
#endif
#define wardenmenuincluded

public SharedPlugin __pl_wardenmenu =
{
	name = "wardenmenu",
	file = "wardenmenu.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_wardenmenu_SetNTVOptional()
{
	MarkNativeAsOptional("IsEventDayActive");
	MarkNativeAsOptional("IsHnsActive");
	MarkNativeAsOptional("IsGravFreedayActive");
	MarkNativeAsOptional("IsWarActive");
	MarkNativeAsOptional("IsFreedayActive");
	MarkNativeAsOptional("ClientHasFreeday");
	MarkNativeAsOptional("GiveClientFreeday");
	MarkNativeAsOptional("RemoveClientFreeday");
	MarkNativeAsOptional("SetClientBeacon");
	MarkNativeAsOptional("ExecWarday");
	MarkNativeAsOptional("ExecFreeday");
	MarkNativeAsOptional("ExecHnS");
	MarkNativeAsOptional("ExecGravday");
}
#endif

stock bool g_bIsGameActive;
stock bool g_bAllowVotes;

/**
* Called when a warden opens the warden menu. Also called when a player becomes a warden if sm_cmenu_auto_open is set to 1.
*
* @param client 		Client index of the one opening the menu
*/
forward void OnCMenuOpened(int client);

/**
* Called when an event day is created.
*/
forward void OnEventDayCreated();

/**
* Called when an event day is aborted.
*/
forward void OnEventDayAborted();

/**
* Called when Hide and Seek is won.
*/
forward void OnHnsOver();

/**
* Check if there is a event day currently active.
* 
* @return				true if yes
*/
native bool IsEventDayActive();

/**
* Check if a Hide and Seek game is running.
*
* @return				true if yes
*/
native bool IsHnsActive();

/**
* Check if a Gravity Freeday is running.
*
* @return				true if yes
*/
native bool IsGravFreedayActive();

/**
* Check if a warday is running.
*
* @return				true if yes
*/
native bool IsWarActive();

/**
* Check if a freeday is running.
*
* @return				true if yes
*/
native bool IsFreedayActive();

/**
* Check if the specified client already has a freeday.
*
* @param client			Client index
* @return				true if yes
*/
native bool ClientHasFreeday(int client);

/**
* Give a client a freeday
*
* @param      client index
* @return     true if successful
*/
native bool GiveClientFreeday(int client);

/**
* Remove a client's freeday
*
* @param client			Client index
* @return				true if successful
*/
native bool RemoveClientFreeday(int client);

/**
* Sets a beacon on a client. Just like the one in the SM Admin Menu.
*
* @param client			Client index
* @param beaconState	State of the beacon
* @return				true if successful
*/
native bool SetClientBeacon(int client, bool beaconState);

/**
* Executes a warday. This will execute whether or not a game is already running.
* Make sure to check before with IsEventDayActive()!
*
* @return				true if successful
*/
native bool ExecWarday();

/**
* Executes a freeday. This will execute whether or not a game is already running.
* Make sure to check before with IsEventDayActive()!
*
* @return				true if successful
*/
native bool ExecFreeday();

/**
* Executes an HNS with the specified amount of winners. This will execute whether or not a game is already running.
* Make sure to check before with IsEventDayActive()!
*
* @param winners		The amount of winners
* @return				true if successful
*/
native bool ExecHnS(int winners);

/**
* Executes a gravity freeday. This will execute whether or not a game is already running.
* Make sure to check before with IsEventDayActive()!
*
* @return				true if successful
*/
native bool ExecGravday();