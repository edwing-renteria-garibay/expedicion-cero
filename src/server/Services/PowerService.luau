-- Los poderes del bastón en el servidor (Config/Powers). Por ahora, el Empuje.
--
-- El cliente avisa con el remote Power ("Empuje", dirección). El servidor revisa que tengas el
-- poder (atributo del jugador) y que no lo uses demasiado seguido, y luego, hacia enfrente:
--   * empuja y aturde a las máquinas (y le quita un poco de vida)
--   * al jefe le pone el atributo "Empujado" (el jefe decide si se cae)
--   * mueve el bloque más cercano un paso y rompe las paredes agrietadas (Puzzles)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Powers = require(ReplicatedStorage.Shared.Config.Powers)
local Puzzles = require(script.Parent.Parent.Puzzles)

local Remotes = ReplicatedStorage.Remotes
local powerRemote = Remotes.Power :: RemoteEvent
local fx = Remotes.Fx :: RemoteEvent

local PowerService = {}

local last: { [Player]: number } = {}

-- ¿Está dentro de la onda? (cerca y enfrente)
local function inWave(origin: Vector3, look: Vector3, position: Vector3, extra: number): boolean
	local info = Powers.Empuje
	local offset = position - origin
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude > info.range + extra or math.abs(offset.Y) > 10 then
		return false
	end
	return flat.Magnitude < 1 or flat.Unit:Dot(look) >= info.angle
end

local function push(player: Player, origin: Vector3, look: Vector3)
	local info = Powers.Empuje
	-- Máquinas y jefe
	for _, enemy in CollectionService:GetTagged("Enemy") do
		local root = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		if not enemy:IsA("Model") or not root or not humanoid or humanoid.Health <= 0 then
			continue
		end
		if not inWave(origin, look, root.Position, root.Size.X / 2) then
			continue
		end
		if enemy:GetAttribute("Jefe") then
			enemy:SetAttribute("Empujado", os.clock())
			continue
		end
		if enemy:GetAttribute("Muneco") then
			humanoid:TakeDamage(info.damage)
			fx:FireAllClients("Hit", root.Position, info.damage)
			continue
		end
		humanoid:TakeDamage(info.damage)
		enemy:SetAttribute("Aturdido", os.clock() + info.stun)
		enemy:SetAttribute("UltimoGolpe", player.UserId)
		if not root.Anchored then
			root:ApplyImpulse((look * info.push + Vector3.new(0, info.push * 0.4, 0)) * root.AssemblyMass)
		end
		fx:FireAllClients("Hit", root.Position, info.damage)
	end
	-- El bloque más cercano en la onda
	local nearest, nearestDistance = nil, math.huge
	for _, block in CollectionService:GetTagged("Empujable") do
		if block:IsA("BasePart") and inWave(origin, look, block.Position, block.Size.X / 2) then
			local distance = (block.Position - origin).Magnitude
			if distance < nearestDistance then
				nearest, nearestDistance = block, distance
			end
		end
	end
	if nearest then
		Puzzles.Push(nearest, look)
	end
	-- Paredes agrietadas
	for _, wall in CollectionService:GetTagged("Agrietado") do
		if
			wall:IsA("BasePart")
			and inWave(origin, look, wall.Position, math.max(wall.Size.X, wall.Size.Z) / 2)
		then
			Puzzles.Crack(wall)
		end
	end
end

local function onPower(player: Player, name: any, look: any)
	if name ~= "Empuje" or typeof(look) ~= "Vector3" or not player:GetAttribute("Empuje") then
		return
	end
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 or look.Magnitude ~= look.Magnitude then
		return
	end
	look = look.Unit
	local now = os.clock()
	if now - (last[player] or 0) < Powers.Empuje.cooldown - 0.12 then
		return
	end
	last[player] = now
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	-- Todos ven la onda; los demás, además, la animación
	fx:FireAllClients("Wave", root.Position, look)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			fx:FireClient(other, "Swing", character, "Empuje")
		end
	end
	task.delay(Powers.Empuje.duration * 0.35, function()
		if root.Parent then
			push(player, root.Position, look)
		end
	end)
end

function PowerService.Start()
	powerRemote.OnServerEvent:Connect(onPower)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
end

return PowerService
