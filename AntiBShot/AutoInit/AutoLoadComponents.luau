--!strict
local StarterPlayer = game:GetService("StarterPlayer")

local AutoLoadComponents = {}

function AutoLoadComponents.Init(autoFolder:Folder)
	
	local Components = {
		
		[autoFolder:WaitForChild("AntiBShotChatClient")] = StarterPlayer.StarterPlayerScripts,
		
	}
	
	for component, togo in pairs(Components) do
		if not togo:FindFirstChild(component.Name) then
			component:Clone().Parent=togo
		end
	end
end

return AutoLoadComponents
