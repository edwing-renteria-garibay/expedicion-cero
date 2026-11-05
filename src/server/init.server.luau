-- Punto de entrada del servidor: arma Puerto Eco (la isla central), los muñecos del campo de
-- práctica, las máquinas del Óxido de la chatarrería, los cofres y la Selva Brumosa (con su
-- templo y su jefe); carga el progreso de cada jugador (cristales, corazones, cofres, poderes y
-- núcleos) y arranca el bastón, los poderes, los puzzles y los portales.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dummies = require(script.Dummies)
local Pickups = require(script.Pickups)
local Puzzles = require(script.Puzzles)
local World = require(script.World)
local ChestService = require(script.Services.ChestService)
local DataService = require(script.Services.DataService)
local EnemyService = require(script.Services.EnemyService)
local HealthService = require(script.Services.HealthService)
local PortalService = require(script.Services.PortalService)
local PowerService = require(script.Services.PowerService)
local StaffService = require(script.Services.StaffService)
local Selva = require(script.Zones.Selva)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

World.Build()
DataService.Start()
HealthService.Start()
Pickups.Start()
StaffService.Start()
ChestService.Start()
EnemyService.Start(World.enemySpots)
PowerService.Start()
Puzzles.Start()
Selva.Build()
PortalService.Add("Selva", Selva.arrival)
PortalService.Add("Puerto", World.arrival)
PortalService.Start()
Dummies.Start(World.dummySpots, function(dummy: Model)
	-- Al romper un muñeco, Chispa lo comenta (solo a quien le dio el último golpe)
	local userId = dummy:GetAttribute("UltimoGolpe")
	local player = userId and Players:GetPlayerByUserId(userId)
	if player then
		fx:FireClient(player, "Say", "Muneco")
	end
end)

local function onPlayerAdded(player: Player)
	DataService.Load(player)
	HealthService.Refresh(player, true) -- sus corazones (si ya apareció antes de cargar)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
