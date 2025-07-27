--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local ServicesFolder = MainFolder:WaitForChild("Services")
local SharedModules = MainFolder:WaitForChild("SharedModules")
local SharedServices = MainFolder:WaitForChild("SharedServices")
local BanServiceFolder = SharedServices:WaitForChild("BanService")

local Config = require(SharedModules.Config)
local BanService = require(BanServiceFolder.BanService)
local PlayerState = require(ServicesFolder.AntiBackshot.PlayerStateService)
local Detection = require(ServicesFolder.AntiBackshot.DetectionService)

local PenaltyService = {}


local function TempBan(Uid : number, Minutes: number)
	
	local CurrentT = os.time()
	local BanData = BanService.Get(Uid) or { Total = 0, Expiry = 0 }
	
	BanData.Total += 1
	BanData.Expiry = CurrentT + Minutes * 60
	BanService.Set(Uid, BanData)
end

local function Punish(Attacker: Player, Humanoid: Humanoid)
	
	local State = PlayerState.Get(Attacker)
	local CurrentT = os.clock()

	if CurrentT - State.LastKillT < Config.Penalty.KillCooldown then
		return
	end

	State.LastKillT = CurrentT
	Humanoid.Health = 0
	State.AbuseCount += 1

	if State.AbuseCount < Config.Penalty.KillsBeforeBan then
		return
	end


	if Config.Penalty.KickPenalty and not Config.Penalty.BanPenalty then
		TempBan(Attacker.UserId, Config.Penalty.TempBanMinutes)

		local kickMsg = string.format(
			Config.KickMessages.TempBan,
			Config.Penalty.TempBanMinutes
		)
		Attacker:Kick(kickMsg)
		return
	end

	if not Config.Penalty.KickPenalty and Config.Penalty.BanPenalty then
		BanService.SetPlayerRestrictions(Attacker)
		return
	end


	if Config.Penalty.KickPenalty and Config.Penalty.BanPenalty then
		
		local banData = BanService.Get(Attacker.UserId) or { Total = 0, Expiry = 0 }
		
		banData.Total += 1

		if banData.Total < Config.Penalty.PermBanAfter then
			banData.Expiry = os.time() + Config.Penalty.TempBanMinutes * 60
			BanService.Set(Attacker.UserId, banData)

			local kickMsg = string.format(
				Config.KickMessages.TempBan,
				Config.Penalty.TempBanMinutes
			)
			Attacker:Kick(kickMsg)
		else
			BanService.SetPlayerRestrictions(Attacker)
		end
	end
end

function PenaltyService.Init()
	Detection.Event.Event:Connect(Punish)
end

return PenaltyService
