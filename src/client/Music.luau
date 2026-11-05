-- La música de fondo (Config/Music): una canción en Puerto Eco, otra en cada isla y otra cuando
-- estás cerca de un jefe vivo (tapa la de la isla). Al cambiar, una baja poco a poco y la otra
-- sube, para que no se corte de golpe. Las que tienen número 0 no suenan.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Music = require(ReplicatedStorage.Shared.Config.Music)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)

local player = Players.LocalPlayer

local MusicClient = {}

-- Las islas que tienen su propia canción (además de Puerto y Jefe)
local ISLANDS = { "Selva" }
local BOSS_RANGE = 90 -- qué tan cerca del jefe empieza su música

local tracks: { [string]: Sound } = {}
local playing: string? = nil

local function track(key: string): Sound?
	local id = (Music :: any)[key]
	if typeof(id) ~= "number" or id == 0 then
		return nil
	end
	local sound = tracks[key]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "Musica_" .. key
		sound.SoundId = "rbxassetid://" .. id
		sound.Looped = true
		sound.Volume = 0
		sound.Parent = SoundService
		tracks[key] = sound
	end
	return sound
end

local function switch(key: string)
	if key == playing then
		return
	end
	local old = playing and tracks[playing]
	playing = key
	if old then
		local fade = TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 })
		fade.Completed:Connect(function()
			if old ~= tracks[playing] then
				old:Stop()
			end
		end)
		fade:Play()
	end
	local new = track(key)
	if new then
		if not new.IsPlaying then
			new:Play()
		end
		TweenService:Create(new, TweenInfo.new(1.5), { Volume = Music.volume }):Play()
	end
end

-- ¿Hay un jefe vivo cerca?
local function nearBoss(position: Vector3): boolean
	for _, enemy in CollectionService:GetTagged("Enemy") do
		if not enemy:IsA("Model") or not enemy:GetAttribute("Jefe") then
			continue
		end
		local root = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if
			root
			and humanoid
			and humanoid.Health > 0
			and (root.Position - position).Magnitude < BOSS_RANGE
		then
			return true
		end
	end
	return false
end

function MusicClient.Start()
	while true do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local key = "Puerto"
			for _, island in ISLANDS do
				if Zones.Inside((Zones :: any)[island], root.Position) then
					key = island
				end
			end
			if nearBoss(root.Position) then
				key = "Jefe"
			end
			switch(key)
		end
		task.wait(1)
	end
end

return MusicClient
