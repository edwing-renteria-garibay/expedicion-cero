-- La Selva Brumosa: la primera isla, a la que se llega por su portal de Puerto Eco.
--
-- Recorrido (de la llegada hacia el norte):
--   Llegada  -> camino de lodo entre árboles gigantes, con algunas máquinas del Óxido
--   Templo de raíces (la mazmorra):
--     Sala 1  combate: la puerta se abre al romper todas las máquinas de la sala
--     Sala 2  placa con tiempo: párate en ella y corre a la puerta antes de que se cierre
--     Sala 3  gran cofre con el poder de EMPUJE, y un bloque que hay que empujar sobre la placa
--     Sala 4  pared agrietada (rómpela con Empuje) que esconde la llave del jefe
--     Arena   el Gusano de chatarra gigante (Bosses/Worm). Al romperlo sale el NÚCLEO de la
--             selva y un portal de regreso
--
-- El templo se arma de nuevo (con todo cerrado otra vez) cuando nadie ha estado en la selva
-- por un minuto. Lo que ganas (el Empuje, el núcleo) se guarda para siempre.
-- Las puertas y placas las maneja Puzzles; el Empuje, PowerService.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Worm = require(script.Parent.Parent.Bosses.Worm)
local Puzzles = require(script.Parent.Parent.Puzzles)
local DataService = require(script.Parent.Parent.Services.DataService)
local EnemyService = require(script.Parent.Parent.Services.EnemyService)

local Zones = require(ReplicatedStorage.Shared.Config.Zones)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local Selva = {}

-- El centro de la isla (lejos de Puerto Eco, Config/Zones) y la altura del piso
local S = Zones.Selva.center
local GROUND = 2
local H = 24 -- altura de las paredes del templo

-- Dónde apareces al llegar por el portal
Selva.arrival = CFrame.lookAt(S + Vector3.new(0, GROUND + 3, 56), S + Vector3.new(0, GROUND + 3, 0))
local C = {
	stone = Color3.fromRGB(122, 140, 112),
	stoneDark = Color3.fromRGB(86, 104, 82),
	moss = Color3.fromRGB(70, 150, 70),
	cracked = Color3.fromRGB(150, 130, 100),
	trunk = Color3.fromRGB(110, 76, 48),
	leaf = Color3.fromRGB(40, 140, 70),
	leafDark = Color3.fromRGB(30, 110, 60),
	wood = Color3.fromRGB(156, 102, 62),
	gold = Color3.fromRGB(250, 200, 70),
	core = Color3.fromRGB(90, 255, 120),
}

local zoneFolder: Folder -- lo que no cambia (árboles, piso, máquinas de afuera)
local temple: Folder? -- la mazmorra, que se reinicia

