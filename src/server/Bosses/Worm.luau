-- El jefe de la Selva Brumosa: el Gusano de chatarra gigante.
--
-- Cómo pelea (se repite):
--   1. Bajo tierra: sale un círculo de tierra donde va a salir (¡quítate!).
--   2. Sale de golpe; si estabas encima, te pega.
--   3. Arriba: te mira, su ojo se pone rojo y se lanza contra ti (2 veces). Desde la mitad de
--      su vida, entre lanzada y lanzada escupe una bola de óxido.
--   4. Se vuelve a meter y sale en otro lado.
--
-- Su armadura (atributo "Blindado") aguanta el bastón. Mientras está arriba, dale un Empuje
-- (E): se cae al piso aturdido y SIN armadura unos segundos. ¡Ahí pégale con todo!
--
-- Tiene la etiqueta "Enemy" y un Humanoid para la vida, como las otras máquinas. Todas sus
-- piezas son fijas (Anchored): el servidor las mueve cuadro por cuadro.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EnemyService = require(script.Parent.Parent.Services.EnemyService)
local HealthService = require(script.Parent.Parent.Services.HealthService)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local Worm = {}

local HEALTH = 360
local SEGMENTS = 7
local RUST = Color3.fromRGB(176, 92, 48)
local DARK = Color3.fromRGB(110, 70, 50)
local EYE = Color3.fromRGB(255, 200, 80)
local ANGRY = Color3.fromRGB(255, 40, 40)

-- Qué tan rápido hace todo según su vida (fase 1, 2 y 3)
local PHASES = {
	{ windup = 0.9, up = 5.5, lunges = 2, spit = false },
	{ windup = 0.75, up = 5, lunges = 2, spit = true },
	{ windup = 0.6, up = 4.5, lunges = 3, spit = true },
}

local BALL = { projectileSpeed = 45, reach = 70, damage = 10 }

