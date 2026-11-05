-- La barra de vida del jefe, arriba en medio, cuando estás cerca de uno (modelos con el
-- atributo "Jefe", que es su nombre). Dice "BLINDADO" mientras tiene la armadura puesta.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local BossBar = {}

local RANGE = 90

function BossBar.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Jefe"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 14)
	frame.Size = UDim2.new(0.5, 0, 0, 46)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = gui
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(520, 46)
	size.Parent = frame

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 20)
	name.Font = Enum.Font.FredokaOne
	name.TextSize = 18
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.3
	name.Parent = frame

	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(0, 24)
	back.Size = UDim2.new(1, 0, 0, 16)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	back.BorderSizePixel = 0
	back.Parent = frame
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 120, 60)
	fill.BorderSizePixel = 0
	fill.Parent = back
	for _, f in { back, fill } do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = f
	end

	RunService.Heartbeat:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local boss: Model? = nil
		if root then
			for _, enemy in CollectionService:GetTagged("Enemy") do
				local bossRoot = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
				if
					enemy:IsA("Model")
					and enemy:GetAttribute("Jefe")
					and bossRoot
					and (bossRoot.Position - root.Position).Magnitude < RANGE
				then
					boss = enemy
				end
			end
		end
		local humanoid = boss and boss:FindFirstChildOfClass("Humanoid")
		frame.Visible = humanoid ~= nil and humanoid.Health > 0
		if boss and humanoid then
			local armored = boss:GetAttribute("Blindado")
			name.Text = tostring(boss:GetAttribute("Jefe")) .. if armored then "  ·  BLINDADO" else ""
			fill.Size = UDim2.fromScale(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 1)
			fill.BackgroundColor3 = if armored
				then Color3.fromRGB(150, 156, 170)
				else Color3.fromRGB(255, 120, 60)
		end
	end)
end

return BossBar
