--!nocheck
--!optimize 2

local TS = _G[script.Parent]
local LemonSignalCounter = TS.import(script, TS.getModule(script, "@rbxts", "lemon-signal-counter").dist)
return LemonSignalCounter
