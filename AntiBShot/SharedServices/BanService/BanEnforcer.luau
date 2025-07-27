--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")
local BanServiceFolder = SharedServicesFolder:WaitForChild("BanService")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")
local Config = require(SharedModulesFolder:FindFirstChild("Config"))
local BanDataStore = require(BanServiceFolder:FindFirstChild("BanDataStore"))

local BanEnforcer = {}

function BanEnforcer.SetPlayerRestrictions(plr : Player)

	local Uid = plr.UserId

	local currentT = os.time()

	local BanData = BanDataStore.Get(Uid) or {Total = 0, Expiry = 0}

	BanData.Total += 1
	BanData.Expiry = (BanData.Total >= Config.Penalty.PermBanAfter) and math.huge or currentT + Config.Penalty.TempBanMinutes * 60

	BanDataStore.Set(Uid, BanData)

	local msg = (BanData.Expiry == math.huge) and Config.KickMessages.Permanent
		or string.format(Config.KickMessages.TempBan, math.ceil((BanData.Expiry - currentT) / 60))

	plr:Kick(msg)
end

return BanEnforcer