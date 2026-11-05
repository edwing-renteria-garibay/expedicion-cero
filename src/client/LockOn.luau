-- Fijar objetivo (F, o R3 en control): elige al enemigo más cercano que tengas enfrente y tu
-- personaje lo mira todo el tiempo, así tus golpes siempre van hacia él. Encima sale un rombo
-- amarillo. Vuelve a apretar F para soltarlo; se suelta solo si el enemigo muere o te alejas.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Staff = require(ReplicatedStorage.Shared.Config.Staff)
local Actions = require(script.Parent.Actions)

local player = Players.LocalPlayer

local LockOn = {}

-- Mientras sea true no voltea al personaje (por ejemplo, durante el giro del bastón)
LockOn.hold = false

local target: Model? = nil
local marker: BillboardGui? = nil

local function myRoot(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function rootOf(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function valid(model: Model): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return model:IsDescendantOf(workspace)
		and CollectionService:HasTag(model, "Enemy")
		and humanoid ~= nil
		and humanoid.Health > 0
		and rootOf(model) ~= nil
end

-- El mejor enemigo para fijar: cerca y enfrente de la cámara
local function best(): Model?
	local root = myRoot()
	if not root then
		return nil
	end
	local look = workspace.CurrentCamera.CFrame.LookVector
	local chosen, bestScore = nil, math.huge
	for _, enemy in CollectionService:GetTagged("Enemy") do
		if not enemy:IsA("Model") or not valid(enemy) then
			continue
		end
		local offset = (rootOf(enemy) :: BasePart).Position - root.Position
		local distance = offset.Magnitude
		if distance > Staff.lockRange then
			continue
		end
		local facing = if distance > 0.1 then offset.Unit:Dot(look) else 1
		if facing < -0.2 then
			continue -- está detrás de la cámara
		end
		local score = distance * (1.6 - facing)
		if score < bestScore then
			chosen, bestScore = enemy, score
		end
	end
	return chosen
end

local function setTarget(model: Model?)
	target = model
	if marker then
		marker.Adornee = if model then rootOf(model) else nil
		marker.Enabled = model ~= nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = model == nil
	end
end

-- La parte del enemigo fijado (o nil si no hay)
function LockOn.Target(): BasePart?
	if target and valid(target) then
		return rootOf(target)
	end
	return nil
end

local function makeMarker()
	local gui = Instance.new("BillboardGui")
	gui.Name = "Fijado"
	gui.Size = UDim2.fromOffset(40, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Enabled = false
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = "◆"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 60)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	marker = gui
end

function LockOn.Start()
	makeMarker()
	Actions.Bind("Fijar", function(_, state)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if target then
			setTarget(nil)
		else
			setTarget(best())
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonR3)

	RunService.RenderStepped:Connect(function()
		if not target then
			return
		end
		local root = myRoot()
		local aim = LockOn.Target()
		if not root or not aim or (aim.Position - root.Position).Magnitude > Staff.lockBreak then
			setTarget(nil)
			return
		end
		if LockOn.hold then
			return
		end
		local flat = Vector3.new(aim.Position.X, root.Position.Y, aim.Position.Z)
		if (flat - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, flat)
		end
	end)

	player.CharacterAdded:Connect(function()
		setTarget(nil)
	end)
end

return LockOn
