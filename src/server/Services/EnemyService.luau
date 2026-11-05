-- Las máquinas del Óxido (los números en Config/Enemies):
--   * Rastreador: chico y rápido. Te persigue y te muerde.
--   * Escudero: grande, con escudo al frente. De frente, tus golpes normales rebotan.
--   * Torreta: no camina; gira y te dispara bolas de óxido lentas.
--
-- Todas avisan antes de atacar: el ojo se pone ROJO durante "windup" segundos. Ese es el
-- momento de rodar (Shift). Si un golpe del bastón les pega, se quedan quietas un instante.
-- Al romperse sueltan cristales (y a veces un corazón) y vuelven a salir después de un rato.
--
-- Cada máquina tiene la etiqueta "Enemy", así el bastón, fijar y el escaneo de Chispa la ven.
-- Las caminantes usan un Humanoid sin esqueleto: el servidor las mueve con MoveTo.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Enemies = require(ReplicatedStorage.Shared.Config.Enemies)
local HealthService = require(script.Parent.HealthService)
local Pickups = require(script.Parent.Parent.Pickups)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local EnemyService = {}

local EYE = Color3.fromRGB(255, 200, 80)
local ANGRY = Color3.fromRGB(255, 40, 40)
local LEASH = 70 -- no se alejan más que esto de donde salen
local TICK = 0.15

local folder: Folder

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function piece(model: Model, name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.CorrodedMetal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Pega una pieza al centro de la máquina, en esta posición relativa
local function attach(root: BasePart, p: BasePart, offset: CFrame)
	p.CFrame = root.CFrame * offset
	p.Massless = true
	p.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
end

-- Arma una caminante (Rastreador o Escudero): cuerpo, patas, ojo y, si toca, escudo
local function buildWalker(kind: string, info, position: Vector3): Model
	local s = info.size
	local model = Instance.new("Model")
	model.Name = kind
	local root = piece(model, "HumanoidRootPart", Vector3.new(2.6, 2, 3) * s, info.color)
	root.CFrame = CFrame.new(position + Vector3.new(0, 2 * s, 0))
	model.PrimaryPart = root
	-- Lomo y "boca"
	attach(
		root,
		piece(model, "Lomo", Vector3.new(2, 0.8, 2.4) * s, Color3.fromRGB(120, 70, 50)),
		CFrame.new(0, 1.2 * s, 0.2 * s)
	)
	attach(
		root,
		piece(
			model,
			"Mandibula",
			Vector3.new(2, 0.5, 0.8) * s,
			Color3.fromRGB(90, 90, 96),
			Enum.Material.Metal
		),
		CFrame.new(0, -0.6 * s, -1.6 * s)
	)
	-- Cuatro patas
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			attach(
				root,
				piece(
					model,
					"Pata",
					Vector3.new(0.5, 1.6, 0.5) * s,
					Color3.fromRGB(80, 80, 86),
					Enum.Material.Metal
				),
				CFrame.new(x * 1.2 * s, -1.4 * s, z * 1.1 * s) * CFrame.Angles(0, 0, math.rad(15 * x))
			)
		end
	end
	local eye = piece(model, "Ojo", Vector3.new(0.9, 0.6, 0.3) * s, EYE, Enum.Material.Neon)
	attach(root, eye, CFrame.new(0, 0.3 * s, -1.55 * s))
	if info.shield then
		local shield = piece(
			model,
			"Escudo",
			Vector3.new(3.6, 3, 0.4) * s,
			Color3.fromRGB(110, 116, 126),
			Enum.Material.DiamondPlate
		)
		attach(root, shield, CFrame.new(0, 0.2 * s, -2.1 * s))
		model:SetAttribute("Escudo", true)
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = info.health
	humanoid.Health = info.health
	humanoid.WalkSpeed = info.speed
	humanoid.HipHeight = 1.4 * s
	-- Que no se caigan de lado con los golpes
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model
	return model
end

-- Arma una torreta: base fija y una cabeza que gira con un cañón
local function buildTurret(kind: string, info, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = kind
	local root = piece(model, "HumanoidRootPart", Vector3.new(3.4, 3, 3.4), info.color)
	root.CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0))
	root.Anchored = true
	model.PrimaryPart = root
	local head = piece(model, "Cabeza", Vector3.new(2.6, 2, 2.6), Color3.fromRGB(176, 92, 48))
	head.Anchored = true
	head.CFrame = root.CFrame * CFrame.new(0, 2.5, 0)
	local barrel =
		piece(model, "Canon", Vector3.new(0.7, 0.7, 2.4), Color3.fromRGB(80, 80, 86), Enum.Material.Metal)
	barrel.Anchored = true
	local eye = piece(model, "Ojo", Vector3.new(0.8, 0.5, 0.2), EYE, Enum.Material.Neon)
	eye.Anchored = true
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = info.health
	humanoid.Health = info.health
	humanoid.WalkSpeed = 0
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model
	return model
