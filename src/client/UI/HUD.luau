-- La pantalla de arriba a la izquierda: tus corazones y tus cristales.
--
-- Cada corazón es un ♥: rojo si está lleno, medio rojo si está a la mitad y gris si está
-- vacío. La barra de vida de Roblox se apaga. Los cristales salen debajo con un ◆ azul y
-- brincan un poco cada vez que recoges uno.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Settings = require(ReplicatedStorage.Shared.Config.Settings)

local player = Players.LocalPlayer

local HUD = {}

local RED = Color3.fromRGB(255, 70, 90)
local EMPTY = Color3.fromRGB(60, 60, 70)
local CYAN = Color3.fromRGB(110, 230, 255)
local SIZE = 30

local heartsFrame: Frame
local crystalLabel: TextLabel
local hearts: { { fill: Frame } } = {}

local function heartLabel(parent: Instance, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(SIZE, SIZE)
	label.Font = Enum.Font.GothamBlack
	label.Text = "♥"
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Parent = parent
	return label
end

-- Un corazón: el gris de fondo y encima el rojo, recortado según cuánto está lleno
local function makeHeart(index: number)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(SIZE, SIZE)
	holder.LayoutOrder = index
	holder.Parent = heartsFrame
	heartLabel(holder, EMPTY)
	local fill = Instance.new("Frame")
	fill.BackgroundTransparency = 1
	fill.ClipsDescendants = true
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = holder
	heartLabel(fill, RED)
	hearts[index] = { fill = fill }
end

local function refresh()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local count = player:GetAttribute("Corazones") or Settings.hearts.start
	local health = if humanoid then humanoid.Health else 0
	for i = #hearts + 1, count do
		makeHeart(i)
	end
	for i, heart in hearts do
		local holder = heart.fill.Parent :: Frame
		holder.Visible = i <= count
		-- Cuánto de este corazón está lleno (0, 0.5 o 1, redondeado a medios)
		local amount = math.clamp((health - (i - 1) * Settings.hearts.value) / Settings.hearts.value, 0, 1)
		amount = math.ceil(amount * 2) / 2
		heart.fill.Size = UDim2.fromScale(amount, 1)
	end
end

local function bump(label: GuiObject)
	label.Size = UDim2.fromOffset(150, 34)
	TweenService:Create(label, TweenInfo.new(0.2), { Size = UDim2.fromOffset(140, 28) }):Play()
end

function HUD.Start()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2
	gui.Parent = player:WaitForChild("PlayerGui")

	heartsFrame = Instance.new("Frame")
	heartsFrame.BackgroundTransparency = 1
	heartsFrame.Position = UDim2.fromOffset(16, 12)
	heartsFrame.Size = UDim2.fromOffset(6 * (SIZE + 2), 2 * (SIZE + 2))
	heartsFrame.Parent = gui
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(SIZE, SIZE)
	grid.CellPadding = UDim2.fromOffset(2, 2)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.FillDirectionMaxCells = 6
	grid.Parent = heartsFrame

	crystalLabel = Instance.new("TextLabel")
	crystalLabel.BackgroundTransparency = 1
	crystalLabel.Position = UDim2.fromOffset(16, 12 + 2 * (SIZE + 2) + 2)
	crystalLabel.Size = UDim2.fromOffset(140, 28)
	crystalLabel.Font = Enum.Font.FredokaOne
	crystalLabel.TextScaled = true
	crystalLabel.TextColor3 = CYAN
	crystalLabel.TextStrokeTransparency = 0.3
	crystalLabel.TextXAlignment = Enum.TextXAlignment.Left
	crystalLabel.Text = "◆ 0"
	crystalLabel.Parent = gui

	local function crystals()
		crystalLabel.Text = "◆ " .. tostring(player:GetAttribute("Cristales") or 0)
	end
	crystals()
	player:GetAttributeChangedSignal("Cristales"):Connect(function()
		crystals()
		bump(crystalLabel)
	end)
	RunService.Heartbeat:Connect(refresh)
end

return HUD
