--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AntiBShotFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedModulesFolder = AntiBShotFolder:WaitForChild("SharedModules")

require(SharedModulesFolder:WaitForChild("Bootstrap")).Start()
