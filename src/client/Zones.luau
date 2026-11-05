-- Cambia cómo se ve el cielo al entrar a una isla (Config/Zones): en la Selva Brumosa todo se
-- llena de niebla verde. Al salir, regresa como en Puerto Eco.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Zones = require(ReplicatedStorage.Shared.Config.Zones)

local player = Players.LocalPlayer

local ZonesClient = {}

local ISLANDS = { "Selva" }

function ZonesClient.Start()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		return
	end
	local normal = {
		Density = atmosphere.Density,
		Haze = atmosphere.Haze,
		Color = atmosphere.Color,
		Decay = atmosphere.Decay,
	}
	local current: string? = nil
	while true do
		task.wait(0.5)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local inside: string? = nil
		for _, key in ISLANDS do
			if Zones.Inside((Zones :: any)[key], root.Position) then
				inside = key
			end
		end
		if inside ~= current then
			current = inside
			local goal = if inside then (Zones :: any)[inside].fog else normal
			TweenService:Create(atmosphere, TweenInfo.new(1.5), goal):Play()
		end
	end
end

return ZonesClient
