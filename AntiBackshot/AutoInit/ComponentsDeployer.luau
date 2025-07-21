local DeployComponents = {}

DeployComponents.__index = DeployComponents

function DeployComponents.new(Config, TextChatService, AntiBackshotF)
	local self = setmetatable({}, DeployComponents)
	self.Config = Config
	self.TextChatService = TextChatService
	self.MainFolder = AntiBackshotF
	return self
end

function DeployComponents:Init()
	
	local RemotesF = Instance.new("Folder")
	RemotesF.Name = "Remotes"
	RemotesF.Parent = self.MainFolder

	local Remote = Instance.new("RemoteEvent")
	Remote.Name = "AntiBackshotEvents"
	Remote.Parent = RemotesF

	local CommandsF = Instance.new("Folder")
	CommandsF.Name = "AntiBackshotCommands"
	CommandsF.Parent = self.TextChatService

	local BanlistCmd = Instance.new("TextChatCommand")
	BanlistCmd.Name = "AntiBackshotBannedList"
	BanlistCmd.PrimaryAlias = self.Config.AdminConfig.CommandPrefix
	BanlistCmd.Parent = CommandsF
end

return DeployComponents
