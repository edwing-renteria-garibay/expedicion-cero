-- Los corazones del jugador.
--
-- La vida del personaje es corazones × Settings.hearts.value (con 3 corazones, 60 de vida).
-- No se cura sola: solo con los corazones que sueltan las máquinas y al volver a aparecer.
-- (El script "Health" vacío de StarterCharacterScripts apaga la curación de Roblox.)
--
-- Todo el daño a jugadores pasa por HealthService.Damage: si está rodando (atributo
-- "Esquivando") no le pasa nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local DataService = require(script.Parent.DataService)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local HealthService = {}

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Pone la vida máxima según sus corazones
function HealthService.Refresh(player: Player, fill: boolean?)
	local humanoid = humanoidOf(player)
	local profile = DataService.Get(player)
	if not humanoid or not profile then
		return
	end
	local hearts = player:GetAttribute("Corazones") or profile.hearts -- incluye el del VIP
	humanoid.MaxHealth = hearts * Settings.hearts.value
	if fill then
		humanoid.Health = humanoid.MaxHealth
	end
end

-- Le quita vida. Devuelve false si no le pegó (estaba rodando o ya había caído).
function HealthService.Damage(player: Player, amount: number, from: Vector3?): boolean
	local character = player.Character
	local humanoid = humanoidOf(player)
	if not character or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if character:GetAttribute("Esquivando") then
		fx:FireClient(player, "Dodged")
		return false
	end
	humanoid:TakeDamage(amount)
	fx:FireClient(player, "Hurt", from)
	return true
end

-- ¿Le falta vida?
function HealthService.Hurt(player: Player): boolean
	local humanoid = humanoidOf(player)
	return humanoid ~= nil and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth
end

-- Cura (por ejemplo, un corazón recogido). Devuelve false si ya estaba lleno.
function HealthService.Heal(player: Player, amount: number): boolean
	local humanoid = humanoidOf(player)
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return false
	end
	humanoid.Health = math.min(humanoid.Health + amount, humanoid.MaxHealth)
	return true
end

function HealthService.Start()
	Players.RespawnTime = Settings.respawnTime
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 5)
			HealthService.Refresh(player, true)
		end)
		if player.Character then
			HealthService.Refresh(player, true)
		end
		-- Si gana un corazón, se nota al momento
		player:GetAttributeChangedSignal("Corazones"):Connect(function()
			HealthService.Refresh(player, false)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return HealthService
