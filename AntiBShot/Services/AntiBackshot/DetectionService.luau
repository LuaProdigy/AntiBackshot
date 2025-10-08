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
DetectionService.Dump = nil

local heartbeatConnection

local function getRoot(char)
	local candidate = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
	if candidate and candidate:IsA("BasePart") then
		return candidate
	end
	return nil
end

local bit = {}
local UINT32 = 4294967296
local UINT31 = 2147483648
local function toUint32(n)
	local f = math.floor((n or 0) + 0.0)
	local r = f % UINT32
	if r < 0 then
		r = r + UINT32
	end
	return r
end
local function toInt32(u)
	local v = toUint32(u)
	if v >= UINT31 then
		return v - UINT32
	end
	return v
end
function bit.lshift(x, n)
	n = (n or 0) % 32
	local v = toUint32(x)
	local s = toUint32((v * (2 ^ n)))
	return s % UINT32
end
function bit.rshift(x, n)
	n = (n or 0) % 32
	local v = toUint32(x)
	return math.floor(v / (2 ^ n)) % UINT32
end
function bit.arshift(x, n)
	n = (n or 0) % 32
	local i = toInt32(x)
	if i >= 0 then
		return math.floor(i / (2 ^ n))
	else
		local shifted = math.floor((i) / (2 ^ n))
		return shifted
	end
end
function bit.band(a, b)
	local A = toUint32(a)
	local B = toUint32(b)
	local r = 0
	for i = 0, 31 do
		local ai = (math.floor(A / (2 ^ i)) % 2)
		local bi = (math.floor(B / (2 ^ i)) % 2)
		if ai == 1 and bi == 1 then
			r = r + (2 ^ i)
		end
	end
	return toUint32(r)
end
function bit.bor(a, b)
	local A = toUint32(a)
	local B = toUint32(b)
	local r = 0
	for i = 0, 31 do
		local ai = (math.floor(A / (2 ^ i)) % 2)
		local bi = (math.floor(B / (2 ^ i)) % 2)
		if ai == 1 or bi == 1 then
			r = r + (2 ^ i)
		end
	end
	return toUint32(r)
end
function bit.bxor(a, b)
	local A = toUint32(a)
	local B = toUint32(b)
	local r = 0
	for i = 0, 31 do
		local ai = (math.floor(A / (2 ^ i)) % 2)
		local bi = (math.floor(B / (2 ^ i)) % 2)
		if (ai + bi) % 2 == 1 then
			r = r + (2 ^ i)
		end
	end
	return toUint32(r)
end
function bit.bnot(a)
	local A = toUint32(a)
	local r = 0
	for i = 0, 31 do
		local ai = (math.floor(A / (2 ^ i)) % 2)
		if ai == 0 then
			r = r + (2 ^ i)
		end
	end
	return toUint32(r)
end

local S_SHIFT = 12
local SCALE = bit.lshift(1, S_SHIFT)

local function abs_int(x)
	if x < 0 then
		return -x
	end
	return x
end

local function ftoi(n)
	local neg = (n < 0) and 1 or 0
	local a = abs_int(n or 0)
	local scaled = math.floor(a * SCALE + 0.5)
	local val = (neg == 1) and -scaled or scaled
	local asint = toInt32(val)
	return asint
end

local function itof(i)
	return (i or 0) / SCALE
end

local function clamp_bitwise(x, a, b)
	if x ~= x then
		return a
	end
	if x < a then
		return a
	end
	if x > b then
		return b
	end
	return x
end

local VM = {}
VM.stack = {}
VM.sp = 0
VM.regs = {0,0,0,0,0,0,0,0}
VM.ip = 1
VM.code = {}
VM.mem = {}
VM.ops = {}
VM.callstack = {}
VM.halted = false

local function vm_push(v)
	VM.sp = VM.sp + 1
	VM.stack[VM.sp] = v
end
local function vm_pop()
	if VM.sp <= 0 then
		return 0
	end
	local v = VM.stack[VM.sp]
	VM.stack[VM.sp] = nil
	VM.sp = VM.sp - 1
	return v
end
local function vm_peek()
	if VM.sp <= 0 then
		return 0
	end
	return VM.stack[VM.sp]
end
local function vm_reset()
	VM.stack = {}
	VM.sp = 0
	for i=1,#VM.regs do
		VM.regs[i] = 0
	end
	VM.ip = 1
	VM.code = {}
	VM.mem = {}
	VM.callstack = {}
	VM.halted = false
