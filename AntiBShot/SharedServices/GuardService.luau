--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")
local ServicesFolder = MainFolder:WaitForChild("Services")
local BanServiceFolder = SharedServicesFolder:WaitForChild("BanService")

local BanService = require(BanServiceFolder:WaitForChild("BanService"))
local PlayerState = require(ServicesFolder:WaitForChild("AntiBackshot"):FindFirstChild("PlayerStateService"))

local GuardService = {}

local function KickBannedPlayer(Player : Player)
	
	local BanData = BanService.Get(Player.UserId)
	
	if BanData and BanData.Expiry > os.time() then
		Player:Kick("You are banned.")
	end
end

function GuardService.Start()
	
	for index, plr in ipairs(Players:GetPlayers()) do
		KickBannedPlayer(plr)
	end
	
	Players.PlayerAdded:Connect(KickBannedPlayer)
	
	Players.PlayerRemoving:Connect(PlayerState.Reset)
end

return GuardService
