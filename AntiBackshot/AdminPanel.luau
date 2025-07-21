--//Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")


--//Main Variables
local AntiBackshotF = ReplicatedStorage:WaitForChild("AntiBackshot")
local Config = require(AntiBackshotF:WaitForChild("Config"))
local BanDataStore = DataStoreService:GetDataStore(Config.DataStore.DataStoreName)
local RemotesF = AntiBackshotF:WaitForChild("Remotes")
local Remote = RemotesF:WaitForChild("AntiBackshotEvents")
local CommandsF = TextChatService:WaitForChild("AntiBackshotCommands")
local BackshotBannedCmd = CommandsF:WaitForChild("AntiBackshotBannedList")


local AdminPanel = {}


local Admins = Config.Admins


function AdminPanel.IsAdmin(Player)

	if not Player then 
		return false 
	end

	return Admins[Player.UserId]
end



local function ColorTag(Color, Text)
	return string.format("<font color=\"rgb(%d,%d,%d)\">%s</font>",Color.R*255,Color.G*255,Color.B*255,Text)
end



local function SendChat(Admin, Text)

	local PrefixColor = Config.AdminConfig.PrefixColor
	local MessageColor = Config.AdminConfig.MsgColor

	local Prefix = string.format(
		"<font color=\"rgb(%d,%d,%d)\">%s</font>",
		PrefixColor.R*255, PrefixColor.G*255, PrefixColor.B*255,
		Config.AdminConfig.Prefix
	)

	local Body = string.format(
		"<font color=\"rgb(%d,%d,%d)\">%s</font>",
		MessageColor.R*255, MessageColor.G*255, MessageColor.B*255,
		Text
	)
	
	Remote:FireClient(Admin, Prefix.." "..Body)
end



local function SystemResponse(Uid,Data)

	local Name = "Unknown User"

	local plrname, fid = pcall(function() 
		return Players:GetNameFromUserIdAsync(tonumber(Uid)) 
	end)

	if plrname and fid then 
		Name = fid 
	end

	if Data.Expiry == math.huge then
		
		return string.format(Config.AdminConfig.PermaFormat, Name)
		
	else
		
		local Rem = math.max(0,Data.Expiry - os.time())
		
		return string.format(Config.AdminConfig.TempFormat, Name, math.ceil(Rem/60))
	end
end



local function ShowBans(AdminPlayer)

	local HasBannedPlayers = false

	local isk, key = pcall(function() 
		return BanDataStore:ListKeysAsync() 
	end)

	if not isk then
		SendChat(AdminPlayer, Config.AdminConfig.DataStoreError)
		return
	end

	while true do

		local isk, entries = pcall(function() 
			return key:GetCurrentPage() 
		end)

		if not isk then 
			break 
		end

		for i, Info in ipairs(entries) do

			local Key = Info.KeyName

			local isk, Data = pcall(function() 
				return BanDataStore:GetAsync(Key) 
			end)

			if isk and Data and (Data.Expiry == math.huge or Data.Expiry > os.time()) then

				HasBannedPlayers = true

				SendChat(AdminPlayer, SystemResponse(Key,Data))
			end
		end

		if key.IsFinished then 
			break 
		end

		pcall(function() 
			key:AdvanceToNextPageAsync() 
		end)
	end

	if not HasBannedPlayers then
		SendChat(AdminPlayer, Config.AdminConfig.BanListEmpty)
	end
end



function AdminPanel:Init()

	BackshotBannedCmd.Triggered:Connect(function(source)
		
		local player = Players:GetPlayerByUserId(source.UserId)
		
		if not player then return end

		if AdminPanel.IsAdmin(player) then
			ShowBans(player)
		else
			SendChat(player,Config.AdminConfig.NoPermission)
		end
	end)
end

return AdminPanel
