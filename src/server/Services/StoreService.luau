-- Las compras con ROBUX (Config/Store).
--
-- Pases: Roblox recuerda quién los compró. Al entrar se le pregunta y, si lo tiene, se marca
-- con el atributo "Pass_x2" o "Pass_VIP". Lo demás del juego solo lee esos atributos
-- (DataService: cristales x2 y el corazón del VIP; Drones y StaffModel: el color dorado).
--
-- Productos (bolsas de cristales): Roblox llama a processReceipt y solo da por buena la compra
-- si devolvemos PurchaseGranted. Si no se pudo guardar devolvemos NotProcessedYet y Roblox lo
-- reintenta después, así nadie pierde sus Robux.
--
-- En Studio, lo que todavía no tiene id se puede "comprar" gratis con el botón Probar.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local Store = require(ReplicatedStorage.Shared.Config.Store)
local DataService = require(script.Parent.DataService)
local HealthService = require(script.Parent.HealthService)

local Remotes = ReplicatedStorage.Remotes
local storeRemote = Remotes.Store :: RemoteEvent

local MAX_RECEIPTS = 50

local StoreService = {}

local function grantPass(player: Player, key: string)
	player:SetAttribute("Pass_" .. key, true)
	if key == "VIP" then
		DataService.Publish(player) -- su corazón extra
		HealthService.Refresh(player, false)
	end
end

-- Pregunta a Roblox qué pases tiene el jugador
function StoreService.CheckPasses(player: Player)
	for _, pass in Store.passes do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				grantPass(player, pass.key)
			end
		end
	end
end

local function onPassPurchased(player: Player, passId: number, purchased: boolean)
	if not purchased then
		return
	end
	for _, pass in Store.passes do
		if pass.id ~= 0 and pass.id == passId then
			grantPass(player, pass.key)
			storeRemote:FireClient(player, "bought", pass.name)
		end
	end
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = player and DataService.Get(player)
	if not player or not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if table.find(profile.receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- ya se había dado
	end
	local product = nil
	for _, candidate in Store.products do
		if candidate.id ~= 0 and candidate.id == receipt.ProductId then
			product = candidate
		end
	end
	if not product then
		warn("[Tienda] Producto desconocido", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	DataService.AddCrystals(player, product.crystals, true)
	table.insert(profile.receipts, purchaseId)
	if #profile.receipts > MAX_RECEIPTS then
		table.remove(profile.receipts, 1)
	end
	if not DataService.SaveNow(player) then
		-- No se guardó: se deshace y Roblox lo reintenta después
		DataService.AddCrystals(player, -product.crystals, true)
		table.remove(profile.receipts)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	storeRemote:FireClient(player, "bought", product.name)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Botón Probar (solo en Studio): da el pase o el producto sin pagar
local function onTest(player: Player, key: any)
	if not Settings.testing or typeof(key) ~= "string" then
		return
	end
	for _, pass in Store.passes do
		if pass.key == key then
			grantPass(player, key)
			storeRemote:FireClient(player, "bought", pass.name .. " (prueba)")
		end
	end
	for _, product in Store.products do
		if product.key == key then
			DataService.AddCrystals(player, product.crystals, true)
			storeRemote:FireClient(player, "bought", product.name .. " (prueba)")
		end
	end
end

function StoreService.Start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassPurchased)
	MarketplaceService.ProcessReceipt = processReceipt
	storeRemote.OnServerEvent:Connect(function(player, action, key)
		if action == "test" then
			onTest(player, key)
		end
	end)
end

return StoreService
