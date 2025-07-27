--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")
local Config = require(SharedModulesFolder:FindFirstChild("Config"))

local DS = DataStoreService:GetDataStore(Config.DataStore.DataStoreName)

local BanDataStore = {}
local cached = {} :: {[number] : any}

local function get(Uid : number)

	if cached[Uid]~=nil then 
		return cached[Uid] 
	end

	local isk, Result = pcall(function() 
		return DS:GetAsync(tostring(Uid))
	end)

	cached[Uid] = if isk then 
		Result else nil
	return cached[Uid]

end

function BanDataStore.Get(Uid : number) : any
	return get(Uid)
end

function BanDataStore.Set(Uid : number, Data : any)

	cached[Uid] = Data

	pcall(function() 
		DS:SetAsync(tostring(Uid), Data) 
	end)
end

return BanDataStore