--!strict

type DeployObj = {
	Config: any,
	TextChatService: TextChatService,
	MainFolder: Folder,

	Init: (self: DeployObj) -> (),
}

local DeployComponents = {}
DeployComponents.__index = DeployComponents

function DeployComponents.new(
	config: any,
	textChat: TextChatService,
	mainFolder: Folder
): DeployObj

	local self = {} :: DeployObj
	setmetatable(self, DeployComponents)

	self.Config = config
	self.TextChatService = textChat
	self.MainFolder = mainFolder

	return self
end

------------------------------------------------------------------
function DeployComponents:Init()
	-- Remotes folder + event
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = self.MainFolder

	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = "AntiBackshotEvents"
	remoteEvent.Parent = remotes

	-- TextChat command folder + command
	local cmdFolder = Instance.new("Folder")
	cmdFolder.Name = "AntiBackshotCommands"
	cmdFolder.Parent = self.TextChatService

	local banListCmd = Instance.new("TextChatCommand")
	banListCmd.Name = "AntiBackshotBannedList"
	banListCmd.PrimaryAlias = self.Config.AdminConfig.CommandPrefix
	banListCmd.Parent = cmdFolder
end

return DeployComponents
