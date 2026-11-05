-- El progreso de cada jugador y su guardado en un DataStore (lo que no se borra al salir).
--
--   crystals = cristales para gastar (en la tienda y el taller, más adelante)
--   hearts   = cuántos corazones tiene (empieza con Settings.hearts.start)
--   chests   = los cofres que ya abrió: { [nombre] = true }
--   powers   = los poderes del bastón que ganó: { Empuje = true }
--   cores    = los núcleos que recuperó: { Selva = true }
--
-- Cuando cambian los cristales o los corazones se ponen como atributos del jugador
-- ("Cristales", "Corazones", "Nucleos" y uno por poder, como "Empuje"), así la pantalla los ve, y en la tabla de puntos (leaderstats).
--
-- En Studio no se guarda nada (Settings.testing). En el juego publicado guarda al salir y cada
-- 2 minutos.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Shared.Config.Settings)

local DataService = {}

export type Profile = {
	crystals: number,
	hearts: number,
	chests: { [string]: boolean },
	powers: { [string]: boolean },
	cores: { [string]: boolean },
}

local profiles: { [Player]: Profile } = {}

local store: DataStore? = nil
if not Settings.testing then
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Settings.saveKey)
	end)
	if ok then
		store = result
	else
		warn("[Datos] No hay DataStore (¿juego sin publicar?). No se guardará nada.")
	end
end

local function keyOf(player: Player): string
	return "jugador_" .. player.UserId
end

local function save(player: Player)
	local profile = profiles[player]
	if not store or not profile then
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync(keyOf(player), profile)
	end)
	if not ok then
		warn("[Datos] No se pudo guardar a", player.Name, err)
	end
end

-- Pone los números en el jugador para que la pantalla los vea
local function publish(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Cristales", profile.crystals)
	player:SetAttribute("Corazones", profile.hearts)
	local cores = 0
	for _ in profile.cores do
		cores += 1
	end
	player:SetAttribute("Nucleos", cores)
	for power in profile.powers do
		player:SetAttribute(power, true)
	end
	-- Lo que ya tomó: así su pantalla esconde el aviso de "Abrir" o "Tomar" (client/Prompts)
	for chest in profile.chests do
		player:SetAttribute("Cofre_" .. chest, true)
	end
	for core in profile.cores do
		player:SetAttribute("Nucleo_" .. core, true)
	end
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cristales") :: IntValue?
	if value then
		value.Value = profile.crystals
	end
end

function DataService.Load(player: Player)
	local profile: Profile = {
		crystals = 0,
		hearts = Settings.hearts.start,
		chests = {},
		powers = {},
		cores = {},
	}
	if store then
		local ok, data = pcall(function()
			return (store :: DataStore):GetAsync(keyOf(player))
		end)
		if ok and type(data) == "table" then
			profile.crystals = math.max(0, math.floor(tonumber(data.crystals) or 0))
			profile.hearts = math.clamp(
				math.floor(tonumber(data.hearts) or Settings.hearts.start),
				Settings.hearts.start,
				Settings.hearts.max
			)
			profile.chests = if type(data.chests) == "table" then data.chests else {}
			profile.powers = if type(data.powers) == "table" then data.powers else {}
			profile.cores = if type(data.cores) == "table" then data.cores else {}
		elseif not ok then
			warn("[Datos] No se pudo leer a", player.Name, data)
		end
	end
	profiles[player] = profile

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local crystals = Instance.new("IntValue")
	crystals.Name = "Cristales"
	crystals.Parent = stats
	stats.Parent = player
	publish(player)
end

function DataService.Get(player: Player): Profile?
	return profiles[player]
end

function DataService.AddCrystals(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.crystals = math.max(0, profile.crystals + amount)
	publish(player)
end

-- Un corazón más (hasta el máximo). Devuelve true si se pudo.
function DataService.AddHeart(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.hearts >= Settings.hearts.max then
		return false
	end
	profile.hearts += 1
	publish(player)
	return true
end

function DataService.OpenChest(player: Player, name: string): boolean
	local profile = profiles[player]
	if not profile or profile.chests[name] then
		return false
	end
	profile.chests[name] = true
	publish(player)
	return true
end

-- Le da un poder del bastón (por ejemplo, "Empuje"). Devuelve false si ya lo tenía.
function DataService.GivePower(player: Player, power: string): boolean
	local profile = profiles[player]
	if not profile or profile.powers[power] then
		return false
	end
	profile.powers[power] = true
	publish(player)
	return true
end

-- Guarda un núcleo recuperado (por ejemplo, "Selva"). Devuelve false si ya lo tenía.
function DataService.GiveCore(player: Player, core: string): boolean
	local profile = profiles[player]
	if not profile or profile.cores[core] then
		return false
	end
	profile.cores[core] = true
	publish(player)
	return true
end

function DataService.Release(player: Player)
	save(player)
	profiles[player] = nil
end

function DataService.Start()
	Players.PlayerRemoving:Connect(DataService.Release)
	-- Guarda a todos cada 2 minutos (por si el servidor se cae)
	task.spawn(function()
		while true do
			task.wait(120)
			for player in profiles do
				task.spawn(save, player)
			end
		end
	end)
	game:BindToClose(function()
		for player in profiles do
			save(player)
		end
	end)
end

return DataService
