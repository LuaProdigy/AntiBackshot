--!strict

local PlayerStateService = {}

local cached ={} :: {[Player]:{
	
	LastKillT : number,
	AbuseCount : number,
	ThrustCount : number,
	LastDir : number,
	FirstThrustT : number,
	
}}

function PlayerStateService.Get(plr : Player)
	
	cached[plr] = cached[plr] or {
		
		LastKillT = 0,
		AbuseCount = 0,
		ThrustCount = 0,
		LastDir = 0,
		FirstThrustT = 0,
		
	}
	
	return cached[plr]
end

function PlayerStateService.Reset(plr : Player)
	cached[plr]=nil
end

return PlayerStateService
