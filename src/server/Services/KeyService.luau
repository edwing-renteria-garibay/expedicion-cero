-- La cacería de las 7 llaves (Config/Keys).
--
--   * Cada mundo registra sus ESCONDITES (AddSpots): lugares donde puede quedar una llave.
--   * Al arrancar, y cada vez que cambia la temporada, el servidor elige dónde va cada llave
--     con una semilla hecha del número de temporada y una clave (SALT). Mismo número = mismos
--     lugares en todos los servidores.
--   * Cada jugador toma su propia copia de cada llave (en co-op nadie se la quita a nadie); en
--     su pantalla la llave desaparece al tomarla (client/Prompts).
--   * Con las 7: es Leyenda (DataService.CompleteSeason), su nombre va al Salón de Leyendas
--     (OrderedDataStore por temporada) y todos lo ven con título y aura dorada.
--   * Chispa, al escanear, pregunta por el remote "Llaves" si hay una llave cerca: frío, tibio o
--     caliente (y hacia dónde, con el escáner del taller).
--
-- Mientras faltan mundos, las llaves también se esconden en el Nexo (escondites "temporales").
-- En Studio se escribe en Output dónde quedó cada llave, para poder probar.

local BadgeService = game:GetService("BadgeService")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Keys = require(ReplicatedStorage.Shared.Config.Keys)
local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local DataService = require(script.Parent.DataService)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent
local keyRemote = ReplicatedStorage.Remotes.Llaves :: RemoteEvent

local KeyService = {}

-- La clave de la semilla. Si tu repositorio es público, cámbiala aquí en tu copia de Studio
-- (o en el código antes de publicar) para que nadie pueda calcular dónde quedan las llaves.
local SALT = "eco-7-llaves"

-- Mundos que no cuentan como mundo de verdad: solo se usan si faltan mundos
local TEMPORARY = { Nexo = true }

type Spot = { world: string, name: string, position: Vector3 }

local spots: { Spot } = {}
local placed: { [number]: { spot: Spot, model: Model } } = {}
local season = 0
local folder: Folder

-- Salón de Leyendas de esta temporada: { { userId, name } } en orden de llegada
local legends: { { userId: number, name: string } } = {}
local hallChanged: BindableEvent = Instance.new("BindableEvent")
KeyService.HallChanged = hallChanged.Event

local lastHint: { [Player]: number } = {}
local names: { [number]: string } = {} -- nombres ya buscados (para no preguntar cada minuto)

