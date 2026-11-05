-- El bastón de energía en el servidor:
--   * le pone el bastón en la mano a cada personaje que aparece (todos lo ven)
--   * recibe los golpes del cliente (remote Attack), revisa que no sean demasiado seguidos y le
--     quita vida a los enemigos (etiqueta "Enemy") que estén enfrente y cerca
--   * Chispa, el dron, le dispara un rayito al enemigo que golpeaste (Config/Drone)
--   * rodar (remote Dodge): por un momento nada te hace daño (atributo "Esquivando")
--   * avisa a todos los clientes (remote Fx) para que vean el golpe, el daño y el rayito
--
-- El cliente decide CUÁNDO golpeas (para que se sienta inmediato); el servidor decide A QUIÉN
-- le pegas y cuánto, para que nadie haga trampa.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Drone = require(ReplicatedStorage.Shared.Config.Drone)
local Enemies = require(ReplicatedStorage.Shared.Config.Enemies)
local Staff = require(ReplicatedStorage.Shared.Config.Staff)
local StaffModel = require(ReplicatedStorage.Shared.StaffModel)

local Remotes = ReplicatedStorage.Remotes
local attackRemote = Remotes.Attack :: RemoteEvent
local dodgeRemote = Remotes.Dodge :: RemoteEvent
local fx = Remotes.Fx :: RemoteEvent

local StaffService = {}

-- Cuándo terminó el último golpe de cada jugador, y su último rayito y rodada
local busyUntil: { [Player]: number } = {}
local lastZap: { [Player]: number } = {}
local lastDodge: { [Player]: number } = {}

-- Un poco de tolerancia por el lag (el cliente y el servidor no ven el tiempo igual)
local LAG = 0.12

