--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")
local BanServiceFolder = SharedServicesFolder:WaitForChild("BanService")
local BanDataStore = require(BanServiceFolder:FindFirstChild("BanDataStore"))
local BanList = require(BanServiceFolder:FindFirstChild("BanList"))
local BanEnforcer = require(BanServiceFolder:FindFirstChild("BanEnforcer"))

local BanService = {}

function BanService.Get(Uid : number) : any
	return BanDataStore.Get(Uid)
end

function BanService.Set(Uid : number, Data : any)
	BanDataStore.Set(Uid, Data)
end

function BanService.ListActive() : ({[number] : any}?, string?)
	return BanList.ListActive()
end

function BanService.SetPlayerRestrictions(plr : Player)
	BanEnforcer.SetPlayerRestrictions(plr)
end

return BanService