end

-- Gira la cabeza de la torreta hacia una dirección (el cañón y el ojo la siguen)
local function aimTurret(model: Model, direction: Vector3)
	local head = model:FindFirstChild("Cabeza") :: BasePart?
	local barrel = model:FindFirstChild("Canon") :: BasePart?
	local eye = model:FindFirstChild("Ojo") :: BasePart?
	if not head or not barrel or not eye then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	local frame = CFrame.lookAt(head.Position, head.Position + flat)
	head.CFrame = frame
	barrel.CFrame = frame * CFrame.new(0, 0, -2)
	eye.CFrame = frame * CFrame.new(0, 0.5, -1.35)
end

-- La barra de vida sobre la máquina (solo se ve si le pegaste)
local function healthBar(model: Model, humanoid: Humanoid)
	local root = model.PrimaryPart :: BasePart
	local gui = Instance.new("BillboardGui")
	gui.Name = "Vida"
	gui.Size = UDim2.fromOffset(80, 10)
	gui.StudsOffsetWorldSpace = Vector3.new(0, root.Size.Y + 2.5, 0)
	gui.MaxDistance = 80
	gui.Enabled = false
	gui.Parent = root
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	back.BorderSizePixel = 0
	back.Parent = gui
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
	humanoid.HealthChanged:Connect(function(health)
		gui.Enabled = health < humanoid.MaxHealth
		fill.Size = UDim2.fromScale(math.clamp(health / humanoid.MaxHealth, 0, 1), 1)
	end)
end

-- El jugador vivo más cercano dentro de "range" que se pueda ver
local function findTarget(from: Vector3, range: number, model: Model): (Player?, BasePart?)
	local best, bestRoot, bestDistance = nil, nil, range
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not character or not humanoid or humanoid.Health <= 0 or not root then
			continue
		end
		local distance = (root.Position - from).Magnitude
		if distance >= bestDistance then
			continue
		end
		rayParams.FilterDescendantsInstances = { model, character, folder }
		local blocked = workspace:Raycast(from, root.Position - from, rayParams)
		if not blocked or blocked.Instance:IsDescendantOf(workspace.Terrain) and distance < 12 then
			best, bestRoot, bestDistance = player, root, distance
		end
	end
	return best, bestRoot
end

local function setEye(model: Model, color: Color3)
	local eye = model:FindFirstChild("Ojo") :: BasePart?
	if eye then
		eye.Color = color
	end
end

local function stunned(model: Model): boolean
	local untilTime = model:GetAttribute("Aturdido")
	return typeof(untilTime) == "number" and os.clock() < untilTime
end

-- Una bola de óxido lenta: avanza en línea recta y le pega al primer jugador que toque
local function fireBall(owner: Model, from: Vector3, direction: Vector3, info)
	local ball = Instance.new("Part")
	ball.Name = "BolaOxido"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * 1.4
	ball.Color = Color3.fromRGB(230, 110, 40)
	ball.Material = Enum.Material.Neon
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Position = from
	ball.Parent = folder
	local light = Instance.new("PointLight")
	light.Color = ball.Color
	light.Range = 8
	light.Parent = ball
	local traveled = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local move = direction * info.projectileSpeed * dt
		rayParams.FilterDescendantsInstances = { owner, folder }
		local blocked = workspace:Raycast(ball.Position, move, rayParams)
		local hitPlayer: Player? = nil
		if blocked then
			local hitModel = blocked.Instance:FindFirstAncestorOfClass("Model")
			hitPlayer = if hitModel then Players:GetPlayerFromCharacter(hitModel) else nil
		end
		-- También le pega si pasa muy cerca de un jugador
		if not hitPlayer then
			for _, player in Players:GetPlayers() do
				local root = player.Character
					and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (root.Position - ball.Position).Magnitude < 2.6 then
					hitPlayer = player
					break
				end
			end
		end
		traveled += move.Magnitude
		if hitPlayer or blocked or traveled > info.reach + 10 then
			connection:Disconnect()
			if hitPlayer then
				HealthService.Damage(hitPlayer, info.damage, ball.Position)
			end
			fx:FireAllClients("Pop", ball.Position, ball.Color)
			ball:Destroy()
			return
		end
		ball.Position += move
	end)
end

