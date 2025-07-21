--!strict
--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

--//Vars 
local AntiBackshotF = ReplicatedStorage:WaitForChild("AntiBackshot")
local AutoInitF = AntiBackshotF:WaitForChild("AutoInit")
local Config = require(AntiBackshotF:WaitForChild("Config"))
local DeployComponents = require(AutoInitF:WaitForChild("ComponentsDeployer"))

local ABChatClient = AutoInitF:WaitForChild("AntiBackshotChatClient")

local Deploy = DeployComponents.new(Config, TextChatService, AntiBackshotF)

if not StarterPlayerScripts:FindFirstChild(ABChatClient.Name) then
	ABChatClient:Clone().Parent = StarterPlayerScripts
end

Deploy:Init()

local AdminPanel = require(AntiBackshotF:WaitForChild("AdminPanel"))
local AntiBackshotCore = require(AntiBackshotF:WaitForChild("AntiBackshotMain"))


AdminPanel:Init()
AntiBackshotCore.Start()
