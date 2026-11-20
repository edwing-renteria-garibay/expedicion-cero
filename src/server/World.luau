-- Arma el Nexo (antes Puerto Eco), la isla central de donde salen los portales:
--   * el mar y la isla (con Terrain: arena en la orilla y pasto arriba)
--   * la plaza con el pedestal de las 7 llaves, el tablero de la temporada y el punto de aparición
--   * el anillo de 9 portales al norte (los mundos que aún no existen dicen "Sin energía")
--   * la tienda (este) y el taller de Chispa (oeste)
--   * el Salón de Leyendas (sureste): nombres y estatuas de quienes juntaron las 7 llaves
--   * el campo de práctica (sur) con muñecos para probar el bastón (Dummies)
--   * árboles y rocas de adorno, siempre en el mismo lugar
--
-- Las piezas que hacen que Chispa diga algo llevan la etiqueta "Pista" (Config/Drone).
-- Todo usa colores vivos y SmoothPlastic: estilo caricatura.

local CollectionService = game:GetService("CollectionService")

local World = {}

local GROUND = 2 -- altura del pasto de la isla

-- Colores (estilo caricatura)
local C = {
	stone = Color3.fromRGB(196, 190, 176),
	stoneDark = Color3.fromRGB(140, 134, 124),
	wood = Color3.fromRGB(156, 102, 62),
	woodDark = Color3.fromRGB(110, 70, 44),
	roofRed = Color3.fromRGB(214, 84, 66),
	roofBlue = Color3.fromRGB(70, 128, 210),
	wall = Color3.fromRGB(246, 234, 206),
	leaf = Color3.fromRGB(86, 196, 92),
	leafDark = Color3.fromRGB(56, 160, 76),
	trunk = Color3.fromRGB(150, 98, 58),
	rock = Color3.fromRGB(150, 156, 168),
	core = Color3.fromRGB(110, 230, 255),
}

-- Los 9 portales, de izquierda a derecha viendo hacia el norte: nombre, color y si ya abre.
-- La frase de Chispa al acercarte es la de su key (Config/Drone).
local PORTALS = {
	{ key = "Selva", name = "Selva Brumosa", color = Color3.fromRGB(80, 220, 110), open = true },
	{ key = "Volcan", name = "Volcán Brasa", color = Color3.fromRGB(255, 120, 40) },
	{ key = "Pista", name = "Pista Neón", color = Color3.fromRGB(255, 80, 200) },
	{ key = "Arena", name = "Arena del Óxido", color = Color3.fromRGB(200, 120, 60) },
	{ key = "Mansion", name = "Mansión Eco", color = Color3.fromRGB(140, 110, 200) },
	{ key = "Glaciar", name = "Glaciar Silencio", color = Color3.fromRGB(120, 220, 255) },
	{ key = "Ruinas", name = "Ruinas del Cielo", color = Color3.fromRGB(250, 220, 120) },
	{ key = "Laberinto", name = "Laberinto Espejo", color = Color3.fromRGB(200, 230, 240) },
	{ key = "Pixel", name = "Mundo Píxel", color = Color3.fromRGB(120, 255, 160) },
}
local RING = 108 -- qué tan lejos de la plaza está el anillo de portales
local FIRST, LAST = 210, 330 -- de qué ángulo a qué ángulo va el anillo (270 = norte)

