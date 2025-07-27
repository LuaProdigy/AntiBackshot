--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainFolder = ReplicatedStorage:WaitForChild("AntiBShot")
local ServicesFolder = MainFolder:WaitForChild("Services")
local SharedServicesFolder = MainFolder:WaitForChild("SharedServices")
local SharedModulesFolder = MainFolder:WaitForChild("SharedModules")

local Config = require(SharedModulesFolder:WaitForChild("Config"))
local PlayerState = require(ServicesFolder:WaitForChild("AntiBackshot"):FindFirstChild("PlayerStateService"))
local Debug = require(SharedServicesFolder:WaitForChild("DebugService"))

local DetectionService = {}
DetectionService.Event = Instance.new("BindableEvent")

local heartbeatConnection : RBXScriptConnection?

local function getRoot(char : Model) : BasePart?
	local candidate = char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")

	if candidate and candidate:IsA("BasePart") then
		return candidate
	end

	return nil
end

local function movementDir(root: BasePart) : number
	local v = root.AssemblyLinearVelocity
	local dot = v:Dot(root.CFrame.LookVector)
	if math.abs(dot) < Config.Detection.MinSpeed then
		return 0
	end
	return (dot >= 0) and 1 or -1
end

local function isBehind(attRoot: BasePart, victimChar: Model): boolean
	local origin = attRoot.Position
	local dir = attRoot.CFrame.LookVector * Config.Detection.MaxDistance
	Debug.Ray(origin, dir)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local characterModel = attRoot.Parent
	if characterModel then
		params.FilterDescendantsInstances = { characterModel }
	end

	local hit = workspace:Raycast(origin, dir, params)
	if not hit or not hit.Instance then
		return false
	end
	if not hit.Instance:IsDescendantOf(victimChar) then
		return false
	end

	local victimRoot = getRoot(victimChar)
	if victimRoot then
		local toAttacker = attRoot.Position - victimRoot.Position
		if toAttacker:Dot(victimRoot.CFrame.LookVector) > 0 then
			return false
		end
	end
	return true
end

local function step()
	for _, attacker in ipairs(Players:GetPlayers()) do
		local char = attacker.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		local root = char and getRoot(char) :: BasePart?
		if not (hum and root) then
			continue
		end

		local state = PlayerState.Get(attacker)
		local dir = movementDir(root)
		local now = os.clock()
		local behind = false

		for _, victim in ipairs(Players:GetPlayers()) do
			if victim ~= attacker and victim.Character and isBehind(root, victim.Character) then
				behind = true
				break
			end
		end

		if behind then
			if dir ~= 0 and dir ~= state.LastDir then
				if state.ThrustCount == 0 then
					state.FirstThrustT = now
				end
				state.ThrustCount += 1
				state.LastDir = dir
			end

			if now - state.FirstThrustT > Config.Detection.WithinTime then
				state.ThrustCount = 0
				state.LastDir = dir
			end

			if state.ThrustCount >= Config.Detection.ThrustCount then
				state.ThrustCount = 0
				state.LastDir = 0
				DetectionService.Event:Fire(attacker, hum)
			end
		else
			state.ThrustCount = 0
			state.LastDir = 0
		end
	end
end

function DetectionService.Start()
	if heartbeatConnection then
		return
	end
	heartbeatConnection = RunService.Heartbeat:Connect(step)
end

function DetectionService.Stop()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

return DetectionService
