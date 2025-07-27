--!strict
local Config = {}

Config.Detection = {
	
	MaxDistance = 2.5,
	MinSpeed = 1,
	ThrustCount = 2,
	WithinTime = 2,
	
}

Config.Penalty = {
	
	KillCooldown = 1,
	KillsBeforeBan = 3,
	TempBanMinutes = 1,
	PermBanAfter = 3,
	KickPenalty = false,
	BanPenalty = false, 
	
}

Config.DataStore = {
	
	DataStoreName = "AntiBShotTB12",
	
}

Config.DebugVisual = {
	
	Enabled = false,
	Lifetime = 0.01,
	Thickness = 0.08,
	Color = Color3.fromRGB(255,0,0),
	
}

Config.KickMessages = {
	
	Permanent = "[AntiBShot]: Permanent banned, repeated backshot abuse.",
	TempBan = "[AntiBShot]: What you tryna do :/? You received a temporary ban for %d minutes",
	
}

Config.AdminConfig = {
	
	CommandPrefix = "!abbl",
	
	Prefix = "[AntiBShot]:",
	
	BanListEmpty = "The ban list is empty.",
	NoPermission = "You do not have permission to use this command.",
	DataStoreError = "Error - Could not access the ban list data.",
	
	PermaFormat = "[%s] - Perma Ban",
	TempFormat = "[%s] - Temp Ban - %d m",
	
	PrefixColor=Color3.fromRGB(4,175,236),
	MsgColor=Color3.fromRGB(248,248,248),
}

Config.Admins = {
	
	[71296349] = true,
	
}

return Config
