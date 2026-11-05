-- Arma Puerto Eco, la isla central, cuando arranca el servidor:
--   * el mar y la isla (con Terrain: arena en la orilla y pasto arriba)
--   * la plaza con el pedestal vacío de los cuatro núcleos y el punto de aparición
--   * los cuatro portales al norte (todavía apagados)
--   * la tienda (este) y el taller de Chispa (oeste), cerrados por ahora
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

-- Los cuatro portales: nombre, color y la frase de Chispa
local PORTALS = {
	{ key = "Selva", name = "Selva Brumosa", color = Color3.fromRGB(80, 220, 110), x = -75 },
	{ key = "Volcan", name = "Volcán Brasa", color = Color3.fromRGB(255, 120, 40), x = -25 },
	{ key = "Glaciar", name = "Glaciar Silencio", color = Color3.fromRGB(120, 220, 255), x = 25 },
	{ key = "Ruinas", name = "Ruinas del Cielo", color = Color3.fromRGB(190, 120, 255), x = 75 },
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

-- La plaza del centro: piso de piedra, el pedestal sin núcleos y donde apareces
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
	sign(base, "Núcleos de Eco", "0 de 4", C.core)
	-- Cuatro huecos vacíos donde iban los núcleos (se encienden al recuperarlos)
	for i = 0, 3 do
		local angle = math.rad(45 + i * 90)
		local p = part({
			Name = "Hueco" .. (i + 1),
			Size = Vector3.new(1.6, 4, 1.6),
			CFrame = CFrame.new(math.cos(angle) * 4.5, GROUND + 5.3, math.sin(angle) * 4.5)
				* CFrame.Angles(0, angle, math.rad(45)),
			Color = Color3.fromRGB(70, 74, 82),
			Material = Enum.Material.Glass,
			Transparency = 0.3,
		})
		p:SetAttribute("Nucleo", i + 1)
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
	path(Vector3.new(0, y, -32), Vector3.new(0, y, -86)) -- a los portales
	path(Vector3.new(32, y, 0), Vector3.new(66, y, 20)) -- a la tienda
	path(Vector3.new(-32, y, 0), Vector3.new(-66, y, 20)) -- al taller
	path(Vector3.new(0, y, 32), Vector3.new(0, y, 78)) -- al campo de práctica
end

-- Un portal apagado: dos columnas, un arco y un disco de luz débil
local function portal(info, z: number)
	local x = info.x
	local model = Instance.new("Model")
	model.Name = "Portal" .. info.key
	model.Parent = folder
	-- Escalón
	part({
		Name = "Escalon",
		Size = Vector3.new(22, 1.4, 10),
		Position = Vector3.new(x, GROUND + 0.5, z),
		Color = C.stoneDark,
		Parent = model,
	})
	for _, side in { -1, 1 } do
		part({
			Name = "Columna",
			Size = Vector3.new(3, 18, 3),
			Position = Vector3.new(x + side * 8, GROUND + 10, z),
			Color = C.stone,
			Parent = model,
		})
		-- Un cristal del color de la isla en la punta
		part({
			Name = "Cristal",
			Size = Vector3.new(1.6, 3, 1.6),
			CFrame = CFrame.new(x + side * 8, GROUND + 21, z) * CFrame.Angles(0, math.rad(45), 0),
			Color = info.color,
			Material = Enum.Material.Neon,
		})
	end
	local arch = part({
		Name = "Arco",
		Size = Vector3.new(20, 3, 3.4),
		Position = Vector3.new(x, GROUND + 19.5, z),
		Color = C.stone,
		Parent = model,
	})
	sign(arch, info.name, "Sin energía", info.color)
	part({
		Name = "Luz",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 13, 13),
		CFrame = CFrame.new(x, GROUND + 9, z) * CFrame.Angles(0, math.rad(90), 0),
		Color = info.color,
		Material = Enum.Material.Neon,
		Transparency = 0.75,
		CanCollide = true, -- todavía no se puede pasar
		Parent = model,
	})
	hint(info.key, Vector3.new(x, GROUND, z + 8), 11)
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
	-- Puerta de madera cerrada
	part({
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
		if p.Z < -70 and math.abs(p.X) < 100 then
			return false -- portales
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
	local z = -100
	for _, info in PORTALS do
		portal(info, z)
	end
	hint("Portales", Vector3.new(0, GROUND, -80), 14)
	house(
		"Tienda",
		"Próximamente",
		Vector3.new(80, GROUND, 24),
		Vector3.new(0, GROUND, 0),
		C.roofRed,
		"Tienda"
	)
	house(
		"Taller de Chispa",
		"Próximamente",
		Vector3.new(-80, GROUND, 24),
		Vector3.new(0, GROUND, 0),
		C.roofBlue,
		"Taller"
	)
	trainingField()
	decorate()
end

return World
