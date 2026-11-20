-- Toca un sonido de Config/Sounds (si tiene número; 0 = sin sonido).
-- Si le das una pieza, el sonido sale de ahí (se oye más fuerte de cerca).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)

local Sfx = {}

function Sfx.Play(key: string, at: Instance?)
	local id = (Sounds :: any)[key]
	if not id or id == 0 then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = 0.7
	sound.Parent = at or SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return Sfx