-- Dónde está cada portal, mirando a la plaza
local function portalFrame(index: number): CFrame
	local angle = math.rad(FIRST + (LAST - FIRST) * (index - 1) / (#PORTALS - 1))
	local position = Vector3.new(math.cos(angle) * RING, GROUND, math.sin(angle) * RING)
	return CFrame.lookAt(position, Vector3.new(0, GROUND, 0))
end

-- El Salón de Leyendas
local HALL = Vector3.new(86, GROUND, 86)

-- La chatarrería del Óxido, donde salen las máquinas (EnemyService)
local SCRAPYARD = Vector3.new(-80, GROUND, 80)

-- Los cofres escondidos (ChestService): cada jugador puede abrir cada uno una vez.
-- reward = cristales que da; heart = true si da un corazón más
local CHESTS = {
	{ name = "CofrePalmeras", position = Vector3.new(118, GROUND, -46), reward = 25 },
	{ name = "CofreFaro", position = Vector3.new(-124, GROUND, -30), reward = 25 },
	{ name = "CofrePlaya", position = Vector3.new(46, GROUND, 132), reward = 25 },
	{
		name = "CofreChatarra",
		position = SCRAPYARD + Vector3.new(-14, 0, 18),
		reward = 40,
		heart = true,
		big = true,
	},
}

local folder: Folder

-- Crea una pieza fija con estas propiedades
local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" and key ~= "Parent" then
			(p :: any)[key] = value
		end
	end
	p.Parent = props.Parent or folder
	return p :: BasePart
end

-- Una zona invisible que hace hablar a Chispa al acercarte
local function hint(key: string, position: Vector3, radius: number)
	local p = part({
		Name = "Pista" .. key,
		Size = Vector3.new(1, 1, 1),
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

-- Un letrero que flota sobre algo
local function sign(parent: BasePart, title: string, subtitle: string?, color: Color3?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffsetWorldSpace = Vector3.new(0, parent.Size.Y / 2 + 3, 0)
	gui.MaxDistance = 140
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Titulo"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0.6, 0)
	label.Font = Enum.Font.FredokaOne
	label.Text = title
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	if subtitle then
		local small = Instance.new("TextLabel")
		small.Name = "Subtitulo"
		small.BackgroundTransparency = 1
		small.Position = UDim2.fromScale(0, 0.6)
		small.Size = UDim2.new(1, 0, 0.4, 0)
		small.Font = Enum.Font.FredokaOne
		small.Text = subtitle
		small.TextScaled = true
		small.TextColor3 = Color3.new(1, 1, 1)
		small.TextStrokeTransparency = 0.4
		small.Parent = gui
	end
end

-- El mar y la isla con Terrain
local function island()
	local terrain = workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(40, 170, 210)
	terrain.WaterTransparency = 0.4
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 8
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(110, 200, 90))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(240, 222, 160))
	-- El mar (su superficie queda en y = 0)
	terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(800, 16, 800), Enum.Material.Water)
	-- El fondo bajo el agua
	terrain:FillBlock(CFrame.new(0, -20, 0), Vector3.new(800, 8, 800), Enum.Material.Sand)
	-- La orilla de arena y encima el pasto (un poco más chico)
	terrain:FillCylinder(CFrame.new(0, -5, 0), 12, 165, Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(0, -4, 0), 12, 150, Enum.Material.Grass)
end

-- La plaza del centro: piso de piedra, el pedestal de las 7 llaves y donde apareces
local function plaza()
	part({
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 64, 64),
		CFrame = CFrame.new(0, GROUND + 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.stone,
	})
	part({
		Name = "Borde",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 68, 68),
		CFrame = CFrame.new(0, GROUND + 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.stoneDark,
	})
	-- El pedestal
	local base = part({
		Name = "Pedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 14, 14),
		CFrame = CFrame.new(0, GROUND + 1.8, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.stoneDark,
	})
	sign(base, "Llaves del Nexo", "0 de 7", C.core)
	-- Siete huecos, uno por llave (cada jugador ve encendidas las suyas: client/Hub)
	for i = 0, 6 do
		local angle = math.rad(i * 360 / 7)
		local p = part({
			Name = "Hueco" .. (i + 1),
			Size = Vector3.new(1.6, 4, 1.6),
			CFrame = CFrame.new(math.cos(angle) * 4.5, GROUND + 5.3, math.sin(angle) * 4.5)
				* CFrame.Angles(0, angle, math.rad(45)),
			Color = Color3.fromRGB(70, 74, 82),
			Material = Enum.Material.Glass,
			Transparency = 0.3,
		})
		p:SetAttribute("Llave", i + 1)
	end
	-- Un cristal flotando en medio, apagado
	part({
		Name = "Corazon",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		Position = Vector3.new(0, GROUND + 7, 0),
		Color = C.core,
		Material = Enum.Material.Neon,
		Transparency = 0.6,
		CanCollide = false,
	})
	hint("Plaza", Vector3.new(0, GROUND, 0), 18)

	-- El tablero de la temporada (KeyService escribe en él)
	local board = part({
		Name = "Tablero",
		Size = Vector3.new(14, 8, 1),
		CFrame = CFrame.lookAt(Vector3.new(-22, GROUND + 6, -38), Vector3.new(-22, GROUND + 6, 0)),
		Color = C.woodDark,
	})
	for _, side in { -1, 1 } do
		part({
			Name = "Pata",
			Size = Vector3.new(1, 6, 1),
			Position = Vector3.new(-22 + side * 6, GROUND + 3, -38),
			Color = C.wood,
		})
	end
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(560, 320)
	surface.Parent = board
	local text = Instance.new("TextLabel")
	text.Name = "Texto"
	text.BackgroundColor3 = Color3.fromRGB(24, 36, 54)
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.Text = "Temporada..."
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = surface
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = text

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Aparicion"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.Position = Vector3.new(0, GROUND + 0.6, 22)
	spawn.Color = C.core
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.5
	spawn.Duration = 0
	spawn.CanCollide = true
	spawn.Parent = folder
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	-- Camino de piedra de la plaza a cada lugar
	local function path(from: Vector3, to: Vector3)
		local middle = (from + to) / 2
		local length = (to - from).Magnitude
		part({
			Name = "Camino",
			Size = Vector3.new(8, 0.3, length),
			CFrame = CFrame.lookAt(middle, to) + Vector3.new(0, 0, 0),
			Color = C.stone,
			CanCollide = false,
		})
	end
	local y = GROUND + 0.05
	path(Vector3.new(0, y, -32), Vector3.new(0, y, -92)) -- a los portales
	path(Vector3.new(24, y, 24), Vector3.new(72, y, 72)) -- al Salón de Leyendas
	path(Vector3.new(32, y, 0), Vector3.new(66, y, 20)) -- a la tienda
	path(Vector3.new(-32, y, 0), Vector3.new(-66, y, 20)) -- al taller
	path(Vector3.new(0, y, 32), Vector3.new(0, y, 78)) -- al campo de práctica
end

-- Un portal: dos columnas, un arco y un disco de luz (débil si todavía no tiene energía)
local function portal(info, frame: CFrame)
	local model = Instance.new("Model")
	model.Name = "Portal" .. info.key
	model.Parent = folder
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	-- Escalón
	part({
		Name = "Escalon",
		Size = Vector3.new(22, 1.4, 10),
		CFrame = at(0, 0.5, 0),
		Color = C.stoneDark,
		Parent = model,
	})
	for _, side in { -1, 1 } do
		part({
			Name = "Columna",
			Size = Vector3.new(3, 18, 3),
			CFrame = at(side * 8, 10, 0),
			Color = C.stone,
			Parent = model,
		})
		-- Un cristal del color del mundo en la punta
		part({
			Name = "Cristal",
			Size = Vector3.new(1.6, 3, 1.6),
			CFrame = at(side * 8, 21, 0) * CFrame.Angles(0, math.rad(45), 0),
			Color = info.color,
			Material = Enum.Material.Neon,
			Parent = model,
		})
	end
	local arch = part({
		Name = "Arco",
		Size = Vector3.new(20, 3, 3.4),
		CFrame = at(0, 19.5, 0),
		Color = C.stone,
		Parent = model,
	})
	sign(arch, info.name, if info.open then "Abierto" else "Sin energía", info.color)
	local light = part({
		Name = "Luz",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 13, 13),
		CFrame = at(0, 9, 0) * CFrame.Angles(0, math.rad(90), 0),
		Color = info.color,
		Material = Enum.Material.Neon,
		Transparency = if info.open then 0.3 else 0.75,
		CanCollide = not info.open, -- los apagados todavía no se pueden pasar
		Parent = model,
	})
	local front = at(0, 0, -8).Position -- frente al portal, del lado de la plaza
	if info.open then
		-- Al tocarlo te lleva a su mundo (PortalService)
		light:SetAttribute("Destino", info.key)
		CollectionService:AddTag(light, "Portal")
		hint(info.key .. "Abierto", front, 11)
	else
		hint(info.key, front, 11)
	end
end

-- El Salón de Leyendas: un pabellón abierto con el muro de nombres y 3 estatuas doradas
-- (KeyService escribe los nombres)
local function hall()
	local model = Instance.new("Model")
	model.Name = "SalonLeyendas"
	model.Parent = folder
	local look = CFrame.lookAt(HALL, Vector3.new(0, GROUND, 0))
	local function at(x: number, y: number, z: number): CFrame
		return look * CFrame.new(x, y, z)
	end
	local gold = Color3.fromRGB(250, 200, 70)
	part({
		Name = "Piso",
		Size = Vector3.new(34, 1, 26),
		CFrame = at(0, 0.5, 0),
		Color = C.stone,
		Parent = model,
	})
	for _, x in { -15, -5, 5, 15 } do
		part({
			Name = "Columna",
			Size = Vector3.new(2.4, 16, 2.4),
			CFrame = at(x, 9, -11),
			Color = C.wall,
			Parent = model,
		})
	end
	part({
		Name = "Techo",
		Size = Vector3.new(36, 2, 28),
		CFrame = at(0, 18, 0),
		Color = gold,
		Parent = model,
	})
	local wall = part({
		Name = "Muro",
		Size = Vector3.new(32, 16, 1.4),
		CFrame = at(0, 9, 12),
		Color = C.wall,
		Parent = model,
	})
	local front = part({
		Name = "Letrero",
		Size = Vector3.new(22, 3, 0.6),
		CFrame = at(0, 20.5, -13),
		Color = C.wood,
		Parent = model,
	})
	sign(front, "Salón de Leyendas", "Junta las 7 llaves", gold)
	-- El muro con los nombres (mira hacia adentro del pabellón)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(800, 400)
	surface.Parent = wall
	local list = Instance.new("TextLabel")
	list.Name = "Lista"
	list.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
	list.Size = UDim2.fromScale(1, 1)
	list.Font = Enum.Font.FredokaOne
	list.Text = "Todavía no hay Leyendas esta temporada"
	list.TextSize = 30
	list.TextWrapped = true
	list.TextColor3 = gold
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.Parent = surface
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.Parent = list
	-- Tres estatuas (1°, 2° y 3° de la temporada)
	for i, x in { 0, -9, 9 } do
		local height = if i == 1 then 3 else 2
		part({
			Name = "Base",
			Size = Vector3.new(5, height, 5),
			CFrame = at(x, height / 2 + 1, 2),
			Color = C.stoneDark,
			Parent = model,
		})
		local y = height + 1
		local statue = Instance.new("Model")
		statue.Name = "Estatua" .. i
		statue.Parent = model
		local function block(name: string, size: Vector3, offset: Vector3)
			return part({
				Name = name,
				Size = size,
				CFrame = at(x + offset.X, y + offset.Y, 2 + offset.Z),
				Color = gold,
				Material = Enum.Material.Metal,
				Parent = statue,
			})
		end
		block("Pierna", Vector3.new(0.9, 2, 0.9), Vector3.new(-0.5, 1, 0))
		block("Pierna", Vector3.new(0.9, 2, 0.9), Vector3.new(0.5, 1, 0))
		block("Cuerpo", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
		block("Brazo", Vector3.new(0.8, 2, 0.8), Vector3.new(-1.4, 3, 0))
		block("Brazo", Vector3.new(0.8, 2.4, 0.8), Vector3.new(1.4, 4, 0))
		local head = block("Cabeza", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.7, 0))
		statue.PrimaryPart = head
		local gui = Instance.new("BillboardGui")
		gui.Name = "Nombre"
		gui.Size = UDim2.fromOffset(180, 30)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
		gui.MaxDistance = 80
		gui.Parent = head
		local label = Instance.new("TextLabel")
		label.Name = "Texto"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.Text = `{i}° · ¿Tú?`
		label.TextScaled = true
		label.TextColor3 = gold
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
	end
	hint("Salon", HALL, 18)
end

-- Una casita de caricatura con techo de dos aguas y un letrero
local function house(
	name: string,
	subtitle: string,
	center: Vector3,
	faceTo: Vector3,
	roof: Color3,
	hintKey: string
)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = folder
	local look = CFrame.lookAt(center, Vector3.new(faceTo.X, center.Y, faceTo.Z))
	local function at(offset: Vector3): CFrame
		return look * CFrame.new(offset)
	end
	local W, D, H = 22, 18, 12
	part({
		Name = "Piso",
		Size = Vector3.new(W + 2, 1, D + 2),
		CFrame = at(Vector3.new(0, 0.5, 0)),
		Color = C.woodDark,
		Parent = model,
	})
	-- Paredes (la de enfrente con una puerta)
	part({
		Name = "Atras",
		Size = Vector3.new(W, H, 1),
		CFrame = at(Vector3.new(0, H / 2 + 1, D / 2)),
		Color = C.wall,
		Parent = model,
	})
	part({
		Name = "Izq",
		Size = Vector3.new(1, H, D),
		CFrame = at(Vector3.new(-W / 2, H / 2 + 1, 0)),
		Color = C.wall,
		Parent = model,
	})
	part({
		Name = "Der",
		Size = Vector3.new(1, H, D),
		CFrame = at(Vector3.new(W / 2, H / 2 + 1, 0)),
		Color = C.wall,
		Parent = model,
	})
	part({
		Name = "FrenteIzq",
		Size = Vector3.new(7, H, 1),
		CFrame = at(Vector3.new(-7.5, H / 2 + 1, -D / 2)),
		Color = C.wall,
		Parent = model,
	})
	part({
		Name = "FrenteDer",
		Size = Vector3.new(7, H, 1),
		CFrame = at(Vector3.new(7.5, H / 2 + 1, -D / 2)),
		Color = C.wall,
		Parent = model,
	})
	part({
		Name = "Dintel",
		Size = Vector3.new(8, 4, 1),
		CFrame = at(Vector3.new(0, H - 1, -D / 2)),
		Color = C.wall,
		Parent = model,
	})
	-- Puerta de madera cerrada (con su aviso: abre el menú de la tienda o del taller)
	local door = part({
		Name = "Puerta",
		Size = Vector3.new(8, H - 4, 0.6),
		CFrame = at(Vector3.new(0, (H - 4) / 2 + 1, -D / 2)),
		Color = C.wood,
		Parent = model,
	})
	-- Techo: dos cuñas
	for _, side in { -1, 1 } do
		part({
			ClassName = "WedgePart",
			Name = "Techo",
			Size = Vector3.new(D + 4, 7, W / 2 + 2),
			CFrame = at(Vector3.new(side * (W / 4 + 0.5), H + 4.5, 0))
				* CFrame.Angles(0, math.rad(-90 * side), 0),
			Color = roof,
			Parent = model,
		})
	end
	local board = part({
		Name = "Letrero",
		Size = Vector3.new(12, 3, 0.6),
		CFrame = at(Vector3.new(0, H + 1.5, -D / 2 - 0.8)),
		Color = C.wood,
		Parent = model,
	})
	sign(board, name, subtitle)
	hint(hintKey, (at(Vector3.new(0, 0, -D / 2 - 6))).Position, 12)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Entrar"
	prompt.ObjectText = name
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("AbreMenu", hintKey) -- client/UI/Shop abre el menú
	prompt.Parent = door
end

-- Una palmera de caricatura
local function tree(position: Vector3, size: number)
	local trunkHeight = 10 * size
	part({
		Name = "Tronco",
		Size = Vector3.new(1.6 * size, trunkHeight, 1.6 * size),
		CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(6)),
		Color = C.trunk,
	})
	for i = 0, 2 do
		local angle = i * 2.1
		part({
			Name = "Hojas",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (6 + i) * size,
			Position = position + Vector3.new(
				math.cos(angle) * 2 * size,
				trunkHeight + (1 - i * 0.6) * size,
				math.sin(angle) * 2 * size
			),
			Color = if i % 2 == 0 then C.leaf else C.leafDark,
			CanCollide = false,
		})
	end
end

local function rock(position: Vector3, size: number, spin: number)
	part({
		Name = "Roca",
		Size = Vector3.new(5, 3, 4) * size,
		CFrame = CFrame.new(position + Vector3.new(0, 1 * size, 0)) * CFrame.Angles(0.2, spin, 0.15),
		Color = C.rock,
	})
end

-- Árboles y rocas: al azar pero con la misma semilla, así salen siempre en el mismo lugar.
-- No se ponen en la plaza, los caminos ni los edificios.
local function decorate()
	local rng = Random.new(2026)
	local free = function(p: Vector3): boolean
		if p.Magnitude < 42 then
			return false -- plaza
		end
		if p.Z < -30 and p.Magnitude > RING - 18 and p.Magnitude < RING + 18 then
			return false -- portales
		end
		if (p - HALL).Magnitude < 30 then
			return false -- Salón de Leyendas
		end
		if math.abs(p.X) < 10 then
			return false -- camino norte-sur
		end
		if math.abs(p.X) > 50 and math.abs(p.X) < 102 and p.Z > -6 and p.Z < 46 then
			return false -- tienda y taller
		end
		if math.abs(p.X) < 40 and p.Z > 70 and p.Z < 125 then
			return false -- campo de práctica
		end
		if (p - SCRAPYARD).Magnitude < 40 then
			return false -- chatarrería
		end
		for _, chest in CHESTS do
			if (p - chest.position).Magnitude < 8 then
				return false -- cofres
			end
		end
		return true
	end
	local placed = 0
	while placed < 46 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(30, 140)
		local p = Vector3.new(math.cos(angle) * distance, GROUND, math.sin(angle) * distance)
		if free(p) then
			placed += 1
			if rng:NextNumber() < 0.7 then
				tree(p, rng:NextNumber(0.8, 1.3))
			else
				rock(p, rng:NextNumber(0.6, 1.4), rng:NextNumber(0, math.pi))
			end
		end
	end
end

-- La cerca del campo de práctica
local function trainingField()
	local center = Vector3.new(0, GROUND, 96)
	part({
		Name = "Arena",
		Size = Vector3.new(60, 0.3, 40),
		Position = center + Vector3.new(0, 0.1, 0),
		Color = Color3.fromRGB(226, 196, 140),
		CanCollide = false,
	})
	for i = -6, 6 do
		for _, z in { -20, 20 } do
			if not (z == -20 and math.abs(i) <= 1) then -- entrada
				part({
					Name = "Poste",
					Size = Vector3.new(1, 4, 1),
					Position = center + Vector3.new(i * 5, 2, z),
					Color = C.wood,
				})
			end
		end
	end
	for i = -4, 4 do
		for _, x in { -30, 30 } do
			part({
				Name = "Poste",
				Size = Vector3.new(1, 4, 1),
				Position = center + Vector3.new(x, 2, i * 5),
				Color = C.wood,
			})
		end
	end
	local board = part({
		Name = "Letrero",
		Size = Vector3.new(14, 3, 0.6),
		Position = center + Vector3.new(0, 7, -21),
		Color = C.wood,
	})
	sign(board, "Campo de práctica", "Pégale a los muñecos")
	hint("Campo", center + Vector3.new(0, 0, -22), 14)
	hint("Giro", center, 16)
end

-- La chatarrería: un claro de tierra con montones de chatarra oxidada y tubos, donde
-- patrullan las máquinas del Óxido
local function scrapyard()
	local rng = Random.new(77)
	part({
		Name = "Tierra",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 64, 64),
		CFrame = CFrame.new(SCRAPYARD + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 112, 80),
		CanCollide = false,
	})
	local rust = { Color3.fromRGB(176, 92, 48), Color3.fromRGB(140, 80, 56), Color3.fromRGB(110, 104, 98) }
	for i = 1, 14 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(14, 30)
		local position = SCRAPYARD + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local size = Vector3.new(rng:NextNumber(3, 7), rng:NextNumber(2, 5), rng:NextNumber(3, 7))
		part({
			Name = "Chatarra",
			Size = size,
			CFrame = CFrame.new(position + Vector3.new(0, size.Y / 2 - 0.4, 0)) * CFrame.Angles(
				rng:NextNumber(-0.3, 0.3),
				rng:NextNumber(0, math.pi),
				rng:NextNumber(-0.3, 0.3)
			),
			Color = rust[(i % #rust) + 1],
			Material = Enum.Material.CorrodedMetal,
		})
	end
	-- Tubos tirados
	for i = 1, 4 do
		local angle = i * 1.6
		part({
			Name = "Tubo",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(10, 2.4, 2.4),
			CFrame = CFrame.new(SCRAPYARD + Vector3.new(math.cos(angle) * 8, 1.2, math.sin(angle) * 8))
				* CFrame.Angles(0, angle, 0),
			Color = Color3.fromRGB(120, 124, 130),
			Material = Enum.Material.CorrodedMetal,
		})
	end
	local board = part({
		Name = "Letrero",
		Size = Vector3.new(12, 3, 0.6),
		CFrame = CFrame.lookAt(SCRAPYARD + Vector3.new(26, 6, -26), Vector3.new(0, GROUND + 6, 0)),
		Color = C.wood,
	})
	sign(board, "Chatarrería", "Máquinas del Óxido", Color3.fromRGB(255, 150, 80))
	hint("Chatarra", SCRAPYARD, 34)
end

-- Un cofre de madera con tapa y bandas doradas. ChestService le pone el aviso para abrirlo.
local function chest(info)
	local scale = if info.big then 1.5 else 1
	local model = Instance.new("Model")
	model.Name = info.name
	local look = CFrame.lookAt(info.position, Vector3.new(0, GROUND, 0))
	local base = part({
		Name = "Caja",
		Size = Vector3.new(3, 2, 2) * scale,
		CFrame = look * CFrame.new(0, 1 * scale, 0),
		Color = C.wood,
		Parent = model,
	})
	part({
		Name = "Tapa",
		Size = Vector3.new(3.1, 0.8, 2.1) * scale,
		CFrame = look * CFrame.new(0, 2.4 * scale, 0),
		Color = C.woodDark,
		Parent = model,
	})
	for _, x in { -1, 1 } do
		part({
			Name = "Banda",
			Size = Vector3.new(0.3, 2.9, 2.2) * scale,
			CFrame = look * CFrame.new(x * 1 * scale, 1.45 * scale, 0),
			Color = Color3.fromRGB(250, 200, 70),
			Parent = model,
		})
	end
	model.PrimaryPart = base
	model:SetAttribute("Cofre", info.name)
	model:SetAttribute("Premio", info.reward)
	model:SetAttribute("Corazon", info.heart == true)
	CollectionService:AddTag(model, "Cofre")
	CollectionService:AddTag(model, "Secreto") -- Chispa lo marca al escanear
	model.Parent = folder
end

-- Dónde salen las máquinas del Óxido (EnemyService)
World.enemySpots = {
	{ kind = "Rastreador", position = SCRAPYARD + Vector3.new(10, 0, -6) },
	{ kind = "Rastreador", position = SCRAPYARD + Vector3.new(-8, 0, -10) },
	{ kind = "Rastreador", position = SCRAPYARD + Vector3.new(4, 0, 14) },
	{ kind = "Escudero", position = SCRAPYARD + Vector3.new(-10, 0, 8) },
	{ kind = "Torreta", position = SCRAPYARD + Vector3.new(-22, 0, -14) },
	{ kind = "Torreta", position = SCRAPYARD + Vector3.new(18, 0, 22) },
}

-- Dónde apareces al regresar de un mundo: frente al portal de la Selva, mirando a la plaza
World.arrival = (portalFrame(1) * CFrame.new(0, 3, -14))

-- Escondites de llaves en el Nexo. Son temporales: solo se usan mientras faltan mundos
-- (KeyService). Junto a la playa y en rincones de la isla.
World.keySpots = {
	{ name = "PlayaEste", position = Vector3.new(138, GROUND, 30) },
	{ name = "TrasChatarreria", position = Vector3.new(-60, GROUND, 120) },
	{ name = "TrasPortales", position = Vector3.new(30, GROUND, -140) },
	{ name = "PlayaOeste", position = Vector3.new(-140, GROUND, 40) },
}

-- Dónde van los muñecos de práctica (los arma Dummies)
World.dummySpots = {
	Vector3.new(-16, GROUND, 92),
	Vector3.new(-6, GROUND, 104),
	Vector3.new(6, GROUND, 104),
	Vector3.new(16, GROUND, 92),
	Vector3.new(0, GROUND, 88),
}

function World.Build()
	folder = Instance.new("Folder")
	folder.Name = "PuertoEco"
	folder.Parent = workspace
	island()
	plaza()
	for i, info in PORTALS do
		portal(info, portalFrame(i))
	end
	hint("Portales", Vector3.new(0, GROUND, -70), 14)
	house(
		"Tienda",
		"Mejoras y cristales",
		Vector3.new(80, GROUND, 24),
		Vector3.new(0, GROUND, 0),
		C.roofRed,
		"Tienda"
	)
	house(
		"Taller de Chispa",
		"Mejora a Chispa",
		Vector3.new(-80, GROUND, 24),
		Vector3.new(0, GROUND, 0),
		C.roofBlue,
		"Taller"
	)
	trainingField()
	hall()
	scrapyard()
	for _, info in CHESTS do
		chest(info)
	end
	decorate()
end

return World
