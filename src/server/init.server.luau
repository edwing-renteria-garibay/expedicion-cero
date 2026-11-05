-- Punto de entrada del servidor: arma Puerto Eco (la isla central), pone los muñecos del campo
-- de práctica y arranca el bastón (StaffService: golpes, rodar y el rayito de Chispa).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dummies = require(script.Dummies)
local World = require(script.World)
local StaffService = require(script.Services.StaffService)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

World.Build()
StaffService.Start()
Dummies.Start(World.dummySpots, function(dummy: Model)
	-- Al romper un muñeco, Chispa lo comenta (solo a quien le dio el último golpe)
	local userId = dummy:GetAttribute("UltimoGolpe")
	local player = userId and game:GetService("Players"):GetPlayerByUserId(userId)
	if player then
		fx:FireClient(player, "Say", "Muneco")
	end
end)