local function part(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" then
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p :: BasePart
end

-- Una posición dentro de la selva (x, z relativos al centro, sobre el piso)
local function at(x: number, z: number, y: number?): Vector3
	return S + Vector3.new(x, GROUND + (y or 0), z)
end

local function hint(parent: Instance, key: string, position: Vector3, radius: number)
	local p = part(parent, {
		Name = "Pista" .. key,
		Size = Vector3.one,
		Position = position,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	p:SetAttribute("Pista", key)
	p:SetAttribute("Radio", radius)
	CollectionService:AddTag(p, "Pista")
end

-- Un aviso para mantener E (o tocar en celular)
local function prompt(target: BasePart, action: string, object: string, onTriggered: (Player) -> ())
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.5
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p.Parent = target
	p.Triggered:Connect(onTriggered)
	return p
end

-- Una pared recta de (x1, z1) a (x2, z2) (solo derechas: misma x o misma z)
local function wall(parent: Instance, x1: number, z1: number, x2: number, z2: number, name: string?): BasePart
	local length = math.max(math.abs(x2 - x1), math.abs(z2 - z1)) + 2
	local size = if x1 == x2 then Vector3.new(2, H, length) else Vector3.new(length, H, 2)
	return part(parent, {
		Name = name or "Pared",
		Size = size,
		Position = at((x1 + x2) / 2, (z1 + z2) / 2, H / 2),
		Color = C.stone,
		Material = Enum.Material.Slate,
	})
end

-- Un letrero que flota sobre una pieza
local function signOn(target: BasePart, text: string, offset: number, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.MaxDistance = 60
	gui.Parent = target
	local text_ = Instance.new("TextLabel")
	text_.BackgroundTransparency = 1
	text_.Size = UDim2.fromScale(1, 1)
	text_.Font = Enum.Font.FredokaOne
	text_.Text = text
	text_.TextScaled = true
	text_.TextColor3 = color or Color3.new(1, 1, 1)
	text_.TextStrokeTransparency = 0.3
	text_.Parent = gui
end

local function door(parent: Instance, id: string, x: number, z: number): BasePart
	local d = part(parent, {
		Name = "Puerta",
		Size = Vector3.new(8, H, 1.6),
		Position = at(x, z, H / 2),
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	})
	d:SetAttribute("Id", id)
	d:SetAttribute("Abierta", false)
	CollectionService:AddTag(d, "Puerta")
	return d
end

-- Una pared que atraviesa el templo en "z", con un hueco de 8 en medio para la puerta
-- (howTo = qué hay que hacer para abrirla; sale escrito en la puerta)
local function crossWall(
	parent: Instance,
	z: number,
	halfWidth: number,
	doorId: string,
	howTo: string
): BasePart
	wall(parent, -halfWidth, z, -4, z)
	wall(parent, 4, z, halfWidth, z)
	local d = door(parent, doorId, 0, z)
	signOn(d, howTo, -H / 2 + 9, Color3.fromRGB(255, 230, 140))
	return d
end

local function plate(parent: Instance, doorId: string, x: number, z: number, seconds: number?)
	-- Un marco de piedra oscura alrededor, para que se note en el piso
	part(parent, {
		Name = "MarcoPlaca",
		Size = Vector3.new(8.5, 0.5, 8.5),
		Position = at(x, z, 0.45),
		Color = Color3.fromRGB(50, 56, 50),
		Material = Enum.Material.Slate,
		CanCollide = false,
	})
	local p = part(parent, {
		Name = "Placa",
		Size = Vector3.new(6.5, 0.8, 6.5),
		Position = at(x, z, 0.6),
		Color = Color3.fromRGB(240, 200, 70),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	local light = Instance.new("PointLight")
	light.Color = p.Color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = p
	signOn(p, "▼ PLACA ▼", 4, Color3.fromRGB(255, 220, 90))
	p:SetAttribute("Puerta", doorId)
	if seconds then
		p:SetAttribute("Tiempo", seconds)
	end
	CollectionService:AddTag(p, "Placa")
end

local function chestModel(parent: Instance, name: string, position: Vector3, big: boolean): BasePart
	local scale = if big then 1.6 else 1
	local look = CFrame.lookAt(position, position + Vector3.new(1, 0, 0))
	local base = part(parent, {
		Name = name,
		Size = Vector3.new(3, 2, 2) * scale,
		CFrame = look * CFrame.new(0, 1 * scale, 0),
		Color = C.wood,
	})
	part(parent, {
		Name = "Tapa",
		Size = Vector3.new(3.1, 0.8, 2.1) * scale,
		CFrame = look * CFrame.new(0, 2.4 * scale, 0),
		Color = Color3.fromRGB(110, 70, 44),
	})
	part(parent, {
		Name = "Banda",
		Size = Vector3.new(0.4, 2.9, 2.2) * scale,
		CFrame = look * CFrame.new(0, 1.45 * scale, 0),
		Color = C.gold,
	})
	return base
end

-- Un árbol gigante de selva
local function tree(parent: Instance, position: Vector3, size: number)
	local height = 26 * size
	part(parent, {
		Name = "Tronco",
		Size = Vector3.new(4, height, 4) * Vector3.new(size, 1, size),
		Position = position + Vector3.new(0, height / 2, 0),
		Color = C.trunk,
		Material = Enum.Material.Wood,
	})
	for i = 0, 3 do
		local angle = i * 1.7
		part(parent, {
			Name = "Copa",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (14 + i * 2) * size,
			Position = position
				+ Vector3.new(math.cos(angle) * 5 * size, height + (2 - i) * size, math.sin(angle) * 5 * size),
			Color = if i % 2 == 0 then C.leaf else C.leafDark,
			CanCollide = false,
			CastShadow = true,
		})
	end
	-- Raíces
	for i = 0, 2 do
		local angle = i * 2.1 + 0.4
		part(parent, {
			Name = "Raiz",
			Size = Vector3.new(1.4, 1.4, 7) * size,
			CFrame = CFrame.lookAt(position, position + Vector3.new(math.cos(angle), 0, math.sin(angle)))
				* CFrame.new(0, 0.4, -3 * size)
				* CFrame.Angles(math.rad(-12), 0, 0),
			Color = C.trunk,
			Material = Enum.Material.Wood,
		})
	end
end

-- El piso, las paredes de roca alrededor, el lodo del camino y los árboles
local function land()
	local terrain = workspace.Terrain
	terrain:FillBlock(
		CFrame.new(S + Vector3.new(0, -3, -150)),
		Vector3.new(240, 10, 520),
		Enum.Material.Grass
	)
	terrain:FillBlock(CFrame.new(S + Vector3.new(0, -3, -10)), Vector3.new(16, 10, 150), Enum.Material.Mud)
	-- Bajo el templo, piedra en vez de pasto (el pasto tapaba las placas del piso)
	terrain:FillBlock(
		CFrame.new(S + Vector3.new(0, -3, -220)),
		Vector3.new(108, 10, 290),
		Enum.Material.Slate
	)
	-- Paredes de roca: no se puede salir de la selva
	terrain:FillBlock(
		CFrame.new(S + Vector3.new(-125, 20, -150)),
		Vector3.new(16, 60, 540),
		Enum.Material.Rock
	)
	terrain:FillBlock(
		CFrame.new(S + Vector3.new(125, 20, -150)),
		Vector3.new(16, 60, 540),
		Enum.Material.Rock
	)
	terrain:FillBlock(CFrame.new(S + Vector3.new(0, 20, 115)), Vector3.new(260, 60, 16), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(S + Vector3.new(0, 20, -415)), Vector3.new(260, 60, 16), Enum.Material.Rock)

	-- Llegada: una plataforma de piedra con el portal de regreso
	part(zoneFolder, {
		Name = "Llegada",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 24, 24),
		CFrame = CFrame.new(at(0, 60, 0.2)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.stone,
		Material = Enum.Material.Slate,
	})
	hint(zoneFolder, "SelvaLlegada", at(0, 56), 10)

	local rng = Random.new(33)
	local placed = 0
	while placed < 70 do
		local x = rng:NextNumber(-110, 110)
		local z = rng:NextNumber(-400, 100)
		local onPath = math.abs(x) < 16 and z > -80
		local inTemple = math.abs(x) < 64 and z < -70
		local atArrival = math.abs(x) < 20 and z > 40
		if not onPath and not inTemple and not atArrival then
			placed += 1
			tree(zoneFolder, at(x, z), rng:NextNumber(0.8, 1.3))
		end
	end
	-- Unos árboles a los lados del camino, para que se sienta cerrado
	for i = 0, 5 do
		for _, side in { -1, 1 } do
			tree(zoneFolder, at(side * rng:NextNumber(20, 30), 30 - i * 20), rng:NextNumber(0.7, 1))
		end
	end

	-- Máquinas en el camino (vuelven a salir)
	EnemyService.Spawn("Rastreador", at(6, 8), { parent = zoneFolder })
	EnemyService.Spawn("Rastreador", at(-6, -30), { parent = zoneFolder })
	EnemyService.Spawn("Torreta", at(22, -52), { parent = zoneFolder })

	-- La fachada del templo
	for _, side in { -1, 1 } do
		part(zoneFolder, {
			Name = "Columna",
			Size = Vector3.new(6, H + 8, 6),
			Position = at(side * 9, -80, (H + 8) / 2),
			Color = C.stoneDark,
			Material = Enum.Material.Slate,
		})
	end
	local lintel = part(zoneFolder, {
		Name = "Dintel",
		Size = Vector3.new(26, 5, 6),
		Position = at(0, -80, H + 6),
		Color = C.stoneDark,
		Material = Enum.Material.Slate,
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 50)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	gui.MaxDistance = 160
	gui.Parent = lintel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = "Templo de raíces"
	label.TextScaled = true
	label.TextColor3 = C.core
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	hint(zoneFolder, "Templo", at(0, -72), 12)
end

-- Arma el templo completo, todo cerrado
local function buildTemple()
	local folder = Instance.new("Folder")
	folder.Name = "Templo"
	folder.Parent = zoneFolder
	temple = folder

	-- Pisos
	part(folder, {
		Name = "Piso",
		Size = Vector3.new(62, 0.4, 202),
		Position = at(0, -180, 0.2),
		Color = C.stoneDark,
		Material = Enum.Material.Slate,
	})
	part(folder, {
		Name = "Piso",
		Size = Vector3.new(102, 0.4, 82),
		Position = at(0, -320, 0.2),
		Color = C.stoneDark,
		Material = Enum.Material.Slate,
	})
	-- Paredes de los lados (la derecha tiene un hueco en la sala 4, tapado por la pared agrietada)
	wall(folder, -30, -80, -30, -280)
	wall(folder, 30, -80, 30, -245)
	wall(folder, 30, -265, 30, -280)
	-- La fachada (con la entrada en medio)
	wall(folder, -30, -80, -6, -80)
	wall(folder, 6, -80, 30, -80)
	-- Paredes entre salas, con su puerta
	crossWall(folder, -130, 30, "SelvaSala1", "Rompe todas las máquinas")
	crossWall(folder, -180, 30, "SelvaPlaca", "Pisa la placa amarilla")
	crossWall(folder, -230, 30, "SelvaBloque", "Pon el bloque en la placa")
	local bossDoor = crossWall(folder, -280, 50, "SelvaJefe", "Necesitas la llave")
	-- La arena del jefe
	wall(folder, -50, -280, -50, -360)
	wall(folder, 50, -280, 50, -360)
	wall(folder, -50, -360, 50, -360)

	-- Sala 1: combate. La puerta se abre al romper todas
	local alive = 0
	local function roomCleared()
		alive -= 1
		if alive <= 0 then
			Puzzles.SetDoor("SelvaSala1", true)
			fx:FireAllClients("Say", "SalaLimpia")
		end
	end
	for _, spot in { { -10, -100 }, { 10, -108 }, { 0, -120 } } do
		alive += 1
		EnemyService.Spawn("Rastreador", at(spot[1], spot[2]), {
			parent = folder,
			respawn = false,
			onDied = roomCleared,
		})
	end
	hint(folder, "Sala", at(0, -90), 10)

	-- Sala 2: placa con tiempo (7 segundos para llegar a la puerta)
	plate(folder, "SelvaPlaca", -22, -140, 7)
	for _, x in { -12, 8 } do
		part(folder, {
			Name = "Columna",
			Size = Vector3.new(5, H, 5),
			Position = at(x, -158, H / 2),
			Color = C.stoneDark,
			Material = Enum.Material.Slate,
		})
	end
	hint(folder, "Placa", at(-22, -140), 12)

	-- Sala 3: el gran cofre con el Empuje y el bloque
	local bigChest = chestModel(folder, "GranCofre", at(-20, -200), true)
	CollectionService:AddTag(bigChest, "Secreto")
	prompt(bigChest, "Abrir", "Gran cofre", function(player)
		if DataService.GivePower(player, "Empuje") then
			fx:FireClient(player, "Chest", bigChest.Position, 0, false)
			fx:FireClient(player, "Say", "GranCofre")
		else
			fx:FireClient(player, "Say", "YaEmpuje")
		end
	end)
	hint(folder, "GranCofreCerca", at(-20, -192), 10)

	local blockStart = at(0, -196, 3)
	local block = part(folder, {
		Name = "Bloque",
		Size = Vector3.new(6, 6, 6),
		Position = blockStart,
		Color = C.cracked,
		Material = Enum.Material.Cobblestone,
	})
	CollectionService:AddTag(block, "Empujable")
	plate(folder, "SelvaBloque", 0, -212)
	hint(folder, "Bloque", at(0, -188), 8)
	-- Si el bloque se atora en una esquina, esta palanca lo regresa a su lugar
	local lever = part(folder, {
		Name = "Palanca",
		Size = Vector3.new(1, 4, 1),
		Position = at(24, -186, 2),
		Color = C.gold,
		Material = Enum.Material.Metal,
	})
	prompt(lever, "Reiniciar", "Bloque", function()
		if not block:GetAttribute("Moviendo") then
			block.Position = blockStart
			fx:FireAllClients("Slide", blockStart)
		end
	end)

	-- Sala 4: la pared agrietada esconde la llave del jefe
	EnemyService.Spawn("Rastreador", at(-12, -250), { parent = folder, respawn = false })
	EnemyService.Spawn("Escudero", at(8, -262), { parent = folder, respawn = false })
	local cracked = part(folder, {
		Name = "Agrietada",
		Size = Vector3.new(2, H, 20),
		Position = at(30, -255, H / 2),
		Color = C.cracked,
		Material = Enum.Material.Cobblestone,
	})
	CollectionService:AddTag(cracked, "Agrietado")
	hint(folder, "Agrietado", at(20, -255), 10)
	wall(folder, 30, -245, 44, -245)
	wall(folder, 30, -265, 44, -265)
	wall(folder, 44, -245, 44, -265)
	part(folder, {
		Name = "Piso",
		Size = Vector3.new(14, 0.4, 20),
		Position = at(37, -255, 0.2),
		Color = C.stoneDark,
		Material = Enum.Material.Slate,
	})
	local keyChest = chestModel(folder, "CofreLlave", at(38, -255), false)
	CollectionService:AddTag(keyChest, "Secreto")
	prompt(keyChest, "Abrir", "Cofre", function(player)
		if folder:GetAttribute("LlaveJefe") then
			fx:FireClient(player, "Say", "CofreVacio")
			return
		end
		folder:SetAttribute("LlaveJefe", true)
		fx:FireAllClients("Chest", keyChest.Position, 0, false)
		fx:FireAllClients("Say", "Llave")
	end)
	prompt(bossDoor, "Abrir", "Puerta del jefe", function(player)
		if folder:GetAttribute("LlaveJefe") then
			Puzzles.SetDoor("SelvaJefe", true)
		else
			fx:FireClient(player, "Say", "PuertaJefe")
		end
	end)

	-- La arena: el gusano y, al romperlo, el núcleo y el portal de regreso
	local arena = at(0, -322)
	hint(folder, "Jefe", at(0, -290), 10)
	Worm.Build(arena, 36, folder, function(position: Vector3)
		fx:FireAllClients("Say", "JefeVencido")
		local core = part(folder, {
			Name = "NucleoSelva",
			Size = Vector3.new(2.4, 4, 2.4),
			CFrame = CFrame.new(position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(45), 0),
			Color = C.core,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		local light = Instance.new("PointLight")
		light.Color = C.core
		light.Range = 20
		light.Brightness = 3
		light.Parent = core
		prompt(core, "Tomar", "Núcleo de la selva", function(player)
			if DataService.GiveCore(player, "Selva") then
				fx:FireClient(player, "Chest", core.Position, 0, false)
				fx:FireClient(player, "Say", "Nucleo")
			else
				fx:FireClient(player, "Say", "YaNucleo")
			end
		end)
		-- Portal de regreso a Puerto Eco
		local back = part(folder, {
			Name = "PortalRegreso",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 12, 12),
			CFrame = CFrame.new(at(0, -352, 7)) * CFrame.Angles(0, math.rad(90), 0),
			Color = C.core,
			Material = Enum.Material.Neon,
			Transparency = 0.35,
			CanCollide = false,
		})
		back:SetAttribute("Destino", "Puerto")
		CollectionService:AddTag(back, "Portal")
	end)
end

-- ¿Hay alguien en la selva?
local function anyoneInside(): boolean
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and Zones.Inside(Zones.Selva, root.Position) then
			return true
		end
	end
	return false
end

function Selva.Build()
	zoneFolder = Instance.new("Folder")
	zoneFolder.Name = "SelvaBrumosa"
	zoneFolder.Parent = workspace
	land()
	-- El portal de regreso de la llegada
	local back = part(zoneFolder, {
		Name = "PortalRegreso",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 12, 12),
		CFrame = CFrame.new(at(0, 78, 7)) * CFrame.Angles(0, math.rad(90), 0),
		Color = Color3.fromRGB(110, 230, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
	})
	back:SetAttribute("Destino", "Puerto")
	CollectionService:AddTag(back, "Portal")
	for _, side in { -1, 1 } do
		part(zoneFolder, {
			Name = "Columna",
			Size = Vector3.new(2.4, 16, 2.4),
			Position = at(side * 7.5, 78, 8),
			Color = C.stone,
			Material = Enum.Material.Slate,
		})
	end
	buildTemple()

	-- Si nadie está en la selva por un minuto, el templo se arma de nuevo (todo cerrado)
	task.spawn(function()
		local empty = 0
		local used = false
		while true do
			task.wait(5)
			if anyoneInside() then
				empty = 0
				used = true
			else
				empty += 5
				if used and empty >= 60 then
					used = false
					if temple then
						temple:Destroy()
					end
					buildTemple()
				end
			end
		end
	end)
end

return Selva
