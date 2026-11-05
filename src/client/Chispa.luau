-- Lo que dice y hace Chispa en tu pantalla:
--   * Habla: un globo abajo en el centro con su nombre y el texto escribiéndose letra por letra.
--     Si dice varias cosas seguidas, las forma en fila.
--   * Pistas: la primera vez que te acercas a un lugar con etiqueta "Pista" dice su frase.
--   * Escanear (R, o Triángulo / Y en control): marca a los enemigos cercanos con un brillo
--     que se ve a través de las paredes y te dice cuántos ve.
-- Las frases y los números están en Config/Drone.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Drone = require(ReplicatedStorage.Shared.Config.Drone)
local Actions = require(script.Parent.Actions)
local Drones = require(script.Parent.Drones)
local Sfx = require(script.Parent.Sfx)

local player = Players.LocalPlayer

local Chispa = {}

local EYE = Color3.fromRGB(110, 230, 255)
local SCAN = Color3.fromRGB(255, 170, 60)

local panel: Frame
local textLabel: TextLabel
local queue: { string } = {}
local talking = false
local said: { [string]: boolean } = {}
local lastScan = -math.huge

local function buildUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Chispa"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -110)
	panel.Size = UDim2.fromOffset(520, 74)
	panel.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = EYE
	stroke.Thickness = 2
	stroke.Parent = panel
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(520, 74)
	size.Parent = panel
	panel.Size = UDim2.new(0.9, 0, 0, 74)

	-- El "ojo" de Chispa a la izquierda
	local eye = Instance.new("Frame")
	eye.AnchorPoint = Vector2.new(0, 0.5)
	eye.Position = UDim2.new(0, 12, 0.5, 0)
	eye.Size = UDim2.fromOffset(46, 46)
	eye.BackgroundColor3 = Color3.fromRGB(240, 244, 250)
	eye.Parent = panel
	local eyeCorner = Instance.new("UICorner")
	eyeCorner.CornerRadius = UDim.new(0.5, 0)
	eyeCorner.Parent = eye
	local pupil = Instance.new("Frame")
	pupil.AnchorPoint = Vector2.new(0.5, 0.5)
	pupil.Position = UDim2.fromScale(0.5, 0.5)
	pupil.Size = UDim2.fromScale(0.45, 0.45)
	pupil.BackgroundColor3 = EYE
	pupil.Parent = eye
	local pupilCorner = Instance.new("UICorner")
	pupilCorner.CornerRadius = UDim.new(0.5, 0)
	pupilCorner.Parent = pupil

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(70, 6)
	name.Size = UDim2.new(1, -80, 0, 20)
	name.Font = Enum.Font.FredokaOne
	name.Text = string.upper(Drone.name)
	name.TextSize = 16
	name.TextColor3 = EYE
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = panel

	textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromOffset(70, 26)
	textLabel.Size = UDim2.new(1, -82, 1, -32)
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.Text = ""
	textLabel.TextSize = 15
	textLabel.TextWrapped = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Parent = panel
end

local function nextLine()
	if talking or #queue == 0 then
		return
	end
	talking = true
	local text = table.remove(queue, 1) :: string
	panel.Visible = true
	textLabel.Text = text
	textLabel.MaxVisibleGraphemes = 0
	Sfx.Play("chispa")
	Drones.Flash(player, Color3.new(1, 1, 1), 0.2)
	task.spawn(function()
		local length = utf8.len(text) or #text
		for i = 1, length do
			textLabel.MaxVisibleGraphemes = i
			task.wait(0.022)
		end
		textLabel.MaxVisibleGraphemes = -1
		task.wait(2 + length * 0.03)
		talking = false
		if #queue == 0 then
			panel.Visible = false
		end
		nextLine()
	end)
end

-- Chispa dice una frase de Config/Drone (por su nombre) o un texto. Lo que va después del
-- nombre se mete en la frase (por ejemplo, el %d de "Veo %d objetivos").
function Chispa.Say(key: string, ...: any)
	local line = Drone.lines[key] or key
	if select("#", ...) > 0 then
		line = string.format(line, ...)
	end
	-- No repite la misma frase si ya está en la fila
	for _, waiting in queue do
		if waiting == line then
			return
		end
	end
	table.insert(queue, line)
	nextLine()
end

local function scan(_, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return Enum.ContextActionResult.Pass
	end
	local now = os.clock()
	if now - lastScan < Drone.scan.cooldown then
		Chispa.Say("EscaneoEspera")
		return Enum.ContextActionResult.Sink
	end
	lastScan = now
	Sfx.Play("scan")
	Drones.Flash(player, SCAN, Drone.scan.duration)
	local found = 0
	for _, enemy in CollectionService:GetTagged("Enemy") do
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not enemy:IsA("Model") or not enemyRoot then
			continue
		end
		if (enemyRoot.Position - root.Position).Magnitude > Drone.scan.range then
			continue
		end
		found += 1
		local highlight = Instance.new("Highlight")
		highlight.FillColor = SCAN
		highlight.FillTransparency = 0.6
		highlight.OutlineColor = SCAN
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = enemy
		highlight.Parent = enemy
		task.delay(Drone.scan.duration, function()
			highlight:Destroy()
		end)
	end
	if found > 0 then
		Chispa.Say("EscaneoAlgo", found)
	else
		Chispa.Say("EscaneoNada")
	end
	return Enum.ContextActionResult.Sink
end

-- Revisa si estás cerca de una pista que Chispa todavía no ha dicho
local function checkHints()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	for _, spot in CollectionService:GetTagged("Pista") do
		local key = spot:GetAttribute("Pista")
		if not spot:IsA("BasePart") or typeof(key) ~= "string" or said[key] then
			continue
		end
		local radius = spot:GetAttribute("Radio") or 10
		local offset = spot.Position - root.Position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude <= radius then
			said[key] = true
			Chispa.Say(key)
		end
	end
end

function Chispa.Start()
	buildUI()
	Actions.Bind("Escanear", scan, false, Enum.KeyCode.R, Enum.KeyCode.ButtonY)
	-- Saludo al entrar
	task.delay(2, function()
		Chispa.Say("Hola")
	end)
	task.spawn(function()
		while true do
			task.wait(0.4)
			checkHints()
		end
	end)
end

return Chispa
