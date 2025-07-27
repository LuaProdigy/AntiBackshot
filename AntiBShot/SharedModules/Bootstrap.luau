--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")
local AutoInitFolder = MainFolder:WaitForChild("AutoInit")
local ServicesFolder = MainFolder:WaitForChild("Services")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")


local Config = require(SharedModulesFolder:WaitForChild("Config"))

local Deploy = require(AutoInitFolder:WaitForChild("DeployComponents")).new(Config, TextChatService, MainFolder)
local AutoLoader = require(AutoInitFolder:WaitForChild("AutoLoadComponents"))

local DetectionService = require(ServicesFolder:WaitForChild("AntiBackshot"):FindFirstChild("DetectionService"))
local GuardService = require(SharedServicesFolder:WaitForChild("GuardService"))
local PenaltyService = require(ServicesFolder:WaitForChild("AntiBackshot"):FindFirstChild("PenaltyService"))


local Bootstrap = {}

function Bootstrap.Start()
	Deploy:Init()
	AutoLoader.Init(MainFolder.AutoLoadComponents)
	
	local AdminPanel = require(SharedModulesFolder:WaitForChild("AdminPanel"))
	
	PenaltyService.Init()
	DetectionService.Start()
	GuardService.Start()
	AdminPanel.Init()
end

return Bootstrap
