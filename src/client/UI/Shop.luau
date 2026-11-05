-- Los menús de la TIENDA (B) y del TALLER de Chispa (T). También se abren con el aviso de la
-- puerta de cada casa en Puerto Eco.
--
--   Tienda, pestaña Cristales: bastón reforzado y contenedores de corazón (Config/Shop)
--   Tienda, pestaña Robux:     pases y bolsas de cristales (Config/Store). Lo que aún no tiene
--                              id dice "Pronto" (en Studio, "Probar": te lo da gratis)
--   Taller:                    mejoras de Chispa (Config/Shop)
--
-- Las compras con cristales las revisa el servidor (ShopService); las de Robux, Roblox y
-- StoreService.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local Store = require(ReplicatedStorage.Shared.Config.Store)
local Actions = require(script.Parent.Parent.Actions)
local Layout = require(script.Parent.Parent.Layout)
local Menus = require(script.Parent.Parent.Menus)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local shopRemote = Remotes:WaitForChild("Shop") :: RemoteEvent
local storeRemote = Remotes:WaitForChild("Store") :: RemoteEvent
local player = Players.LocalPlayer

local ShopUI = {}

local BACKGROUND = Color3.fromRGB(24, 36, 54)
local ROW = Color3.fromRGB(36, 52, 76)
local CYAN = Color3.fromRGB(110, 230, 255)
local GREEN = Color3.fromRGB(70, 180, 100)
local ROBUX = Color3.fromRGB(60, 150, 90)
local GRAY = Color3.fromRGB(90, 96, 110)

local STUDIO = RunService:IsStudio()

type Panel = { frame: Frame, status: TextLabel, refresh: () -> () }
local panels: { [string]: Panel } = {}

local function corner(target: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = target
end

local function text(parent: Instance, value: string, size: number, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = font or Enum.Font.GothamMedium
	l.Text = value
	l.TextSize = size
	l.TextWrapped = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function crystals(): number
	return player:GetAttribute("Cristales") or 0
end

-- Un renglón: nombre, descripción, nivel y el botón de comprar
local function row(list: Instance, order: number, name: string, description: string): (TextLabel, TextButton)
	local frame = Instance.new("Frame")
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, 70)
	frame.BackgroundColor3 = ROW
	frame.Parent = list
	corner(frame, 10)
	local title = text(frame, name, 17, Enum.Font.FredokaOne)
	title.Position = UDim2.fromOffset(12, 6)
	title.Size = UDim2.new(1, -140, 0, 22)
	local info = text(frame, description, 13)
	info.Position = UDim2.fromOffset(12, 28)
	info.Size = UDim2.new(1, -140, 0, 36)
	info.TextColor3 = Color3.fromRGB(200, 210, 225)
	info.TextYAlignment = Enum.TextYAlignment.Top
	local level = text(frame, "", 12, Enum.Font.GothamBold)
	level.AnchorPoint = Vector2.new(1, 0)
	level.Position = UDim2.new(1, -12, 0, 6)
	level.Size = UDim2.fromOffset(116, 16)
	level.TextXAlignment = Enum.TextXAlignment.Right
	level.TextColor3 = CYAN
	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 1)
	buy.Position = UDim2.new(1, -10, 1, -8)
	buy.Size = UDim2.fromOffset(116, 34)
	buy.Font = Enum.Font.FredokaOne
	buy.TextSize = 16
	buy.TextColor3 = Color3.new(1, 1, 1)
	buy.Parent = frame
	corner(buy, 8)
	return level, buy
end

