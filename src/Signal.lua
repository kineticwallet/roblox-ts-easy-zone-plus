--!nocheck
--!optimize 2

local TS = _G[script.Parent]
return TS.import(script, TS.getModule(script, "@rbxts", "lemon-signal").dist).Signal
