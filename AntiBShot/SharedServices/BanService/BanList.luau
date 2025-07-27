--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")
local BanServiceFolder = SharedServicesFolder:WaitForChild("BanService")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")
local Config = require(SharedModulesFolder:FindFirstChild("Config"))
local BanDataStore = require(BanServiceFolder:FindFirstChild("BanDataStore"))

local DS = DataStoreService:GetDataStore(Config.DataStore.DataStoreName)

local BanList = {}

function BanList.ListActive() : ({[number] : any}?, string?)

	local bans = {}

	local isk, keys = pcall(function() 
		return DS:ListKeysAsync() 
	end)

	if not isk then
		return nil, "ListKeys failed"
	end

	while true do

		local isk, entries=pcall(function() 
			return keys:GetCurrentPage() 
		end)

		if not isk then
			return nil, "Entries failed"
		end

		for index, info in ipairs(entries) do

			local key = info.KeyName

			local data = BanDataStore.Get(tonumber(key))

			if data and (data.Expiry == math.huge or data.Expiry > os.time()) then

				bans[#bans+1] = {Uid=tonumber(key), Data = data}

			end
		end

		if keys.IsFinished then 
			break 
		end

		keys:AdvanceToNextPageAsync()
	end

	return bans, nil
end

return BanList