local function hash(text: string): number
	local h = 7
	for i = 1, #text do
		h = (h * 31 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- En qué mundo está esta posición
local function worldAt(position: Vector3): string
	if Zones.Inside(Zones.Selva, position) then
		return "Selva"
	end
	return "Nexo"
end

-- Agrega los escondites de un mundo: { { name = "Arena", position = Vector3 } }
function KeyService.AddSpots(world: string, list: { { name: string, position: Vector3 } })
	for _, item in list do
		table.insert(spots, { world = world, name = item.name, position = item.position })
	end
end

-- Elige dónde va cada llave esta temporada
local function choose(forSeason: number): { Spot }
	local rng = Random.new(hash(SALT .. ":" .. forSeason))
	local byWorld: { [string]: { Spot } } = {}
	for _, spot in spots do
		byWorld[spot.world] = byWorld[spot.world] or {}
		table.insert(byWorld[spot.world], spot)
	end
	-- Siempre en el mismo orden (si no, cada servidor sacaría algo distinto)
	local real, all = {}, {}
	for world, list in byWorld do
		table.sort(list, function(a, b)
			return a.name < b.name
		end)
		table.insert(all, world)
		if not TEMPORARY[world] then
			table.insert(real, world)
		end
	end
	local worlds = if #real >= Keys.count then real else all
	table.sort(worlds)
	local function shuffle(list: { any })
		for i = #list, 2, -1 do
			local j = rng:NextInteger(1, i)
			list[i], list[j] = list[j], list[i]
		end
	end
	shuffle(worlds)
	for _, world in worlds do
		shuffle(byWorld[world])
	end
	-- Una llave por mundo, dando vueltas si hay menos mundos que llaves
	local chosen: { Spot } = {}
	local used: { [string]: number } = {}
	local i = 0
	local tries = 0
	while #chosen < Keys.count and tries < 200 do
		tries += 1
		local world = worlds[i % #worlds + 1]
		i += 1
		local list = byWorld[world]
		local next_ = (used[world] or 0) + 1
		if list[next_] then
			used[world] = next_
			table.insert(chosen, list[next_])
		end
	end
	return chosen
end

-- Una llave de caricatura: argolla, palo y dientes, del color de su número
local function buildKey(n: number, position: Vector3): Model
	local color = Keys.colors[n]
	local model = Instance.new("Model")
	model.Name = "Llave" .. n
	local function piece(name: string, size: Vector3, cframe: CFrame, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cframe
		if shape then
			p.Shape = shape
		end
		p.Color = color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = false
		p.Parent = model
		return p
	end
	local base = CFrame.new(position + Vector3.new(0, 3, 0))
	local ring =
		piece("Argolla", Vector3.new(0.5, 2.2, 2.2), base * CFrame.new(0, 1.6, 0), Enum.PartType.Cylinder)
	piece("Palo", Vector3.new(0.4, 3, 0.4), base * CFrame.new(0, -0.6, 0))
	piece("Diente", Vector3.new(0.4, 0.4, 0.9), base * CFrame.new(0, -1.7, 0.5))
	piece("Diente", Vector3.new(0.4, 0.4, 0.6), base * CFrame.new(0, -1.1, 0.35))
	model.PrimaryPart = ring
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 2
	light.Parent = ring
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.3, 0)
	sparkles.Lifetime = NumberRange.new(0.8, 1.4)
	sparkles.Rate = 6
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = ring
	model:SetAttribute("Llave", n)
	CollectionService:AddTag(model, "Llave") -- client/Hub la hace girar
	return model
end

local function onTaken(player: Player, n: number)
	local info = placed[n]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not info or not root or (root.Position - info.model:GetPivot().Position).Magnitude > 16 then
		return
	end
	local total = DataService.GiveKey(player, n, season)
	if not total then
		fx:FireClient(player, "Say", "LlaveYa")
		return
	end
	fx:FireClient(player, "Chest", info.model:GetPivot().Position, 0, false)
	if total < Keys.count then
		fx:FireClient(player, "Say", "LlaveTomada", total)
		return
	end
	-- ¡Las 7!
	if not DataService.CompleteSeason(player, season) then
		return
	end
	DataService.SaveNow(player)
	fx:FireClient(player, "Say", "Leyenda")
	for _, other in Players:GetPlayers() do
		if other ~= player then
			fx:FireClient(other, "Say", "NuevaLeyenda", player.DisplayName)
		end
	end
	table.insert(legends, { userId = player.UserId, name = player.DisplayName })
	hallChanged:Fire()
	task.spawn(function()
		local finished = os.time() - Keys.epoch + 10 ^ 8 -- siempre positivo, y menor = antes
		if not Settings.testing then
			pcall(function()
				DataStoreService:GetOrderedDataStore("LeyendasT" .. season)
					:SetAsync(tostring(player.UserId), math.floor(finished))
			end)
		end
		if Keys.badge ~= 0 then
			pcall(BadgeService.AwardBadge, BadgeService, player.UserId, Keys.badge)
		end
	end)
end

-- Pone las 7 llaves de la temporada (quita las de antes)
local function place()
	for _, info in placed do
		info.model:Destroy()
	end
	table.clear(placed)
	local chosen = choose(season)
	for n, spot in chosen do
		local model = buildKey(n, spot.position)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Tomar"
		prompt.ObjectText = "Llave " .. n
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("OcultarSi", "Llave_" .. n) -- client/Prompts
		prompt:SetAttribute("EsconderPieza", "Modelo")
		prompt.Parent = model.PrimaryPart
		prompt.Triggered:Connect(function(player)
			onTaken(player, n)
		end)
		model.Parent = folder
		placed[n] = { spot = spot, model = model }
		if Settings.testing then
			print(`[Llaves] Temporada {season}: llave {n} en {spot.world} / {spot.name}`)
		end
	end
end

-- Lee el Salón de Leyendas de esta temporada (en Studio solo lo de esta partida)
local function loadHall()
	if Settings.testing then
		return
	end
	local ok, pages = pcall(function()
		return DataStoreService:GetOrderedDataStore("LeyendasT" .. season):GetSortedAsync(true, 100)
	end)
	if not ok then
		return
	end
	local list = {}
	for _, entry in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(entry.key) or 0
		if not names[userId] then
			local nameOk, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			names[userId] = if nameOk then name else "Explorador"
		end
		table.insert(list, { userId = userId, name = names[userId] })
	end
	legends = list
	hallChanged:Fire()
end

function KeyService.Season(): number
	return season
end

-- La lista de Leyendas de esta temporada, en orden de llegada
function KeyService.Legends(): { { userId: number, name: string } }
	return legends
end

-- Escribe el tablero de la plaza y el Salón de Leyendas (World los construye)
local function updateBoards()
	local nexo = workspace:FindFirstChild("PuertoEco")
	if not nexo then
		return
	end
	local secondsLeft = math.max(0, Keys.SeasonEnd(season) - os.time())
	local days = math.ceil(secondsLeft / 86400)
	local board = nexo:FindFirstChild("Tablero")
	local text = board and board:FindFirstChild("Texto", true) :: TextLabel?
	if text then
		local left = if days > 1
			then `Faltan {days} días`
			elseif secondsLeft > 3600 then "Último día"
			else "¡Últimos minutos!"
		local count = if #legends >= 100 then "100+" else tostring(#legends)
		text.Text = `TEMPORADA {season}\nLas 7 llaves cambian de lugar\n{left}\nLeyendas: {count}`
	end
	local hall = nexo:FindFirstChild("SalonLeyendas")
	if not hall then
		return
	end
	local list = hall:FindFirstChild("Lista", true) :: TextLabel?
	if list then
		local lines = { `TEMPORADA {season}` }
		for i = 1, math.min(Keys.hallSize, #legends) do
			table.insert(lines, `{i}. {legends[i].name}`)
		end
		if #legends == 0 then
			table.insert(lines, "Todavía nadie. ¿Serás el primero?")
		end
		list.Text = table.concat(lines, "\n")
	end
	for i = 1, 3 do
		local statue = hall:FindFirstChild("Estatua" .. i)
		local label = statue and statue:FindFirstChild("Texto", true) :: TextLabel?
		if label then
			label.Text = if legends[i] then `{i}° · {legends[i].name}` else `{i}° · ¿Tú?`
		end
	end
end

-- Al entrar (o al cambiar la temporada): las llaves de otra temporada ya no cuentan
function KeyService.Sync(player: Player)
	DataService.SyncSeason(player, season)
end

-- Chispa pregunta: ¿hay una llave cerca?
local DIRECTIONS =
	{ "el este", "el sureste", "el sur", "el suroeste", "el oeste", "el noroeste", "el norte", "el noreste" }

local function hint(player: Player)
	local now = os.clock()
	if now - (lastHint[player] or 0) < 2 then
		return
	end
	lastHint[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if (player:GetAttribute("Llaves") or 0) >= Keys.count then
		fx:FireClient(player, "Say", "LlavesCompletas")
		return
	end
	local here = worldAt(root.Position)
	local best: Vector3? = nil
	local bestDistance = math.huge
	for n, info in placed do
		if info.spot.world == here and not player:GetAttribute("Llave_" .. n) then
			local offset = info.model:GetPivot().Position - root.Position
			local distance = Vector3.new(offset.X, 0, offset.Z).Magnitude
			if distance < bestDistance then
				best, bestDistance = offset, distance
			end
		end
	end
	if not best then
		fx:FireClient(player, "Say", "LlaveNinguna")
		return
	end
	-- Con el escáner del taller, Chispa también dice hacia dónde
	local where = ""
	if (player:GetAttribute("Mejora_Escaner") or 0) > 0 and bestDistance > 8 then
		local angle = math.atan2(best.Z, best.X) -- 0 = este; z positivo = sur
		local index = math.floor((angle / (math.pi / 4)) + 0.5) % 8 + 1
		where = ", hacia " .. DIRECTIONS[index]
	end
	local line = if bestDistance <= Keys.hot
		then "LlaveCaliente"
		elseif bestDistance <= Keys.warm then "LlaveTibia"
		else "LlaveFria"
	fx:FireClient(player, "Say", line, where)
end

-- El título y el aura de Leyenda (todos los ven)
local function dressLegend(player: Player, character: Model)
	local count = player:GetAttribute("Leyenda") or 0
	local head = character:FindFirstChild("Head") :: BasePart?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not head or not root then
		return
	end
	local old = head:FindFirstChild("TituloLeyenda")
	if old then
		old:Destroy()
	end
	local oldAura = root:FindFirstChild("AuraLeyenda")
	if oldAura then
		oldAura:Destroy()
	end
	if count <= 0 then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "TituloLeyenda"
	gui.Size = UDim2.fromOffset(160, 28)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 80
	gui.Parent = head
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = "★ LEYENDA" .. if count > 1 then " ×" .. count else ""
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 210, 70)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "AuraLeyenda"
	aura.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 160, 40))
	aura.LightEmission = 1
	aura.Size = NumberSequence.new(0.5, 0)
	aura.Transparency = NumberSequence.new(0.2, 1)
	aura.Lifetime = NumberRange.new(0.8, 1.2)
	aura.Rate = 14
	aura.Speed = NumberRange.new(1.5, 3)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Parent = root
end

local function watchLegend(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart", 10)
		dressLegend(player, character)
	end)
	player:GetAttributeChangedSignal("Leyenda"):Connect(function()
		if player.Character then
			dressLegend(player, player.Character)
		end
	end)
	if player.Character then
		task.spawn(dressLegend, player, player.Character)
	end
end

function KeyService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Llaves"
	folder.Parent = workspace
	season = Keys.Season()
	place()
	hallChanged.Event:Connect(updateBoards)
	updateBoards()
	task.spawn(loadHall)

	keyRemote.OnServerEvent:Connect(function(player, action)
		if action == "pista" then
			hint(player)
		end
	end)
	Players.PlayerAdded:Connect(watchLegend)
	for _, player in Players:GetPlayers() do
		watchLegend(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastHint[player] = nil
	end)

	-- Cada minuto: ¿empezó otra temporada? (y se vuelve a leer el Salón)
	task.spawn(function()
		while true do
			task.wait(60)
			local now = Keys.Season()
			if now ~= season then
				season = now
				legends = {}
				place()
				for _, player in Players:GetPlayers() do
					DataService.SyncSeason(player, season)
				end
				fx:FireAllClients("Say", "NuevaTemporada")
				hallChanged:Fire()
			end
			loadHall()
			updateBoards() -- los días que faltan
		end
	end)
end

return KeyService
