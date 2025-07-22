--!strict
--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

--//Vars
local RemotesF = ReplicatedStorage:WaitForChild("AntiBackshot"):FindFirstChild("Remotes")
if not RemotesF then
	return
end

local Remote = RemotesF:WaitForChild("AntiBackshotEvents") :: RemoteEvent
local SystemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem") :: TextChannel

if not Remote or not Remote:IsA("RemoteEvent") then
	return
end

Remote.OnClientEvent:Connect(function(msg)
	SystemChannel:DisplaySystemMessage(msg)
end)
