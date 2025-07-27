--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")


local DebugRay = require(SharedModulesFolder.Config).DebugVisual

local DebugService={}

function DebugService.Ray(Origin : Vector3, Dir : Vector3, HitPos : Vector3?)
	
	if not DebugRay.Enabled then 
		return 
	end
	
	local Length = HitPos and (HitPos-Origin).Magnitude or Dir.Magnitude
	local Rayc = Instance.new("Part")
	
	Rayc.Anchored = true
	Rayc.CanCollide = false
	Rayc.CastShadow = false
	Rayc.Material = Enum.Material.Neon
	Rayc.Color = DebugRay.Color
	Rayc.Transparency = 0.25
	Rayc.Size = Vector3.new(DebugRay.Thickness, DebugRay.Thickness, Length)
	Rayc.CFrame = CFrame.new(Origin + Dir.Unit* (Length * 0.5), Origin + Dir)
	Rayc.Parent = workspace
	
	Debris:AddItem(Rayc, DebugRay.Lifetime)
end

return DebugService
