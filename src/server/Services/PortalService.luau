-- Los portales: piezas con la etiqueta "Portal" y el atributo Destino (por ejemplo "Selva" o
-- "Puerto"). Al tocar una, el personaje aparece en ese destino.
--
-- Los destinos los registra cada zona con PortalService.Add(nombre, lugar).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local PortalService = {}

local destinations: { [string]: CFrame } = {}
local lastUse: { [Player]: number } = {}

function PortalService.Add(name: string, place: CFrame)
	destinations[name] = place
end

local function setup(portal: Instance)
	if not portal:IsA("BasePart") then
		return
	end
	portal.CanTouch = true
	portal.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local name = portal:GetAttribute("Destino")
		local place = typeof(name) == "string" and destinations[name]
		if not player or not character or not place then
			return
		end
		local now = os.clock()
		if now - (lastUse[player] or 0) < 2 then
			return
		end
		lastUse[player] = now
		fx:FireClient(player, "Travel", name)
		character:PivotTo(place)
	end)
end

function PortalService.Start()
	CollectionService:GetInstanceAddedSignal("Portal"):Connect(setup)
	for _, portal in CollectionService:GetTagged("Portal") do
		setup(portal)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return PortalService