-- Un panel con título, cristales, una o dos pestañas y la X para cerrar
local function makePanel(
	gui: ScreenGui,
	kind: string,
	title: string,
	tabs: { string }
): (Panel, { [string]: Frame })
	local frame = Instance.new("Frame")
	frame.Name = kind
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.new(0.9, 0, 0, 440)
	frame.BackgroundColor3 = BACKGROUND
	frame.Visible = false
	frame.Parent = gui
	corner(frame, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = CYAN
	stroke.Thickness = 2
	stroke.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, 440)
	limit.Parent = frame

	local heading = text(frame, title, 24, Enum.Font.FredokaOne)
	heading.Position = UDim2.fromOffset(16, 10)
	heading.Size = UDim2.new(1, -60, 0, 30)
	local money = text(frame, "", 18, Enum.Font.FredokaOne)
	money.Position = UDim2.fromOffset(16, 40)
	money.Size = UDim2.new(1, -32, 0, 22)
	money.TextColor3 = CYAN

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(36, 36)
	close.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
	close.Font = Enum.Font.FredokaOne
	close.Text = "X"
	close.TextSize = 20
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Parent = frame
	corner(close, 8)
	Menus.Register(close)
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	-- Pestañas
	local pages: { [string]: Frame } = {}
	local buttons: { [string]: TextButton } = {}
	local function show(name: string)
		for key, page in pages do
			page.Visible = key == name
			buttons[key].BackgroundColor3 = if key == name then CYAN else GRAY
			buttons[key].TextColor3 = if key == name then BACKGROUND else Color3.new(1, 1, 1)
		end
	end
	for i, name in tabs do
		local tab = Instance.new("TextButton")
		tab.Position = UDim2.new((i - 1) / #tabs, 16 - (i - 1) * 8, 0, 70)
		tab.Size = UDim2.new(1 / #tabs, -20 + (if #tabs == 1 then 4 else 0), 0, 30)
		tab.Font = Enum.Font.FredokaOne
		tab.Text = name
		tab.TextSize = 16
		tab.Parent = frame
		tab.Visible = #tabs > 1
		corner(tab, 8)
		buttons[name] = tab
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Position = UDim2.fromOffset(12, if #tabs > 1 then 108 else 72)
		page.Size = UDim2.new(1, -24, 1, if #tabs > 1 then -146 else -110)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 6
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new()
		page.Parent = frame
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 8)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = page
		pages[name] = page :: any
		tab.Activated:Connect(function()
			show(name)
		end)
	end
	show(tabs[1])

	local status = text(frame, "", 14, Enum.Font.GothamBold)
	status.AnchorPoint = Vector2.new(0, 1)
	status.Position = UDim2.new(0, 16, 1, -10)
	status.Size = UDim2.new(1, -32, 0, 24)
	status.TextXAlignment = Enum.TextXAlignment.Center

	local panel: Panel = {
		frame = frame,
		status = status,
		refresh = function()
			money.Text = "◆ " .. crystals() .. " cristales"
		end,
	}
	return panel, pages
end

-- Llena una página con las mejoras de un lugar (Tienda o Taller)
local function upgrades(page: Frame, place: string): () -> ()
	local refreshers = {}
	for order, key in Shop.order[place] do
		local item = Shop.items[key]
		local level, buy = row(page, order, item.name, item.description)
		buy.Activated:Connect(function()
			shopRemote:FireServer("buy", key)
		end)
		table.insert(refreshers, function()
			local current = player:GetAttribute("Mejora_" .. key) or 0
			local price = item.prices[current + 1]
			level.Text = string.format("Nivel %d / %d", current, #item.prices)
			if price then
				buy.Text = "◆ " .. price
				buy.BackgroundColor3 = if crystals() >= price then GREEN else GRAY
				buy.AutoButtonColor = true
			else
				buy.Text = "MÁXIMO"
				buy.BackgroundColor3 = GRAY
				buy.AutoButtonColor = false
			end
		end)
	end
	return function()
		for _, refresh in refreshers do
			refresh()
		end
	end
end

-- Llena la pestaña de Robux
local function robux(page: Frame): () -> ()
	local refreshers = {}
	local order = 0
	local function add(entry, isPass: boolean)
		order += 1
		local level, buy = row(page, order, entry.name, entry.description)
		buy.Activated:Connect(function()
			if entry.id ~= 0 then
				if isPass then
					MarketplaceService:PromptGamePassPurchase(player, entry.id)
				else
					MarketplaceService:PromptProductPurchase(player, entry.id)
				end
			elseif STUDIO then
				storeRemote:FireServer("test", entry.key)
			end
		end)
		table.insert(refreshers, function()
			local owned = isPass and player:GetAttribute("Pass_" .. entry.key) == true
			level.Text = if isPass then "Pase" else "Producto"
			if owned then
				buy.Text = "LO TIENES"
				buy.BackgroundColor3 = GRAY
			elseif entry.id ~= 0 then
				buy.Text = "R$ " .. entry.price
				buy.BackgroundColor3 = ROBUX
			else
				buy.Text = if STUDIO then "Probar" else "Pronto"
				buy.BackgroundColor3 = if STUDIO then ROBUX else GRAY
			end
		end)
	end
	for _, pass in Store.passes do
		add(pass, true)
	end
	for _, product in Store.products do
		add(product, false)
	end
	return function()
		for _, refresh in refreshers do
			refresh()
		end
	end
end

local function toggle(kind: string, open: boolean?)
	for key, panel in panels do
		if key == kind then
			panel.frame.Visible = if open == nil then not panel.frame.Visible else open
			panel.status.Text = ""
			panel.refresh()
		else
			panel.frame.Visible = false
		end
	end
end

local function dockButton(label: string, color: Color3, order: number, kind: string)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(130, 44)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.FredokaOne
	b.Text = label
	b.TextSize = 17
	b.TextColor3 = Color3.new(1, 1, 1)
	corner(b, 10)
	Layout.Dock(b, order)
	b.Activated:Connect(function()
		toggle(kind)
	end)
end

function ShopUI.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Tienda"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = player:WaitForChild("PlayerGui")

	local store, storePages = makePanel(gui, "Tienda", "Tienda", { "Cristales", "Robux" })
	local refreshUpgrades = upgrades(storePages.Cristales, "Tienda")
	local refreshRobux = robux(storePages.Robux)
	local baseRefresh = store.refresh
	store.refresh = function()
		baseRefresh()
		refreshUpgrades()
		refreshRobux()
	end
	panels.Tienda = store

	local workshop, workshopPages = makePanel(gui, "Taller", "Taller de Chispa", { "Mejoras" })
	local refreshWorkshop = upgrades(workshopPages.Mejoras, "Taller")
	local workshopBase = workshop.refresh
	workshop.refresh = function()
		workshopBase()
		refreshWorkshop()
	end
	panels.Taller = workshop

	dockButton("TIENDA (B)", Color3.fromRGB(200, 80, 60), 1, "Tienda")
	dockButton("TALLER (T)", Color3.fromRGB(60, 120, 200), 2, "Taller")
	Actions.Bind("AbrirTienda", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggle("Tienda")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.B)
	Actions.Bind("AbrirTaller", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggle("Taller")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.T)

	-- Los avisos de las puertas de la tienda y el taller (atributo AbreMenu)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local kind = prompt:GetAttribute("AbreMenu")
		if typeof(kind) == "string" and panels[kind] then
			toggle(kind, true)
		end
	end)

	-- Al cambiar cristales, mejoras o pases, todo se actualiza
	player.AttributeChanged:Connect(function()
		for _, panel in panels do
			if panel.frame.Visible then
				panel.refresh()
			end
		end
	end)

	local function result(kind: string, message: string)
		for _, panel in panels do
			if panel.frame.Visible then
				panel.status.TextColor3 = if kind == "bought"
					then Color3.fromRGB(120, 255, 160)
					else Color3.fromRGB(255, 130, 110)
				panel.status.Text = if kind == "bought" then "¡Listo! " .. message else message
			end
		end
	end
	shopRemote.OnClientEvent:Connect(result)
	storeRemote.OnClientEvent:Connect(result)
end

return ShopUI