local function rootOf(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Los enemigos vivos a los que alcanza el golpe
local function targetsOf(origin: Vector3, look: Vector3, attack): { Model }
	local hits = {}
	for _, enemy in CollectionService:GetTagged("Enemy") do
		if not enemy:IsA("Model") or not enemy:IsDescendantOf(workspace) then
			continue
		end
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		local root = rootOf(enemy)
		if not humanoid or humanoid.Health <= 0 or not root then
			continue
		end
		local offset = root.Position - origin
		local flat = Vector3.new(offset.X, 0, offset.Z)
		-- Más altura de tolerancia: los muñecos y enemigos grandes tienen el centro arriba
		if flat.Magnitude > attack.range + root.Size.X / 2 or math.abs(offset.Y) > 8 then
			continue
		end
		if attack.angle > -1 and flat.Magnitude > 1 and flat.Unit:Dot(look) < attack.angle then
			continue
		end
		table.insert(hits, enemy)
	end
	return hits
end

-- ¿El escudo de un Escudero para este golpe? (de frente y sin romper la guardia)
local function blocked(enemy: Model, root: BasePart, kind: any, from: Vector3): boolean
	-- Blindado (el jefe con su armadura puesta): nada le entra
	if enemy:GetAttribute("Blindado") then
		return true
	end
	if not enemy:GetAttribute("Escudo") or Enemies.guardBreakers[kind] then
		return false
	end
	local toAttacker = from - root.Position
	toAttacker = Vector3.new(toAttacker.X, 0, toAttacker.Z)
	if toAttacker.Magnitude < 0.1 then
		return false
	end
	local facing = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	return facing.Magnitude > 0.1 and facing.Unit:Dot(toAttacker.Unit) > 0.35
end

local function damage(player: Player, enemy: Model, attack, kind: any, from: Vector3)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	local root = rootOf(enemy)
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	if blocked(enemy, root, kind, from) then
		fx:FireAllClients("Block", root.Position + (from - root.Position).Unit * 2)
		fx:FireClient(player, "Say", if enemy:GetAttribute("Blindado") then "Blindado" else "Escudo")
		return
	end
	humanoid:TakeDamage(attack.damage)
	enemy:SetAttribute("UltimoGolpe", player.UserId)
	enemy:SetAttribute("Aturdido", os.clock() + Enemies.stun)
	-- Empujón (los muñecos y torretas están fijos y no se mueven; los demás sí)
	if not root.Anchored then
		local away = root.Position - from
		away = Vector3.new(away.X, 0, away.Z)
		if away.Magnitude > 0.1 then
			root:ApplyImpulse(
				(away.Unit * attack.push + Vector3.new(0, attack.push * 0.3, 0)) * root.AssemblyMass
			)
		end
	end
	fx:FireAllClients("Hit", root.Position, attack.damage)
end

-- Chispa le dispara un rayito al enemigo (si ya se recargó)
local function droneZap(player: Player, enemy: Model)
	local now = os.clock()
	if now - (lastZap[player] or 0) < Drone.zap.cooldown then
		return
	end
	lastZap[player] = now
	task.delay(Drone.zap.delay, function()
		local root = rootOf(enemy)
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or not player.Parent then
			return
		end
		fx:FireAllClients("Zap", player, root.Position)
		if enemy:GetAttribute("Blindado") then
			return -- rebota en la armadura
		end
		humanoid:TakeDamage(Drone.zap.damage)
		fx:FireAllClients("Hit", root.Position, Drone.zap.damage)
	end)
end

local function onAttack(player: Player, kind: any, look: any)
	-- Revisar lo que mandó el cliente: el golpe existe y la dirección es válida
	local attack = Staff.attacks[kind]
	if not attack or typeof(look) ~= "Vector3" then
		return
	end
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 or look.Magnitude ~= look.Magnitude then
		return
	end
	look = look.Unit
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and rootOf(character)
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	-- Muy seguido: el cliente no espera a que termine el golpe anterior
	local now = os.clock()
	if now < (busyUntil[player] or 0) - LAG then
		return
	end
	busyUntil[player] = now + attack.duration

	-- Los demás ven el golpe (el que golpeó ya lo vio en su pantalla)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			fx:FireClient(other, "Swing", character, kind)
		end
	end

	-- El golpe pega a mitad de la animación
	task.delay(attack.duration * 0.4, function()
		if not root.Parent or humanoid.Health <= 0 then
			return
		end
		local origin = root.Position
		local hits = targetsOf(origin, look, attack)
		for _, enemy in hits do
			damage(player, enemy, attack, kind, origin)
		end
		if hits[1] then
			droneZap(player, hits[1])
		end
	end)
end

local function onDodge(player: Player)
	local now = os.clock()
	if now - (lastDodge[player] or 0) < Staff.dodge.cooldown - LAG then
		return
	end
	lastDodge[player] = now
	local character = player.Character
	if not character then
		return
	end
	character:SetAttribute("Esquivando", true)
	task.delay(Staff.dodge.invulnerable, function()
		if character.Parent and lastDodge[player] == now then
			character:SetAttribute("Esquivando", nil)
		end
	end)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			fx:FireClient(other, "Dodge", character)
		end
	end
end

-- Le pone el bastón cuando ya cargó su avatar (si no, Roblox cambia la mano y el bastón se cae)
local function onCharacter(player: Player, character: Model)
	if not player:HasAppearanceLoaded() then
		local loaded = false
		local connection = player.CharacterAppearanceLoaded:Connect(function()
			loaded = true
		end)
		local start = os.clock()
		while not loaded and os.clock() - start < 6 and character.Parent do
			task.wait(0.1)
		end
		connection:Disconnect()
	end
	if not character.Parent or character:FindFirstChild("Baston") then
		return
	end
	StaffModel.Attach(character, StaffModel.Build())
end

function StaffService.Start()
	attackRemote.OnServerEvent:Connect(onAttack)
	dodgeRemote.OnServerEvent:Connect(onDodge)
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		busyUntil[player] = nil
		lastZap[player] = nil
		lastDodge[player] = nil
	end)
end

return StaffService
