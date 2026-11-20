-- Acomoda la pantalla según el aparato:
--   * Los botones de los menús (tienda, taller, salas) van
--     juntos en una fila abajo a la izquierda (Layout.Dock). En celular no caben: se guardan en
--     un botón "MENÚ" arriba a la derecha que los muestra en una lista.
--   * En celular chico todo lo nuestro se ve un poco más pequeño (UIScale), para que no tape el
--     juego ni se amontone con los botones de Roblox.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Menus = require(script.Parent.Menus)

local player = Players.LocalPlayer

local Layout = {}

-- ¿Se juega con el dedo? (celular o tableta, sin teclado)
Layout.touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Qué tan chico se ve todo en celular (1 = normal)
local SMALL_SCALE = 0.7

-- Las pantallas de Roblox que no tocamos
-- (y las nuestras que se dibujan en puntos exactos de la pantalla: la mira y los botones táctiles)
local ROBLOX_GUIS =
	{ TouchGui = true, Chat = true, BubbleChat = true, Freecam = true, TouchButtons = true, Dano = true }

local dock: Frame? = nil
local menuButton: TextButton? = nil

local function corner(target: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = target
end

local function ensureDock(): Frame
	if dock then
		return dock
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "BotonesMenus"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	gui.Parent = player:WaitForChild("PlayerGui")
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.AutomaticSize = Enum.AutomaticSize.XY
	frame.Size = UDim2.new()
	frame.Parent = gui
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, if Layout.touch then 6 else 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = frame
	if Layout.touch then
		-- Arriba a la derecha: el botón MENÚ, y debajo la lista (escondida)
		local open = Instance.new("TextButton")
		open.AnchorPoint = Vector2.new(1, 0)
		open.Position = UDim2.new(1, -12, 0, 8)
		open.Size = UDim2.fromOffset(110, 40)
		open.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
		open.BackgroundTransparency = 0.15
		open.Font = Enum.Font.GothamBlack
		open.Text = "MENÚ"
		open.TextSize = 18
		open.TextColor3 = Color3.new(1, 1, 1)
		open.Parent = gui
		corner(open, 10)
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, -12, 0, 54)
		frame.Visible = false
		list.HorizontalAlignment = Enum.HorizontalAlignment.Right
		open.Activated:Connect(function()
			frame.Visible = not frame.Visible
			open.Text = if frame.Visible then "CERRAR" else "MENÚ"
		end)
		menuButton = open
	else
		frame.AnchorPoint = Vector2.new(0, 1)
		frame.Position = UDim2.new(0, 12, 1, -12)
		list.FillDirection = Enum.FillDirection.Horizontal
	end
	dock = frame
	return frame
end

-- En celular no hay teclado: quita la tecla del texto ("TIENDA (B)" -> "TIENDA")
local function withoutKey(text: string): string
	text = text:gsub("%s*·%s*%a+$", "")
	text = text:gsub("%s*%(%a%)$", "")
	return text
end

-- Pone un botón de menú en la fila (order: su lugar, de izquierda a derecha)
function Layout.Dock(button: GuiButton, order: number)
	local frame = ensureDock()
	button.LayoutOrder = order
	if Layout.touch and button:IsA("TextButton") then
		button.Size = UDim2.fromOffset(170, 40)
		button.TextSize = 16
		local function fix()
			local clean = withoutKey(button.Text)
			if clean ~= button.Text then
				button.Text = clean
			end
		end
		fix()
		button:GetPropertyChangedSignal("Text"):Connect(fix)
		-- Al tocar uno, la lista se cierra
		button.Activated:Connect(function()
			frame.Visible = false
			if menuButton then
				menuButton.Text = "MENÚ"
			end
		end)
	end
	button.Parent = frame
end

-- ¿Pantalla de celular? (una tableta grande, de lado, sí tiene espacio)
local function small(): boolean
	local camera = workspace.CurrentCamera
	if not Layout.touch or not camera then
		return false
	end
	local size = camera.ViewportSize
	return math.min(size.X, size.Y) < 900
end

local function fit(gui: Instance)
	if not gui:IsA("ScreenGui") or ROBLOX_GUIS[gui.Name] or gui:FindFirstChild("EscalaCelular") then
		return
	end
	local scale = Instance.new("UIScale")
	scale.Name = "EscalaCelular"
	scale.Scale = SMALL_SCALE
	scale.Parent = gui
end

-- Con control (PlayStation o Xbox): al abrir un menú se selecciona su X, para moverse por los
-- botones con el stick y elegir con Equis / A (Círculo / B deja de seleccionar)
local function gamepadMenus()
	local wasOpen = false
	RunService.Heartbeat:Connect(function()
		local open = Menus.FirstOpen()
		if open and not wasOpen and UserInputService:GetLastInputType().Name:match("^Gamepad") then
			if GuiService.SelectedObject == nil then
				GuiService.SelectedObject = open
			end
		end
		wasOpen = open ~= nil
	end)
end

function Layout.Start()
	ensureDock()
	gamepadMenus()
	if not small() then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")
	for _, gui in playerGui:GetChildren() do
		fit(gui)
	end
	playerGui.ChildAdded:Connect(fit)
end

return Layout
