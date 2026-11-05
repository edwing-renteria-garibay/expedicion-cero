-- Los botones en celular y tableta, alrededor del botón de saltar de Roblox:
--
--          Escanear
--     Fijar        Rodar
--   Empuje  GOLPEAR      (Saltar)
--
-- Empuje solo sale cuando ya tienes ese poder.
--
-- GOLPEAR funciona igual que el clic: tócalo para golpear (varias veces = combo) y déjalo
-- apretado para cargar el giro; suelta para girar. Llaman a las mismas acciones que las teclas
-- (Actions), así todo se comporta igual. La cámara se mueve arrastrando el dedo en la pantalla.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Actions = require(script.Parent.Parent.Actions)
local LockOn = require(script.Parent.Parent.LockOn)
local PowersClient = require(script.Parent.Parent.Powers)

local player = Players.LocalPlayer

local TouchButtons = {}

local BUTTON = Color3.fromRGB(24, 36, 54)
local ATTACK = Color3.fromRGB(120, 78, 160)
local ACTIVE = Color3.fromRGB(255, 220, 60)
local TEXT = Color3.new(1, 1, 1)

-- Dónde va cada botón: su centro, medido desde el centro del botón de saltar, y su tamaño
local LAYOUT = {
	Attack = { x = -95, y = -10, size = 76 },
	Dodge = { x = -10, y = -95, size = 56 },
	Lock = { x = -170, y = -70, size = 50 },
	Scan = { x = -95, y = -140, size = 50 },
	Push = { x = -190, y = 5, size = 56 },
}

local function makeButton(parent: Instance, key: string, text: string, color: Color3): TextButton
	local spot = LAYOUT[key]
	local button = Instance.new("TextButton")
	button.Name = key
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromOffset(spot.x, spot.y)
	button.Size = UDim2.fromOffset(spot.size, spot.size)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.3
	button.AutoButtonColor = false
	button.Font = Enum.Font.FredokaOne
	button.Text = text
	button.TextColor3 = TEXT
	button.TextScaled = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = TEXT
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = button
	local padding = Instance.new("UIPadding")
	for _, side in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(padding :: any)[side] = UDim.new(0, 8)
	end
	padding.Parent = button
	local textSize = Instance.new("UITextSizeConstraint")
	textSize.MaxTextSize = if key == "Attack" then 16 else 13
	textSize.Parent = button
	return button
end

-- Llama a la acción con Begin al tocar y con End al soltar (aunque sueltes fuera del botón)
local function bindTouch(button: GuiButton, action: string)
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local normal = button.BackgroundTransparency
		button.BackgroundTransparency = normal - 0.25 -- se ve apretado
		Actions.Call(action, Enum.UserInputState.Begin, input)
		local connection
		connection = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			local state = input.UserInputState
			if state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				connection:Disconnect()
				button.BackgroundTransparency = normal
				Actions.Call(action, Enum.UserInputState.End, input)
			end
		end)
	end)
end

function TouchButtons.Start()
	if not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "TouchButtons"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Todos cuelgan de un punto en el centro del botón de saltar. Roblox lo pone en otro lugar
	-- (y más grande) en pantallas grandes, como las tabletas
	local cluster = Instance.new("Frame")
	cluster.BackgroundTransparency = 1
	cluster.Size = UDim2.fromOffset(0, 0)
	cluster.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Parent = cluster
	local function place()
		local size = gui.AbsoluteSize
		local small = math.min(size.X, size.Y) <= 500
		cluster.Position = if small then UDim2.new(1, -60, 1, -55) else UDim2.new(1, -110, 1, -150)
		scale.Scale = if small then 1 else 1.3
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()

	bindTouch(makeButton(cluster, "Attack", "GOLPEAR", ATTACK), "Atacar")
	bindTouch(makeButton(cluster, "Dodge", "Rodar", BUTTON), "Rodar")
	local lock = makeButton(cluster, "Lock", "Fijar", BUTTON)
	bindTouch(lock, "Fijar")
	bindTouch(makeButton(cluster, "Scan", "Escanear", BUTTON), "Escanear")
	local push = makeButton(cluster, "Push", "Empuje", Color3.fromRGB(60, 150, 190))
	bindTouch(push, "Empuje")

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		cluster.Visible = humanoid ~= nil and humanoid.Health > 0
		lock.TextColor3 = if LockOn.Target() then ACTIVE else TEXT
		push.Visible = player:GetAttribute("Empuje") == true
		push.BackgroundTransparency = if PowersClient.Ready() >= 1 then 0.3 else 0.7
	end)
end

return TouchButtons
