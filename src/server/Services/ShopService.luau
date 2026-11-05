-- Las compras con CRISTALES de la tienda y del taller de Chispa (Config/Shop).
--
-- El menú del cliente manda ("buy", "Baston") por el remote Shop. Aquí se revisa que la mejora
-- exista, que no esté al máximo y que te alcancen los cristales; si sí, se cobra y se sube el
-- nivel (DataService.Upgrade). Las mejoras se usan donde toca: StaffService (bastón y rayo),
-- Pickups (imán) y Chispa en el cliente (escáner).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local DataService = require(script.Parent.DataService)

local Remotes = ReplicatedStorage.Remotes
local shopRemote = Remotes.Shop :: RemoteEvent

local ShopService = {}

local function buy(player: Player, key: any)
	local item = typeof(key) == "string" and Shop.items[key]
	local profile = DataService.Get(player)
	if not item or not profile then
		return
	end
	local level = profile.upgrades[key] or 0
	local price = item.prices[level + 1]
	if not price then
		shopRemote:FireClient(player, "error", "Ya está al máximo.")
		return
	end
	if key == "Corazon" and profile.hearts >= Settings.hearts.max then
		shopRemote:FireClient(player, "error", "Ya tienes todos los corazones.")
		return
	end
	if not DataService.Spend(player, price) then
		shopRemote:FireClient(
			player,
			"error",
			string.format("Te faltan %d cristales.", price - profile.crystals)
		)
		return
	end
	DataService.Upgrade(player, key)
	if key == "Corazon" then
		DataService.AddHeart(player)
	end
	shopRemote:FireClient(player, "bought", item.name)
end

function ShopService.Start()
	shopRemote.OnServerEvent:Connect(function(player, action, key)
		if action == "buy" then
			buy(player, key)
		end
	end)
end

return ShopService
