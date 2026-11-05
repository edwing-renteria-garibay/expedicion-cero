-- Lo que sueltan las máquinas al romperse: cristales (azules) y corazones (rojos).
--
-- Salen volando un poco, caen al piso y se quedan girando. Si pasas cerca, se van hacia ti
-- solos (imán) y se recogen. Los corazones solo se recogen si te falta vida. Desaparecen al
-- minuto si nadie los toma.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Settings = require(ReplicatedStorage.Shared.Config.Settings)
local Shop = require(ReplicatedStorage.Shared.Config.Shop)
local DataService = require(script.Parent.Services.DataService)
local HealthService = require(script.Parent.Services.HealthService)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local Pickups = {}

local MAGNET = 12 -- a esta distancia se van hacia ti
local GRAB = 3 -- a esta distancia se recogen
local LIFETIME = 60

type Pickup = {
	part: BasePart,
	kind: string,
	born: number,
	velocity: Vector3,
	resting: boolean,
}

local active: { Pickup } = {}
local folder: Folder

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function make(kind: string, position: Vector3)
	local p = Instance.new("Part")
	p.Name = kind
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	if kind == "Cristal" then
		p.Size = Vector3.new(0.7, 1.2, 0.7)
		p.Color = Color3.fromRGB(110, 230, 255)
	else
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * 1.3
		p.Color = Color3.fromRGB(255, 70, 90)
		local light = Instance.new("PointLight")
		light.Color = p.Color
		light.Range = 6
		light.Parent = p
	end
	p.Position = position
	p.Parent = folder
	local angle = math.random() * math.pi * 2
	table.insert(active, {
		part = p,
		kind = kind,
		born = os.clock(),
		velocity = Vector3.new(math.cos(angle) * 8, 18, math.sin(angle) * 8),
		resting = false,
	})
end

-- Suelta cristales y, a veces, un corazón
function Pickups.Drop(position: Vector3, crystals: number, heart: boolean)
	for _ = 1, crystals do
		make("Cristal", position)
	end
	if heart then
		make("Corazon", position)
	end
end

local function nearestPlayer(position: Vector3, range: number): (Player?, BasePart?)
	local best, bestRoot, bestDistance = nil, nil, math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid and humanoid.Health > 0 and root then
			local distance = (root.Position - position).Magnitude
			-- El imán del taller de Chispa los atrae desde más lejos
			local reach = range + Shop.items.Iman.magnetBonus * (player:GetAttribute("Mejora_Iman") or 0)
			if distance < reach and distance < bestDistance then
				best, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return best, bestRoot
end

local function collect(pickup: Pickup, player: Player): boolean
	if pickup.kind == "Cristal" then
		DataService.AddCrystals(player, 1)
		fx:FireClient(player, "Crystal")
		return true
	end
	if HealthService.Heal(player, Settings.hearts.value) then
		fx:FireClient(player, "Heart")
		return true
	end
	return false -- con la vida llena el corazón se queda ahí
end

local function step(dt: number)
	local now = os.clock()
	for i = #active, 1, -1 do
		local pickup = active[i]
		local p = pickup.part
		if now - pickup.born > LIFETIME or not p.Parent then
			p:Destroy()
			table.remove(active, i)
			continue
		end
		-- Primero vuela y cae al piso
		if not pickup.resting then
			pickup.velocity += Vector3.new(0, -60 * dt, 0)
			local move = pickup.velocity * dt
			rayParams.FilterDescendantsInstances = { folder }
			local hit = workspace:Raycast(p.Position, move + Vector3.new(0, -0.6, 0), rayParams)
			if hit and pickup.velocity.Y < 0 then
				p.Position = hit.Position + Vector3.new(0, 1, 0)
				pickup.resting = true
			else
				p.Position += move
			end
		end
		-- Gira (y después de medio segundo, el imán)
		p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, now * 3, 0)
		if now - pickup.born < 0.5 then
			continue
		end
		local player, root = nearestPlayer(p.Position, MAGNET)
		if player and root then
			local offset = root.Position - p.Position
			if offset.Magnitude <= GRAB then
				if collect(pickup, player) then
					p:Destroy()
					table.remove(active, i)
				end
			elseif pickup.kind == "Cristal" or HealthService.Hurt(player) then
				pickup.resting = true
				p.Position += offset.Unit * math.min(offset.Magnitude, 40 * dt)
			end
		end
	end
end

function Pickups.Start()
	folder = Instance.new("Folder")
	folder.Name = "Recogibles"
	folder.Parent = workspace
	RunService.Heartbeat:Connect(step)
end

return Pickups
