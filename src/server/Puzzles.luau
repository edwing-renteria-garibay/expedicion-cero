-- Las piezas de los puzzles de las mazmorras (las pone cada zona, por ejemplo Zones/Selva):
--
--   Puerta     (etiqueta "Puerta", atributo Id): se hunde en el piso al abrirse.
--   Placa      (etiqueta "Placa", atributo Puerta = Id de la puerta): se aprieta si hay un
--              jugador o un bloque encima. Con el atributo Tiempo, la puerta se queda abierta
--              esos segundos después de apretarla; sin él, solo mientras algo la aprieta.
--   Bloque     (etiqueta "Empujable"): el Empuje lo mueve un paso, como en un tablero.
--   Agrietado  (etiqueta "Agrietado"): una pared que el Empuje rompe.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Powers = require(ReplicatedStorage.Shared.Config.Powers)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent

local Puzzles = {}

local PLATE_UP = Color3.fromRGB(240, 200, 70)
local PLATE_DOWN = Color3.fromRGB(90, 220, 110)

-- Cuándo se cierra cada puerta con tiempo
local closeAt: { [string]: number } = {}

local function doorsWith(id: string): { BasePart }
	local found = {}
	for _, door in CollectionService:GetTagged("Puerta") do
		if door:IsA("BasePart") and door:GetAttribute("Id") == id then
			table.insert(found, door)
		end
	end
	return found
end

-- Abre o cierra todas las puertas con este Id
function Puzzles.SetDoor(id: string, open: boolean)
	for _, door in doorsWith(id) do
		if door:GetAttribute("Abierta") == open then
			continue
		end
		door:SetAttribute("Abierta", open)
		local closed = door:GetAttribute("Cerrada") :: CFrame?
		if not closed then
			closed = door.CFrame
			door:SetAttribute("Cerrada", closed)
		end
		local goal = if open
			then (closed :: CFrame) - Vector3.new(0, door.Size.Y + 0.5, 0)
			else closed :: CFrame
		door.CanCollide = not open
		TweenService:Create(door, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { CFrame = goal }):Play()
		fx:FireAllClients("Door", (closed :: CFrame).Position, open)
	end
end

-- ¿Hay un jugador o un bloque sobre la placa?
local function pressed(plate: BasePart): boolean
	local function onTop(position: Vector3, margin: number): boolean
		local localPos = plate.CFrame:PointToObjectSpace(position)
		return math.abs(localPos.X) <= plate.Size.X / 2 + margin
			and math.abs(localPos.Z) <= plate.Size.Z / 2 + margin
			and localPos.Y > -1
			and localPos.Y < 7
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and humanoid and humanoid.Health > 0 and onTop(root.Position, 0.5) then
			return true
		end
	end
	for _, block in CollectionService:GetTagged("Empujable") do
		if block:IsA("BasePart") and onTop(block.Position, -1) then
			return true
		end
	end
	return false
end

local function checkPlates()
	local now = os.clock()
	local wanted: { [string]: boolean } = {}
	for _, plate in CollectionService:GetTagged("Placa") do
		local id = plate:GetAttribute("Puerta")
		if not plate:IsA("BasePart") or typeof(id) ~= "string" then
			continue
		end
		local down = pressed(plate)
		plate.Color = if down then PLATE_DOWN else PLATE_UP
		local seconds = plate:GetAttribute("Tiempo")
		if down then
			wanted[id] = true
			if typeof(seconds) == "number" then
				closeAt[id] = now + seconds
			end
		elseif closeAt[id] and now < closeAt[id] then
			wanted[id] = true -- todavía le queda tiempo
		elseif wanted[id] == nil then
			wanted[id] = false
		end
	end
	for id, open in wanted do
		Puzzles.SetDoor(id, open)
	end
end

-- Empuja un bloque un paso en la dirección (se acomoda al eje más cercano: norte, sur, este
-- u oeste). Devuelve true si se movió.
function Puzzles.Push(block: BasePart, direction: Vector3): boolean
	if block:GetAttribute("Moviendo") then
		return false
	end
	local axis
	if math.abs(direction.X) > math.abs(direction.Z) then
		axis = Vector3.new(math.sign(direction.X), 0, 0)
	else
		axis = Vector3.new(0, 0, math.sign(direction.Z))
	end
	local goal = block.Position + axis * Powers.Empuje.step
	-- ¿Hay algo en el camino? (paredes, otros bloques, puertas)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { block, workspace.Terrain }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	for _, plate in CollectionService:GetTagged("Placa") do
		table.insert(ignore, plate)
	end
	params.FilterDescendantsInstances = ignore
	local middle = CFrame.new((block.Position + goal) / 2)
	local size = Vector3.new(
		block.Size.X * 0.9 + math.abs(axis.X) * Powers.Empuje.step,
		block.Size.Y * 0.8,
		block.Size.Z * 0.9 + math.abs(axis.Z) * Powers.Empuje.step
	)
	local hits = workspace:GetPartBoundsInBox(middle + Vector3.new(0, 0.6, 0), size, params)
	for _, hit in hits do
		if hit.CanCollide and hit.Name ~= "Piso" then
			fx:FireAllClients("Block", block.Position)
			return false
		end
	end
	block:SetAttribute("Moviendo", true)
	local tween = TweenService:Create(block, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Position = goal })
	tween:Play()
	tween.Completed:Once(function()
		block:SetAttribute("Moviendo", nil)
	end)
	fx:FireAllClients("Slide", block.Position)
	return true
end

-- Rompe una pared agrietada
function Puzzles.Crack(wall: BasePart)
	fx:FireAllClients("Break", wall.Position, wall.Color, 2)
	wall:Destroy()
end

function Puzzles.Start()
	task.spawn(function()
		while true do
			task.wait(0.2)
			checkPlates()
		end
	end)
end

return Puzzles
