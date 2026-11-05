-- Salas privadas, como en Escuadrón Cero y Frecuencia Cero. Hay dos clases de servidor:
--   público: uno normal de Roblox, donde cae cualquiera.
--   sala privada: un servidor reservado (TeleportService:ReserveServer) solo para ti y tus
--                 amigos. Tus cristales, corazones, poderes y todo lo tuyo van contigo (se guardan antes de
--                 irte y se cargan al llegar).
--
-- Para entrar a la sala de un amigo:
--   * Con una invitación de Roblox que lleve el código (LaunchData): el servidor público donde
--     cae tu amigo lo manda a la sala.
--   * Con el código de 6 números que sale en el menú SALAS: tu amigo lo escribe en "Unirse con
--     código" desde cualquier aparato (la invitación de Roblox no cruza de PlayStation a Xbox).
--     Los códigos se guardan unas horas en MemoryStoreService y apuntan al servidor reservado.
--
-- Atributos en ReplicatedStorage (los lee el menú): "ServerKind" ("public", "private" o
-- "loading"), "RoomCode" (los 6 números) e "InviteCode" (el código de acceso, para la invitación).
--
-- Nota: en Studio no hay servidores reservados ni teletransporte: se prueba en el juego publicado.

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local DataService = require(script.Parent.DataService)

local roomRemote = ReplicatedStorage.Remotes.Room :: RemoteEvent

local COOLDOWN = 5 -- segundos entre pedidos de un mismo jugador
local CODE_LIFETIME = 6 * 60 * 60 -- lo que dura un código guardado...
local CODE_REFRESH = 30 * 60 -- ...y cada cuánto se renueva mientras la sala siga abierta

local roomCodes = MemoryStoreService:GetSortedMap("SalasExpedicionCero")

local RoomService = {}

local lastRequest: { [Player]: number } = {}

-- ¿Es un servidor reservado? (los privados de pago tienen dueño; los reservados no)
local function isReserved(): boolean
	return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

local function busy(player: Player): boolean
	local now = os.clock()
	if now - (lastRequest[player] or 0) < COOLDOWN then
		roomRemote:FireClient(player, "error", "Espera unos segundos e intenta otra vez.")
		return true
	end
	lastRequest[player] = now
	return false
end

-- Guarda sus datos y lo manda a otro servidor (accessCode = sala; nil = uno público)
local function send(player: Player, accessCode: string?, data: any): boolean
	roomRemote:FireClient(player, "teleporting")
	DataService.SaveNow(player) -- antes de irse, para que llegue con todo
	local options = Instance.new("TeleportOptions")
	if accessCode then
		options.ReservedServerAccessCode = accessCode
	end
	if data then
		options:SetTeleportData(data)
	end
	local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, { player }, options)
	if not ok then
		warn("[Salas] Falló el teletransporte:", err)
		roomRemote:FireClient(player, "error", "No se pudo cambiar de servidor. Intenta otra vez.")
	end
	return ok
end

-- Le da a esta sala un código de 6 números libre y lo renueva mientras siga abierta
local function registerRoomCode(accessCode: string)
	for _ = 1, 10 do
		local candidate = string.format("%06d", math.random(0, 999999))
		local ok, free = pcall(function()
			local wasFree = false
			roomCodes:UpdateAsync(candidate, function(current)
				if current ~= nil then
					return nil -- ocupado: no se cambia
				end
				wasFree = true
				return accessCode
			end, CODE_LIFETIME)
			return wasFree
		end)
		if ok and free then
			ReplicatedStorage:SetAttribute("RoomCode", candidate)
			task.spawn(function()
				while true do
					task.wait(CODE_REFRESH)
					pcall(roomCodes.SetAsync, roomCodes, candidate, accessCode, CODE_LIFETIME)
				end
			end)
			game:BindToClose(function()
				pcall(roomCodes.RemoveAsync, roomCodes, candidate)
			end)
			return
		elseif not ok then
			warn("[Salas] No se pudo guardar el código:", free)
			task.wait(2)
		end
	end
end

-- "Crear sala privada"
local function onCreate(player: Player)
	if busy(player) then
		return
	end
	local ok, code = pcall(TeleportService.ReserveServer, TeleportService, game.PlaceId)
	if not ok then
		warn("[Salas] No se pudo reservar un servidor:", code)
		roomRemote:FireClient(
			player,
			"error",
			"No se pudo crear la sala. En Studio no funciona: pruébalo en el juego publicado."
		)
		return
	end
	send(player, code, { room = true, code = code })
end

-- "Unirse con código"
local function onJoin(player: Player, roomCode: any)
	if busy(player) then
		return
	end
	if type(roomCode) ~= "string" or not roomCode:match("^%d%d%d%d%d%d$") then
		roomRemote:FireClient(player, "error", "El código son 6 números.")
		return
	end
	if roomCode == ReplicatedStorage:GetAttribute("RoomCode") then
		roomRemote:FireClient(player, "error", "Ya estás en esa sala.")
		return
	end
	local ok, accessCode = pcall(roomCodes.GetAsync, roomCodes, roomCode)
	if not ok then
		warn("[Salas] No se pudo leer el código:", accessCode)
		roomRemote:FireClient(player, "error", "No se pudo buscar la sala. Intenta otra vez.")
		return
	end
	if type(accessCode) ~= "string" then
		roomRemote:FireClient(player, "error", "No hay ninguna sala con ese código.")
		return
	end
	send(player, accessCode, nil)
end

-- "Salir a un servidor público"
local function onLeave(player: Player)
	if not busy(player) then
		send(player, nil, nil)
	end
end

local function onPlayerAdded(player: Player)
	local joinData = player:GetJoinData()
	if isReserved() then
		-- El primero que llega trae el código de acceso de la sala
		local data = joinData.TeleportData
		if
			ReplicatedStorage:GetAttribute("ServerKind") == "loading"
			and type(data) == "table"
			and type(data.code) == "string"
		then
			ReplicatedStorage:SetAttribute("ServerKind", "private")
			ReplicatedStorage:SetAttribute("InviteCode", data.code)
			task.spawn(registerRoomCode, data.code)
		end
		return
	end
	-- En un servidor público: ¿viene de una invitación a una sala? La trae en LaunchData
	local launch = joinData.LaunchData
	if type(launch) == "string" and launch ~= "" then
		local ok, data = pcall(HttpService.JSONDecode, HttpService, launch)
		if ok and type(data) == "table" and type(data.join) == "string" then
			task.wait(2) -- que termine de cargar sus datos antes de guardarlos para irse
			send(player, data.join, nil)
		end
	end
end

function RoomService.Start()
	ReplicatedStorage:SetAttribute("ServerKind", if isReserved() then "loading" else "public")
	roomRemote.OnServerEvent:Connect(function(player, action, ...)
		if action == "create" then
			onCreate(player)
		elseif action == "join" then
			onJoin(player, ...)
		elseif action == "leave" then
			onLeave(player)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return RoomService