local function piece(
	parent: Instance,
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.CorrodedMetal
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Parent = parent
	return p
end

-- Arma al gusano en la arena. onDefeated se llama cuando lo rompen (con la posición).
-- Devuelve el modelo.
function Worm.Build(center: Vector3, radius: number, parent: Instance, onDefeated: (Vector3) -> ()): Model
	local model = Instance.new("Model")
	model.Name = "Gusano de chatarra"
	local head = piece(model, "HumanoidRootPart", Vector3.new(8, 8, 9), RUST)
	head.CanQuery = true
	model.PrimaryPart = head
	local jaw = piece(model, "Mandibula", Vector3.new(7, 2, 5), DARK, Enum.Material.Metal)
	local eye = piece(model, "Ojo", Vector3.new(4, 1.4, 0.4), EYE, Enum.Material.Neon)
	local armor = piece(
		model,
		"Armadura",
		Vector3.new(9, 2.4, 9.6),
		Color3.fromRGB(120, 124, 132),
		Enum.Material.DiamondPlate
	)
	local segments: { BasePart } = {}
	for i = 1, SEGMENTS do
		local size = 7.5 - i * 0.5
		local segment = piece(
			model,
			"Segmento",
			Vector3.one * size,
			if i % 2 == 0 then RUST else DARK,
			nil,
			Enum.PartType.Ball
		)
		table.insert(segments, segment)
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = HEALTH
	humanoid.Health = HEALTH
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model
	model:SetAttribute("Jefe", "Gusano de chatarra")
	model:SetAttribute("Blindado", true)

	local ground = center.Y
	local hidden = ground - 16
	-- Dónde está la cabeza y hacia dónde mira; el cuerpo baja detrás de ella hasta el piso
	local headCFrame = CFrame.new(center.X, hidden, center.Z)
	local tilt = 0 -- 0 = parado, 1 = tirado en el piso (aturdido)

	local function place()
		local frame = headCFrame * CFrame.Angles(math.rad(-70 * tilt), 0, 0)
		head.CFrame = frame
		jaw.CFrame = frame * CFrame.new(0, -3.4, -1.6)
		eye.CFrame = frame * CFrame.new(0, 1, -4.6)
		armor.CFrame = frame * CFrame.new(0, 4.6, 0)
		local back = -frame.LookVector
		for i, segment in segments do
			local along = headCFrame.Position + back * (i * 1.4) + Vector3.new(0, -i * 4.6 * (1 - tilt), 0)
			if tilt > 0 then
				along += back * (i * 4.4 * tilt)
			end
			segment.CFrame = CFrame.new(along)
		end
	end
	place()
	CollectionService:AddTag(model, "Enemy")
	model.Parent = parent

	local alive = true
	local state = "bajo"
	local stunnedUntil = 0

	-- Mueve la cabeza a una posición en "seconds" segundos (cuadro por cuadro)
	local function moveHead(goal: CFrame, seconds: number)
		local start = headCFrame
		local began = os.clock()
		while alive do
			local t = math.min((os.clock() - began) / seconds, 1)
			local eased = 1 - (1 - t) * (1 - t)
			headCFrame = start:Lerp(goal, eased)
			place()
			if t >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end

	local function setTilt(goal: number, seconds: number)
		local start = tilt
		local began = os.clock()
		while alive do
			local t = math.min((os.clock() - began) / seconds, 1)
			tilt = start + (goal - start) * t
			place()
			if t >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end

	-- Los jugadores vivos dentro de la arena
	local function fighters(): { BasePart }
		local list = {}
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local hum = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and hum and hum.Health > 0 then
				local offset = root.Position - center
				if Vector3.new(offset.X, 0, offset.Z).Magnitude < radius + 6 and math.abs(offset.Y) < 20 then
					table.insert(list, root)
				end
			end
		end
		return list
	end

	-- Le pega a los jugadores a menos de "distance" de este punto
	local function hurtAround(position: Vector3, distance: number, amount: number)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local offset = root.Position - position
				if Vector3.new(offset.X, 0, offset.Z).Magnitude < distance and math.abs(offset.Y) < 10 then
					HealthService.Damage(player, amount, position)
				end
			end
		end
	end

	local function phase(): typeof(PHASES[1])
		local ratio = humanoid.Health / humanoid.MaxHealth
		return if ratio > 0.66 then PHASES[1] elseif ratio > 0.33 then PHASES[2] else PHASES[3]
	end

	local function setArmor(on: boolean)
		model:SetAttribute("Blindado", on)
		armor.Transparency = if on then 0 else 1
		eye.Color = if on then EYE else Color3.fromRGB(120, 120, 130)
	end

	-- El Empuje lo tumba (solo si está arriba y con la armadura)
	model:GetAttributeChangedSignal("Empujado"):Connect(function()
		if state == "arriba" and model:GetAttribute("Blindado") then
			state = "aturdido"
			stunnedUntil = os.clock() + 4.5
			setArmor(false)
			fx:FireAllClients("Break", armor.Position, Color3.fromRGB(120, 124, 132), 1.5)
			fx:FireAllClients("Say", "JefeTumbado")
		end
	end)

	-- Un ataque desde arriba: avisa con el ojo y se lanza hacia el jugador
	local function lunge(target: BasePart, windup: number)
		local origin = headCFrame
		local flat = Vector3.new(target.Position.X, origin.Position.Y, target.Position.Z)
		if (flat - origin.Position).Magnitude > 0.5 then
			headCFrame = CFrame.lookAt(origin.Position, flat)
			origin = headCFrame
			place()
		end
		eye.Color = ANGRY
		local waitUntil = os.clock() + windup
		while alive and os.clock() < waitUntil and state == "arriba" do
			RunService.Heartbeat:Wait()
		end
		if state ~= "arriba" then
			return
		end
		eye.Color = EYE
		local strike = target.Position
		local direction = Vector3.new(strike.X - origin.X, 0, strike.Z - origin.Z)
		if direction.Magnitude > 22 then
			strike = origin.Position + direction.Unit * 22
		end
		local goal = CFrame.lookAt(
			Vector3.new(strike.X, ground + 5, strike.Z),
			Vector3.new(strike.X, ground + 5, strike.Z) + direction
		)
		moveHead(goal, 0.25)
		hurtAround(goal.Position, 7, 20)
		fx:FireAllClients("Slam", goal.Position - Vector3.new(0, 4, 0))
		task.wait(0.35)
		if state == "arriba" then
			moveHead(origin, 0.45)
		end
	end

	local function spit(target: BasePart)
		if state ~= "arriba" then
			return
		end
		local from = (headCFrame * CFrame.new(0, -1.5, -5)).Position
		local direction = target.Position - from
		if direction.Magnitude > 0.1 then
			EnemyService.FireBall(model, from, direction.Unit, BALL)
		end
	end

	task.spawn(function()
		while alive and model.Parent do
			local list = fighters()
			if #list == 0 then
				task.wait(0.5)
				continue
			end
			local p = phase()
			-- 1. Elige dónde salir: cerca de alguien, dentro de la arena
			local target = list[math.random(1, #list)]
			local offset = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 10
			local spot = Vector3.new(target.Position.X, ground, target.Position.Z) + offset
			local fromCenter = Vector3.new(spot.X - center.X, 0, spot.Z - center.Z)
			if fromCenter.Magnitude > radius - 8 then
				spot = center + fromCenter.Unit * (radius - 8)
			end
			fx:FireAllClients("Burrow", spot, 1.2)
			task.wait(1.2)
			if not alive then
				break
			end
			-- 2. Sale de golpe
			headCFrame = CFrame.new(spot.X, hidden, spot.Z)
			state = "subiendo"
			moveHead(CFrame.new(spot.X, ground + 12, spot.Z), 0.45)
			hurtAround(spot, 7, 20)
			fx:FireAllClients("Slam", spot)
			state = "arriba"
			-- 3. Arriba: lanzadas (y escupitajos)
			local upUntil = os.clock() + p.up
			local count = 0
			while alive and state == "arriba" and count < p.lunges and os.clock() < upUntil do
				local now = fighters()
				if #now == 0 then
					break
				end
				local closest, best = nil, math.huge
				for _, root in now do
					local d = (root.Position - headCFrame.Position).Magnitude
					if d < best then
						closest, best = root, d
					end
				end
				lunge(closest :: BasePart, p.windup)
				count += 1
				if p.spit and state == "arriba" then
					task.wait(0.3)
					spit(closest :: BasePart)
				end
				task.wait(0.5)
			end
			-- Si lo tumbaron: se queda en el piso sin armadura
			if alive and state == "aturdido" then
				local look = headCFrame.LookVector
				local low = Vector3.new(headCFrame.X, ground + 5, headCFrame.Z)
				moveHead(CFrame.lookAt(low, low + Vector3.new(look.X, 0, look.Z)), 0.3)
				setTilt(1, 0.4)
				fx:FireAllClients("Slam", headCFrame.Position - Vector3.new(0, 6, 0))
				while alive and os.clock() < stunnedUntil do
					task.wait(0.1)
				end
				if not alive then
					break
				end
				setTilt(0, 0.5)
				setArmor(true)
			end
			-- 4. Se mete otra vez
			state = "bajando"
			moveHead(CFrame.new(headCFrame.X, hidden, headCFrame.Z), 0.6)
			state = "bajo"
			task.wait(0.4)
		end
	end)

	humanoid.Died:Once(function()
		alive = false
		CollectionService:RemoveTag(model, "Enemy")
		local position = head.Position
		for i, segment in segments do
			task.delay(i * 0.12, function()
				fx:FireAllClients("Break", segment.Position, RUST, 2.5)
				segment:Destroy()
			end)
		end
		fx:FireAllClients("Break", position, RUST, 3)
		TweenService:Create(head, TweenInfo.new(1), { Transparency = 1 }):Play()
		task.delay(1.2, function()
			model:Destroy()
		end)
		onDefeated(Vector3.new(center.X, ground, center.Z))
	end)

	return model
end

return Worm
