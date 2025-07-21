--!strict
--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")

--//Main Variables
local AntiBackshotF = ReplicatedStorage:WaitForChild("AntiBackshot")
local Config = require(AntiBackshotF:WaitForChild("Config"))
local Visual = Config.DebugVisual or {Enabled = false}

--//DS
local BanDataStore = DataStoreService:GetDataStore(Config.DataStore.DataStoreName)


local ConsCheck: RBXScriptConnection? = nil
local playerState = {}
local Banned = {}


local function GetPlayerRoot(Char: Model): BasePart?
	local PlayerRoot = Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Torso")
	if PlayerRoot and PlayerRoot:IsA("BasePart") then
		return PlayerRoot
	end
	return
end


local function DebugRay(Origin: Vector3, Direction: Vector3, HitPos: Vector3?)
	local Length = if HitPos then (HitPos - Origin).Magnitude else Direction.Magnitude

	if not Visual.Enabled then 
		return 
	end

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Visual.Color
	part.Transparency = 0.25
	part.Size = Vector3.new(Visual.Thickness, Visual.Thickness, Length)
	part.CFrame = CFrame.new(Origin + Direction.Unit * (Length * 0.5), Origin + Direction)
	part.Parent = workspace
	Debris:AddItem(part, Visual.Lifetime)
end



local function GetMovementDir(Root: BasePart): number

	if not Root then 
		return 0 
	end

	local Velocity = Root.AssemblyLinearVelocity
	local Dot = Velocity:Dot(Root.CFrame.LookVector)

	if math.abs(Dot) < Config.Detection.MinSpeed then 
		return 0 
	end

	return if (Dot >= 0) then 1 else -1
end



local function IsBehindVictim(AbuserRoot: BasePart, Victim: Model)

	local Origin = AbuserRoot.Position
	local Direction = AbuserRoot.CFrame.LookVector * Config.Detection.MaxDistance

	DebugRay(Origin, Direction)

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	if AbuserRoot.Parent then
		RayParams.FilterDescendantsInstances = {AbuserRoot.Parent}
	end

	local VisibleRay = workspace:Raycast(Origin, Direction, RayParams)

	if not VisibleRay or not VisibleRay.Instance then 
		return false 
	end

	if not VisibleRay.Instance:IsDescendantOf(Victim) then
		return false
	end

	local VictimRoot = GetPlayerRoot(Victim)
	if VictimRoot then
		local ToAttacker = AbuserRoot.Position - VictimRoot.Position
		if ToAttacker:Dot(VictimRoot.CFrame.LookVector) > 0 then
			return false
		end
	end

	return true
end



local function GetPlayerDsData(Uid)

	if Banned[Uid] then 
		return Banned[Uid] 
	end

	local isk, Data = pcall(function() 
		return BanDataStore:GetAsync(tostring(Uid)) 
	end)

	if isk and Data then 
		Banned[Uid] = Data 
		return Data 
	end

	return nil
end



local function SetPlayerDsData(Uid, Data)

	Banned[Uid] = Data

	pcall(function() 
		BanDataStore:SetAsync(tostring(Uid), Data) 
	end)
end



local function SetPlayerRestrictions(Player)

	local Uid = Player.UserId
	local CurrentT = os.time()
	local DsData = GetPlayerDsData(Uid) or 

		{
			Total = 0,
			Expiry = 0
		}

	DsData.Total += 1
	DsData.Expiry = (DsData.Total >= Config.Penalty.PermBanAfter) and math.huge or CurrentT + (Config.Penalty.TempBanMinutes * 60)

	SetPlayerDsData(Uid, DsData)

	local KickMsg = DsData.Expiry == math.huge and Config.KickMessages.Permanent or string.format(Config.KickMessages.TempBan, math.ceil((DsData.Expiry - CurrentT) / 60))

	Player:Kick(KickMsg)
end



local function PlayerState(Player)

	playerState[Player] = playerState[Player] or 

		{
			LastKillT = 0,
			AbuseCount = 0,
			ThrustCount = 0,
			LastDir = 0,
			FirstThrustT = 0
			
		}

	return playerState[Player]
end



local function ResetPlayerState(Player)
	playerState[Player] = nil
end



local function KillPlayer(Player, Humanoid)
	Humanoid.Health = 0
end



local function HandleKill(AbusivePlayer, AbusiveHumanoid)

	local State = PlayerState(AbusivePlayer)
	local CurrentT = os.clock()

	if CurrentT - State.LastKillT < Config.Penalty.KillCooldown then 
		return 
	end

	State.LastKillT = CurrentT
	KillPlayer(AbusivePlayer, AbusiveHumanoid)
	State.AbuseCount += 1

	if State.AbuseCount >= Config.Penalty.KillsBeforeBan then 
		SetPlayerRestrictions(AbusivePlayer) 
	end
end



local function DetectBackshot()

	for i, Abuser in ipairs(Players:GetPlayers()) do

		local Character, Humanoid = Abuser.Character, Abuser.Character and Abuser.Character:FindFirstChildOfClass("Humanoid")
		local Root = Character and GetPlayerRoot(Character)
		if not Root then
			return
		end	
		local State = PlayerState(Abuser)
		local Dir = GetMovementDir(Root)
		local CurrentT = os.clock()
		local IsBehind = false


		if not (Humanoid and Root) then 
			continue 
		end


		for i, Victim in ipairs(Players:GetPlayers()) do

			if Victim ~= Abuser and Victim.Character and IsBehindVictim(Root, Victim.Character) then
				IsBehind = true
				break
			end
		end


		if IsBehind then

			if Dir ~= 0 and Dir ~= State.LastDir then

				if State.ThrustCount == 0 then 
					State.FirstThrustT = CurrentT 
				end

				State.ThrustCount += 1
				State.LastDir = Dir
			end

			if CurrentT - State.FirstThrustT > Config.Detection.WithinTime then
				State.ThrustCount = 0
				State.LastDir = Dir
			end

			if State.ThrustCount >= Config.Detection.ThrustCount then
				State.ThrustCount = 0
				State.LastDir = 0
				HandleKill(Abuser, Humanoid)
			end

		else
			State.ThrustCount = 0
			State.LastDir = 0
		end
	end
end

local Core = {}

function Core.Start()

	if ConsCheck then 
		return 
	end

	for i, player in ipairs(Players:GetPlayers()) do

		local PlrData = GetPlayerDsData(player.UserId)

		if PlrData and PlrData.Expiry > os.time() then 
			player:Kick("You are banned.") 
		end
	end

	Players.PlayerAdded:Connect(function(player)

		local PlrData = GetPlayerDsData(player.UserId)

		if PlrData and PlrData.Expiry > os.time() then 
			player:Kick("You are banned.") 
		end
	end)

	Players.PlayerRemoving:Connect(ResetPlayerState)
	ConsCheck = RunService.Heartbeat:Connect(DetectBackshot)
end

function Core.Stop()
	
	if ConsCheck then
		ConsCheck:Disconnect()
		ConsCheck = nil
	end
	
	playerState = {}
end

return Core