-- El cerebro de una caminante: pasear, perseguir, avisar y morder
local function walkerBrain(model: Model, info, home: Vector3)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model.PrimaryPart :: BasePart
	local nextWander = 0
	local nextAttack = 0
	while model.Parent and humanoid.Health > 0 do
		task.wait(TICK)
		if humanoid.Health <= 0 then
			break
		end
		if stunned(model) then
			humanoid:MoveTo(root.Position)
			continue
		end
		local now = os.clock()
		local player, target = findTarget(root.Position, info.sight, model)
		if target and (target.Position - home).Magnitude > LEASH then
			player, target = nil, nil -- se fue muy lejos: lo deja
		end
		if not player or not target then
			-- Pasea cerca de su lugar
			if now > nextWander then
				nextWander = now + math.random(3, 6)
				local angle = math.random() * math.pi * 2
				humanoid:MoveTo(home + Vector3.new(math.cos(angle), 0, math.sin(angle)) * math.random(4, 14))
			end
			continue
		end
		local offset = target.Position - root.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude > info.reach - 1 then
			humanoid:MoveTo(target.Position)
			continue
		end
		if now < nextAttack then
			humanoid:MoveTo(root.Position)
			continue
		end
		-- ¡Ataque! Se detiene, voltea y el ojo brilla en rojo (tu aviso para rodar)
		nextAttack = now + info.windup + info.cooldown
		humanoid:MoveTo(root.Position)
		if flat.Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
		end
		setEye(model, ANGRY)
		task.wait(info.windup)
		setEye(model, EYE)
		if humanoid.Health <= 0 or stunned(model) then
			continue
		end
		-- Embestida corta hacia adelante
		root:ApplyImpulse(root.CFrame.LookVector * 30 * root.AssemblyMass)
		local now2 = (target.Position - root.Position)
		if target.Parent and Vector3.new(now2.X, 0, now2.Z).Magnitude <= info.reach + 1.5 then
			HealthService.Damage(player, info.damage, root.Position)
		end
	end
end

-- El cerebro de una torreta: girar hacia ti y disparar
local function turretBrain(model: Model, info)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local nextShot = 0
	while model.Parent and humanoid.Health > 0 do
		task.wait(TICK)
		local head = model:FindFirstChild("Cabeza") :: BasePart?
		if not head then
			break
		end
		local _, target = findTarget(head.Position, info.sight, model)
		if not target then
			continue
		end
		aimTurret(model, target.Position - head.Position)
		local now = os.clock()
		if now < nextShot or stunned(model) then
			continue
		end
		nextShot = now + info.windup + info.cooldown
		setEye(model, ANGRY)
		task.wait(info.windup)
		setEye(model, EYE)
		if humanoid.Health <= 0 or not target.Parent then
			continue
		end
		local barrel = model:FindFirstChild("Canon") :: BasePart?
		local from = if barrel then barrel.Position + barrel.CFrame.LookVector * 1.4 else head.Position
		local direction = (target.Position - from)
		if direction.Magnitude > 0.1 then
			fireBall(model, from, direction.Unit, info)
		end
	end
end

local function spawnEnemy(kind: string, home: Vector3)
	local info = Enemies.types[kind]
	if not info then
		warn("[Enemigos] No existe el tipo", kind)
		return
	end
	local model = if info.speed > 0 then buildWalker(kind, info, home) else buildTurret(kind, info, home)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	healthBar(model, humanoid)
	model:SetAttribute("Tipo", kind)
	CollectionService:AddTag(model, "Enemy")
	model.Parent = folder
	local root = model.PrimaryPart :: BasePart
	if not root.Anchored then
		root:SetNetworkOwner(nil) -- el servidor la mueve, no los jugadores
	else
		aimTurret(model, -Vector3.zAxis)
	end

	humanoid.Died:Once(function()
		CollectionService:RemoveTag(model, "Enemy")
		local position = root.Position
		local count = math.random(info.crystals[1], info.crystals[2])
		Pickups.Drop(position, count, math.random() < info.heartChance)
		fx:FireAllClients("Break", position, info.color, info.size)
		model:Destroy()
		task.delay(Enemies.respawn, spawnEnemy, kind, home)
	end)

	task.spawn(function()
		if info.speed > 0 then
			walkerBrain(model, info, home)
		else
			turretBrain(model, info)
		end
	end)
end

function EnemyService.Start(spots: { { kind: string, position: Vector3 } })
	folder = Instance.new("Folder")
	folder.Name = "Oxido"
	folder.Parent = workspace
	for _, spot in spots do
		spawnEnemy(spot.kind, spot.position)
	end
end

return EnemyService
