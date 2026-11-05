-- Una lista chiquita abajo a la izquierda con los controles (en computadora y con control).
-- En celular no sale: ahí están los botones táctiles (UI/TouchButtons).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local Controls = {}

local KEYBOARD = {
	"Clic: golpear (3 seguidos = combo)",
	"Mantén clic y suelta: giro",
	"Shift: rodar (déjalo apretado para correr)",
	"F: fijar enemigo",
	"R: Chispa escanea",
	"E: Empuje (cuando lo tengas)",
	"B: tienda · T: taller de Chispa",
}

local GAMEPAD = {
	"R2: golpear (mantén para el giro)",
	"B / Círculo: rodar (déjalo apretado para correr)",
	"R3: fijar enemigo",
	"Y / Triángulo: Chispa escanea",
	"L2: Empuje (cuando lo tengas)",
}

function Controls.Start()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "Controles"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.new(0, 14, 1, -14)
	label.Size = UDim2.fromOffset(280, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
	label.BackgroundTransparency = 0.35
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = label
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	local function refresh()
		local gamepad = UserInputService:GetLastInputType().Name:match("^Gamepad") ~= nil
		label.Text = table.concat(if gamepad then GAMEPAD else KEYBOARD, "\n")
	end
	refresh()
	UserInputService.LastInputTypeChanged:Connect(refresh)
end

return Controls
