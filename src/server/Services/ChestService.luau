-- Los cofres escondidos de Puerto Eco (los arma World con la etiqueta "Cofre").
--
-- Cada cofre tiene un aviso "Abrir" (mantén E, o tócalo en celular). Cada jugador puede abrir
-- cada cofre una vez (se guarda): da cristales y el cofre grande de la chatarrería, además,
-- un corazón más. Si ya lo abriste, Chispa te dice que está vacío.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local ChestService = {}

local function setup(chest: Instance)
	if not chest:IsA("Model") or not chest.PrimaryPart then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Abrir"
	prompt.ObjectText = "Cofre"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	-- Si ya lo abriste, tu pantalla esconde el aviso (client/Prompts)
	prompt:SetAttribute("OcultarSi", "Cofre_" .. tostring(chest:GetAttribute("Cofre")))
	prompt.Parent = chest.PrimaryPart
	prompt.Triggered:Connect(function(player)
		local name = chest:GetAttribute("Cofre")
		if typeof(name) ~= "string" then
			return
		end
		if not DataService.OpenChest(player, name) then
			fx:FireClient(player, "Say", "CofreVacio")
			return
		end
		local reward = chest:GetAttribute("Premio") or 0
		DataService.AddCrystals(player, reward)
		local heart = chest:GetAttribute("Corazon") == true and DataService.AddHeart(player)
		fx:FireClient(player, "Chest", (chest.PrimaryPart :: BasePart).Position, reward, heart)
	end)
end

function ChestService.Start()
	CollectionService:GetInstanceAddedSignal("Cofre"):Connect(setup)
	for _, chest in CollectionService:GetTagged("Cofre") do
		setup(chest)
	end
end

return ChestService
