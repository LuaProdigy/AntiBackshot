--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

--//Vars
local AntiBackshotF = ReplicatedStorage:WaitForChild("AntiBackshot")
local RemotesF = ReplicatedStorage:WaitForChild("AntiBackshot"):FindFirstChild("Remotes")
local Remote = RemotesF:WaitForChild("AntiBackshotEvents")
local SystemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")

Remote.OnClientEvent:Connect(function(msg)
	SystemChannel:DisplaySystemMessage(msg)
end)
