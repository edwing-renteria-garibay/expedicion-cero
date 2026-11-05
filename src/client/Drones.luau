-- Chispa, el dron compañero: una esfera con un ojo de luz y dos aletas que flota junto al
-- hombro de cada jugador.
--
-- Cada pantalla dibuja los drones de todos los jugadores (no existen en el servidor), así se
-- mueven suaves para todos. El servidor solo avisa cuándo un dron dispara su rayito (Fx "Zap").

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Drones = {}

local BODY = Color3.fromRGB(240, 244, 250)
local BAND = Color3.fromRGB(60, 190, 210)
local EYE = Color3.fromRGB(110, 230, 255)
local FIN = Color3.fromRGB(250, 170, 60)
local GOLD = Color3.fromRGB(255, 205, 70) -- con el pase VIP, Chispa es dorado

-- Dónde flota: a la derecha, arriba y un poco atrás del personaje
local OFFSET = Vector3.new(2.8, 2.6, 1.6)
local FOLLOW = 7 -- qué tan rápido te sigue (más = más pegado)

type Drone = {
	model: Model,
	eye: BasePart,
	position: Vector3,
	look: Vector3,
}

local drones: { [Player]: Drone } = {}
local folder: Folder

local function piece(
	model: Model,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = model
	return p
end

local function build(owner: Player): Drone
	local model = Instance.new("Model")
	model.Name = "Chispa_" .. owner.Name
	local body = piece(model, "Cuerpo", Vector3.one * 1.5, BODY, nil, Enum.PartType.Ball)
	model.PrimaryPart = body
	local band = piece(model, "Banda", Vector3.new(0.35, 1.6, 1.6), BAND, nil, Enum.PartType.Cylinder)
	band.CFrame = CFrame.Angles(0, 0, math.rad(90))
	local eye = piece(model, "Ojo", Vector3.one * 0.6, EYE, Enum.Material.Neon, Enum.PartType.Ball)
	eye.CFrame = CFrame.new(0, 0.1, -0.62)
	for _, side in { -1, 1 } do
		local fin = piece(model, "Aleta", Vector3.new(0.15, 0.6, 0.9), FIN)
		fin.CFrame = CFrame.new(side * 0.85, 0.15, 0.1) * CFrame.Angles(0, 0, math.rad(25 * side))
	end
	local light = Instance.new("PointLight")
	light.Color = EYE
	light.Range = 6
	light.Brightness = 0.8
	light.Parent = eye
	if owner == Players.LocalPlayer then
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(80, 20)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0)
		gui.MaxDistance = 40
		gui.Parent = body
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.Text = "Chispa"
		label.TextScaled = true
		label.TextColor3 = EYE
		label.TextStrokeTransparency = 0.4
		label.Parent = gui
	end
	-- Con el pase VIP la banda y las aletas son doradas (también si lo compra jugando)
	local function paint()
		local vip = owner:GetAttribute("Pass_VIP") == true
		band.Color = if vip then GOLD else BAND
		band.Material = if vip then Enum.Material.Glass else Enum.Material.SmoothPlastic
		for _, child in model:GetChildren() do
			if child.Name == "Aleta" and child:IsA("BasePart") then
				child.Color = if vip then GOLD else FIN
			end
		end
	end
	paint()
	local connection = owner:GetAttributeChangedSignal("Pass_VIP"):Connect(paint)
	model.Destroying:Connect(function()
		connection:Disconnect()
	end)
	-- Todas las piezas se mueven juntas desde el cuerpo (que queda en el origen)
	model:PivotTo(CFrame.new())
	model.Parent = folder
	return { model = model, eye = eye, position = Vector3.zero, look = -Vector3.zAxis }
end

local function remove(owner: Player)
	local drone = drones[owner]
	if drone then
		drone.model:Destroy()
		drones[owner] = nil
	end
end

-- Dónde está el ojo del dron de este jugador (para el rayito)
function Drones.Eye(owner: Player): Vector3?
	local drone = drones[owner]
	return drone and drone.eye.Position
end

-- Cambia el color del ojo un momento (escaneo, rayito)
function Drones.Flash(owner: Player, color: Color3, seconds: number)
	local drone = drones[owner]
	if not drone then
		return
	end
	drone.eye.Color = color
	task.delay(seconds, function()
		if drone.eye.Parent then
			drone.eye.Color = EYE
		end
	end)
end

-- El rayito de Chispa hacia un enemigo
function Drones.Zap(owner: Player, target: Vector3)
	local from = Drones.Eye(owner)
	if not from then
		return
	end
	local distance = (target - from).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = EYE
	beam.Size = Vector3.new(0.25, 0.25, distance)
	beam.CFrame = CFrame.lookAt(from, target) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = folder
	Drones.Flash(owner, Color3.new(1, 1, 1), 0.15)
	task.delay(0.12, function()
		beam:Destroy()
	end)
end

function Drones.Start()
	folder = Instance.new("Folder")
	folder.Name = "Drones"
	folder.Parent = workspace

	Players.PlayerRemoving:Connect(remove)

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		for _, owner in Players:GetPlayers() do
			local character = owner.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				remove(owner)
				continue
			end
			local drone = drones[owner]
			local goal = root.CFrame:PointToWorldSpace(OFFSET) + Vector3.new(0, math.sin(t * 2.2) * 0.3, 0)
			if not drone then
				drone = build(owner)
				drone.position = goal
				drones[owner] = drone
			end
			-- Si quedó muy lejos (reapareciste, te teletransportaste) llega de golpe
			if (goal - drone.position).Magnitude > 60 then
				drone.position = goal
			end
			drone.position = drone.position:Lerp(goal, 1 - math.exp(-dt * FOLLOW))
			local wanted = root.CFrame.LookVector
			drone.look = drone.look:Lerp(wanted, 1 - math.exp(-dt * 5))
			local flat = Vector3.new(drone.look.X, 0, drone.look.Z)
			if flat.Magnitude < 0.05 then
				flat = -Vector3.zAxis
			end
			-- Se inclina un poco al moverse
			local tilt = math.clamp((goal - drone.position).Magnitude * 0.15, 0, 0.4)
			drone.model:PivotTo(
				CFrame.lookAt(drone.position, drone.position + flat)
					* CFrame.Angles(-tilt, 0, math.sin(t * 1.3) * 0.08)
			)
		end
	end)
end

return Drones