end

VM.ops["PUSHI"] = function(arg) vm_push(arg or 0) end
VM.ops["PUSHF"] = function(arg) vm_push(arg or 0) end
VM.ops["ADD"] = function() local b=vm_pop() local a=vm_pop() vm_push(a+b) end
VM.ops["SUB"] = function() local b=vm_pop() local a=vm_pop() vm_push(a-b) end
VM.ops["MUL"] = function() local b=vm_pop() local a=vm_pop() vm_push(a*b) end
VM.ops["DIV"] = function() local b=vm_pop() local a=vm_pop() vm_push((b == 0) and 0 or (a/b)) end
VM.ops["SQRT"] = function() local a=vm_pop() vm_push((a >= 0) and math.sqrt(a) or 0) end
VM.ops["COS"] = function() local a=vm_pop() vm_push(math.cos(a)) end
VM.ops["SIN"] = function() local a=vm_pop() vm_push(math.sin(a)) end
VM.ops["ACOS"] = function() local a=vm_pop() vm_push(math.acos(math.min(1, math.max(-1, a)))) end
VM.ops["ATAN2"] = function() local a=vm_pop() local b=vm_pop() vm_push(math.atan2(a,b)) end
VM.ops["ABS"] = function() local a=vm_pop() vm_push(math.abs(a)) end
VM.ops["NEG"] = function() local a=vm_pop() vm_push(-a) end
VM.ops["BAND"] = function() local b=vm_pop() local a=vm_pop() vm_push(bit.band(a,b)) end
VM.ops["BOR"] = function() local b=vm_pop() local a=vm_pop() vm_push(bit.bor(a,b)) end
VM.ops["BXOR"] = function() local b=vm_pop() local a=vm_pop() vm_push(bit.bxor(a,b)) end
VM.ops["LSH"] = function() local b=vm_pop() local a=vm_pop() vm_push(bit.lshift(a,b)) end
VM.ops["RSH"] = function() local b=vm_pop() local a=vm_pop() vm_push(bit.rshift(a,b)) end
VM.ops["ARSH"] = function() local b=vm_pop() local a=vm_pop() vm_push(bit.arshift(a,b)) end
VM.ops["CEIL"] = function() local a=vm_pop() vm_push(math.ceil(a)) end
VM.ops["FLOOR"] = function() local a=vm_pop() vm_push(math.floor(a)) end
VM.ops["TOINT"] = function() local a=vm_pop() vm_push(toInt32(a)) end
VM.ops["TOUINT"] = function() local a=vm_pop() vm_push(toUint32(a)) end
VM.ops["STORE"] = function(addr) VM.mem[addr or 0] = vm_pop() end
VM.ops["LOAD"] = function(addr) vm_push(VM.mem[addr or 0] or 0) end
VM.ops["MOVR"] = function(arg) VM.regs[arg or 1] = vm_pop() end
VM.ops["PUSHR"] = function(arg) vm_push(VM.regs[arg or 1] or 0) end
VM.ops["CALL"] = function(arg) table.insert(VM.callstack, VM.ip) VM.ip = (arg or VM.ip) end
VM.ops["RET"] = function() local r = table.remove(VM.callstack) if r then VM.ip = r end end
VM.ops["JZ"] = function(arg) local v = vm_pop() if v == 0 then VM.ip = (arg or VM.ip) end end
VM.ops["JNZ"] = function(arg) local v = vm_pop() if v ~= 0 then VM.ip = (arg or VM.ip) end end
VM.ops["NOP"] = function() end
VM.ops["END"] = function() VM.halted = true VM.ip = #VM.code + 1 end

VM.ops["INVOKE"] = function(arg)
	local argc = arg or 0
	local args = {}
	for i = argc, 1, -1 do
		args[i] = vm_pop()
	end
	local fn = vm_pop()
	if type(fn) ~= "function" then
		vm_push(0)
		return
	end
	local ok, ret = pcall(fn, table.unpack(args))
	if not ok then
		vm_push(0)
		return
	end
	if ret == nil then
		vm_push(0)
	else
		vm_push(ret)
	end
end

local function safe_traceback()
	local ok, tb = pcall(function() return debug and debug.traceback and debug.traceback() end)
	return ok and tb or "no-backtrace"
end

