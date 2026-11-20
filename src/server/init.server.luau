-- Punto de entrada del servidor: arma el Nexo (la isla central con sus portales), los muñecos
-- del campo de práctica, las máquinas del Óxido de la chatarrería, los cofres y la Selva Brumosa
-- (con su templo y su jefe); esconde las 7 llaves de la temporada; carga el progreso de cada
-- jugador (cristales, corazones, cofres, poderes y llaves) y arranca el bastón, los poderes, los puzzles, los portales, la tienda y el taller
-- (cristales), la tienda de Robux y las salas privadas.

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
local KeyService = require(script.Services.KeyService)
local PortalService = require(script.Services.PortalService)
local PowerService = require(script.Services.PowerService)
local RoomService = require(script.Services.RoomService)
local ShopService = require(script.Services.ShopService)
local StaffService = require(script.Services.StaffService)
local StoreService = require(script.Services.StoreService)
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
ShopService.Start()
StoreService.Start()
RoomService.Start()
-- Las llaves van al final: cada mundo ya registró sus escondites
KeyService.AddSpots("Nexo", World.keySpots)
KeyService.AddSpots("Selva", Selva.keySpots)
KeyService.Start()
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
	StoreService.CheckPasses(player) -- sus pases (VIP: un corazón más, así que va antes de Refresh)
	KeyService.Sync(player) -- si sus llaves son de otra temporada, se vacían
	HealthService.Refresh(player, true) -- sus corazones (si ya apareció antes de cargar)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
