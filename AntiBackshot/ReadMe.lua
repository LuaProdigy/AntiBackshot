--[[


	Anti-Backshot System 
	Created by: HardNinjaGreatorDev
	Distributed by: Studios Arc
	
	
	This system works via RayCasting
	
	
															  [Quick Setup Guide]:
	
	
	1. Place the "AntiBackshot" folder in ReplicatedStorage
	2. Place the AntiBackshotBootstrap script from the ServerScriptService folder into the ServerScriptService (without the folder just the script it self.)
	3. You are done, the rest of the components needed, is being automatically created for you.
	
	**The only file you might want to modify is Config, Please DO NOT touch any of the other scripts unless you know what you are doing**
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
																[Configuartions]:
	
	
	
	[Detection Configurations]:
	
	MaxDistance = 2.5, --// Determines the distance in which the player has to be form the other player, in order to detect if the player is backshotting.
	
	MinSpeed = 1, --// Determines the minimum walking speed a user can have while backshotting
	
	ThrustCount = 2, --// Determines how many times the user does the movemenet to detect he did a backshot, 2 times is ideal but you can adjust it.
	
	WithinTime = 2, --// Determines within how many seconds, the movement should occur in order to fetch it as a backshot. 
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
	[Penalty Configurations]:
	
	KillCooldown = 1, --// Determies the time needed after already killing the player, to kill him again.
	
	KillsBeforeBan = 3, --// Determines how many times the user can backshot before getting temporary banned
	
	TempBanMinutes = 1, --// How many minutes the temporary ban will last
	
	PermBanAfter = 3, --// If a player gets banned this many times, he gets permanently banned.
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
	[Datastore Configuration]:
	
	DataStoreName = "AntiBackshotMain", --// The name of the datastore, if you change it, it will be a new datastore.
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
	[Debug Configurations]: 
	
	Enabled = false, --// Enables/Disables the visible ray to the user for testing and debugging purposes. RECOMMENDED: false
	
	Lifetime = 0.01, --// Raycast's lifetime. RECOMMENDED NOT TO CHANGE IT
	
	Thickness = 0.08, --// Raycast Thickness.
	
	Color = Color3.fromRGB(255, 0, 0), --// Raycast Color

	----------------------------------------------------------------------------------------------------------------------------------------
	
	[Kick Messages Configurations]:
	
	Permanent = "[AntiBackshot]: Permanent banned, repeated backshot abuse.", --// The Kick message which will appear to the user if he's Permanent Banned
	
	TempBan = "[AntiBackshot]: What you tryna do :/ ? You received a temporary ban for %d minutes", --// The kick message which will appear to the user if he's Temporary Banned
	
	----------------------------------------------------------------------------------------------------------------------------------------
	
	[Admin Users Configurations]:
	
	[71296349] = true --// User ID of the admin. That's my id so change it to yours.
	
	You can add more people like that:
	
	[71296349] = true,
	[12345678] = true,
	[123456789] = true, 
	etc etc.

	----------------------------------------------------------------------------------------------------------------------------------------
	
	[Admin View Banned Players Configuarions]:
	
	**Quick Tip: You can use in the chat the command !abbl to view the currently banned users.**
	
	
	CommandPrefix = "!abbl", --// The prefix of the command to view the banned players.
	
	Prefix = "[AntiBackshot]:", --// The prefix of the messages.
	
	BanListEmpty = "The ban list is empty.", --// Message that will appear if the ban list is empty.
	
	NoPermission = "You do not have permission to use this command.", --// Message that will appear if the user doesn't have the permission to use the command.
	
	DataStoreError = "Error - Could not access the ban list data.", --// Message that will appear if there's an error with the datastore.
	
	PermaFormat = "[%s] - Perma Ban", --// The format of the permanent bans messages. %s = Username.
	
	TempFormat = "[%s] - Temp Ban - %d m", --// The format of the temporary bans messages. %s = Username. %d = Time.
	
	PrefixColor = Color3.fromRGB(4, 175, 236), --// The color of the message prefix.
	
	MsgColor = Color3.fromRGB(248, 248, 248), --// The color of the message.
	
]]