local function dump_state(err)
	local parts = {}
	parts[#parts+1] = "DUMP_V1"
	parts[#parts+1] = "ERR:" .. tostring(err)
	parts[#parts+1] = "VM_IP:" .. tostring(VM.ip)
	parts[#parts+1] = "CALLSTACK:"
	for i=#VM.callstack,1,-1 do
		parts[#parts+1] = "\t" .. tostring(VM.callstack[i])
	end
	parts[#parts+1] = "REGS:"
	for i=1,#VM.regs do
		parts[#parts+1] = "\tR" .. i .. ":" .. tostring(VM.regs[i])
	end
	parts[#parts+1] = "STACK:"
	for i=1,VM.sp do
		parts[#parts+1] = "\t[" .. tostring(i) .. "]=" .. tostring(VM.stack[i])
	end
	parts[#parts+1] = "MEM_KEYS:"
	for k,v in pairs(VM.mem) do
		parts[#parts+1] = "\t" .. tostring(k) .. "=" .. tostring(v)
	end
	parts[#parts+1] = "CODE_SAMPLE:"
	local starti = math.max(1, VM.ip - 6)
	local endi = math.min(#VM.code, VM.ip + 6)
	for i = starti, endi do
		local inst = VM.code[i]
		if type(inst) == "table" then
			parts[#parts+1] = ("\t%04d: %s %s"):format(i, tostring(inst[1]), tostring(inst[2]))
		else
			parts[#parts+1] = ("\t%04d: %s"):format(i, tostring(inst))
		end
	end
	parts[#parts+1] = "LUA_TRACEBACK:"
	parts[#parts+1] = safe_traceback()
	local out = table.concat(parts, "\n")
	DetectionService.Dump = out
	pcall(function() print(out) end)
	return out
end


local function vm_run(code: any)
	vm_reset()
	VM.code = code or {}
	local function exec()
		local steps = 0
		local maxsteps = 20000
		while (not VM.halted) and VM.ip <= #VM.code do
			steps = steps + 1
			if steps > maxsteps then
				error("vm: step limit")
			end
			local inst = VM.code[VM.ip]
			VM.ip = VM.ip + 1
			if type(inst) == "table" then
				local op = inst[1]
				local arg = inst[2]
				local handler = VM.ops[op]
				if handler then
					handler(arg)
				else
					error("bad op:" .. tostring(op))
				end
			elseif type(inst) == "string" then
				local handler = VM.ops[inst]
				if handler then
					handler()
				else
					error("bad opstr:" .. tostring(inst))
				end
			else
				error("bad inst type")
			end
		end
		return vm_pop()
	end
	local ok, resOrDump = xpcall(exec, function(err)
		local ok2, dump = pcall(dump_state, err)
		return (ok2 and dump) or ("dump-failed:" .. tostring(err))
	end)
	if not ok then
		return nil
	end
	return resOrDump
end

DetectionService.RunCode = function(code)
	if type(code) ~= "table" then
		return nil
	end
	local safe = {}
	for i = 1, #code do
		local inst = code[i]
		if type(inst) == "table" then
			local op = inst[1]
			local arg = inst[2]
			if type(op) ~= "string" then
				return nil
			end
			if not VM.ops[op] then
				return nil
			end
			safe[#safe + 1] = {op, arg}
		elseif type(inst) == "string" then
			if not VM.ops[inst] then
				return nil
			end
			safe[#safe + 1] = inst
		else
			return nil
		end
	end
	local last = safe[#safe]
	if not (last == "END" or (type(last) == "table" and last[1] == "END")) then
		safe[#safe + 1] = "END"
	end
	local ok, res = pcall(vm_run, safe)
	if not ok then
		return nil
	end
	if res == nil and VM.sp > 0 then
		return vm_pop()
	end
	return res
end


local function dot_fixed(a, b)
	local ax = ftoi(a.X)
	local ay = ftoi(a.Y)
	local az = ftoi(a.Z)
	local bx = ftoi(b.X)
	local by = ftoi(b.Y)
	local bz = ftoi(b.Z)
	local code = {
		{"PUSHI", ax}, {"MOVR", 1},
		{"PUSHI", bx}, {"MOVR", 2},
		{"PUSHR", 1}, {"PUSHR", 2}, "MUL",
		{"PUSHI", ay}, {"MOVR", 3},
		{"PUSHI", by}, {"MOVR", 4},
		{"PUSHR", 3}, {"PUSHR", 4}, "MUL", "ADD",
		{"PUSHI", az}, {"MOVR", 5},
		{"PUSHI", bz}, {"MOVR", 6},
		{"PUSHR", 5}, {"PUSHR", 6}, "MUL", "ADD",
		"END"
	}
	local s = vm_run(code)
	if not s then
		return 0
	end
	local result = s / (SCALE * SCALE)
	return result
end

local function mag_fixed(v)
	local x = ftoi(v.X)
	local y = ftoi(v.Y)
	local z = ftoi(v.Z)
	local code = {
		{"PUSHI", x}, {"MOVR", 1}, {"PUSHR", 1}, {"PUSHR",1}, "MUL",
		{"PUSHI", y}, {"MOVR", 2}, {"PUSHR", 2}, {"PUSHR", 2}, "MUL", "ADD",
		{"PUSHI", z}, {"MOVR", 3}, {"PUSHR", 3}, {"PUSHR", 3}, "MUL", "ADD",
		"SQRT", "END"
	}
	local s = vm_run(code)
	if not s then
		return 0
	end
	local res = s / SCALE
	return res
end

local function obf_sign(v)
	local p = v >= 0 and 1 or 0
	local r = bit.band(p, 1)
	local t = bit.bxor(bit.lshift(r, 0), 0)
	if t == 0 then
		return -1
	end
	return 1
end

local function movementDir(root)
	local v = root.AssemblyLinearVelocity
	local f = root.CFrame.LookVector
	local a = dot_fixed(v, f)
	local b = mag_fixed(v)
	local c = mag_fixed(f)
	local denom = (b * c) + 1e-10
	local d = a / denom
	local cl = clamp_bitwise(d, -1, 1)
	local ac = math.acos(cl)
	local g = b * math.cos(ac)
	local cmp = a / (c + 1e-9)
	local diff = g - cmp
	local absd = math.abs(diff)
	if absd < Config.Detection.MinSpeed then
		return 0
	end
	local t1 = math.atan2(f.Y, f.Z)
	local t2 = math.atan2(v.Y, v.Z)
	local angSum = t1 + t2 - ac
	local cs = math.cos(angSum)
	local signFlag = cs >= 0 and 1 or 0
	local mask = vm_run({{"PUSHI", signFlag}, {"PUSHI", 1}, "BAND", "END"})
	if not mask then
		return 0
	end
	if mask == 1 then
		local x = vm_run({{"PUSHI", mask}, {"PUSHI", 0}, "BXOR", "END"})
		if x == 1 then
			return 1
		end
	end
	local z = vm_run({{"PUSHI", 0}, {"PUSHI", 0}, "BXOR", "END"})
	if z == 0 then
		return -1
	end
	return -1
end

local function isBehind(attRoot, victimChar)
	local o = attRoot.Position
	local d = attRoot.CFrame.LookVector * Config.Detection.MaxDistance
	Debug.Ray(o, d)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local cm = attRoot.Parent
	if cm then
		p.FilterDescendantsInstances = { cm }
	end
	local h = workspace:Raycast(o, d, p)
	if not h or not h.Instance then
		return false
	end
	if not h.Instance:IsDescendantOf(victimChar) then
		return false
	end
	local vr = getRoot(victimChar)
	if vr then
		local t = Vector3.new(
			(attRoot.Position.X - vr.Position.X),
			(attRoot.Position.Y - vr.Position.Y),
			(attRoot.Position.Z - vr.Position.Z)
		)
		local lv = vr.CFrame.LookVector
		local dp = dot_fixed(t, lv)
		local ml = mag_fixed(t)
		local nl = mag_fixed(lv)
		local denom = (ml * nl) + 1e-10
		local cth = dp / denom
		local cthc = clamp_bitwise(cth, -1, 1)
		local ang = math.acos(cthc)
		local s = math.sin(ang)
		local abscth = math.abs(cth)
		local safe = (1e-9 + abscth)
		local vval = (dp * s) / safe
		local positive = vval > 0 and 1 or 0
		local flip = vm_run({{"PUSHI", positive}, {"PUSHI", 0}, "BXOR", "END"})
		if not flip then
			return false
		end
		if flip == 1 then
			return false
		end
	end
	return true
end

local function step()
	for _, attacker in ipairs(Players:GetPlayers()) do
		local char = attacker.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and getRoot(char)
		if not (hum and root) then
			print('no hum and root')
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
				state.ThrustCount = state.ThrustCount + 1
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
