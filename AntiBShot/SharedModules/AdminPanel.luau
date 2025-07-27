--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")



local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")
local BanServiceFolder = SharedServicesFolder:WaitForChild("BanService")


local Config = require(SharedModulesFolder:WaitForChild("Config"))
local BanService = require(BanServiceFolder:WaitForChild("BanService"))

local Remote = MainFolder.Remotes:WaitForChild("AntiBackshotEvents") :: RemoteEvent
local CmdFolder = TextChatService:WaitForChild("AntiBackshotCommands") :: Folder
local BanCmd = CmdFolder:WaitForChild("AntiBackshotBannedList") :: TextChatCommand

local Panel={}

local function isAdmin(Plr : Player) : boolean
	return Config.Admins[Plr.UserId] == true
end

local function tag(Color : Color3, Message : string) : string
	return string.format("<font color=\"rgb(%d,%d,%d)\">%s</font>", Color.R*255, Color.G*255, Color.B*255, Message)
end

local function chat(ToPlayer : Player, Message : string)
	
	local Prefix = tag(Config.AdminConfig.PrefixColor, Config.AdminConfig.Prefix)
	local Body = tag(Config.AdminConfig.MsgColor, Message)
	
	Remote:FireClient(ToPlayer, Prefix.." "..Body)
end

local function FormatMessage(Uid : number, BanData : any) : string
	
	local name = "Unknown User"
	
	local isk, plrname = pcall(function() 
		return Players:GetNameFromUserIdAsync(Uid) 
	end)
	
	if isk then 
		name = plrname 
	end
	
	if BanData.Expiry == math.huge then
		return string.format(Config.AdminConfig.PermaFormat, name)
	else
		local TimeRemaining = math.max(0, BanData.Expiry - os.time())
		return string.format(Config.AdminConfig.TempFormat, name, math.ceil(TimeRemaining/60))
	end
end

local function show(Admin : Player)
	
	local ActiveBans, errors = BanService.ListActive()
	
	if not ActiveBans then
		chat(Admin, Config.AdminConfig.DataStoreError.." ("..errors..")")
		return
	end
	
	if #ActiveBans == 0 then
		chat(Admin, Config.AdminConfig.BanListEmpty)
		return
	end
	
	for index, BanEntry in ipairs(ActiveBans) do
		chat(Admin, FormatMessage(BanEntry.Uid, BanEntry.Data))
	end
end

function Panel.Init()
	
	BanCmd.Triggered:Connect(function(useraction)
		
		local plr = Players:GetPlayerByUserId(useraction.UserId)
		
		if not plr then 
			return 
		end
		
		if isAdmin(plr) then 
			show(plr) 
		else 
			chat(plr, Config.AdminConfig.NoPermission) 
		end
	end)
end

return Panel
