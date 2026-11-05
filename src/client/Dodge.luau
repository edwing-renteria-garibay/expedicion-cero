-- Rodar y correr (Shift, o Círculo / B en control, o el botón Rodar en celular):
--   * al apretar, una rodada rápida hacia donde caminas (o hacia adelante si estás quieto).
--     Mientras ruedas nada te hace daño (el servidor lo marca con el atributo "Esquivando").
--   * si lo DEJAS apretado, al terminar la rodada sigues corriendo hasta que lo sueltes.
-- Velocidades, duración y espera en Config/Staff (dodge).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Staff = require(ReplicatedStorage.Shared.Config.Staff)
local Actions = require(script.Parent.Actions)
local LockOn = require(script.Parent.LockOn)
local Sfx = require(script.Parent.Sfx)
local Swing = require(script.Parent.Swing)

local dodgeRemote = ReplicatedStorage.Remotes.Dodge :: RemoteEvent
local player = Players.LocalPlayer

local Dodge = {}

local last = 0
local held = false -- Shift sigue apretado
local normalSpeed: number? = nil

-- Correr mientras Shift siga apretado
local function setRunning(on: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	normalSpeed = normalSpeed or humanoid.WalkSpeed
	humanoid.WalkSpeed = if on then Staff.dodge.runSpeed else normalSpeed :: number
end

local function roll(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return false
	end
	local now = os.clock()
	if now - last < Staff.dodge.cooldown or humanoid.FloorMaterial == Enum.Material.Air then
		return false
	end
	last = now

	local direction = humanoid.MoveDirection
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	direction = direction.Unit

	-- Empujón constante durante la rodada (solo de lado, la gravedad sigue igual)
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local push = Instance.new("LinearVelocity")
	push.Attachment0 = attachment
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	push.PrimaryTangentAxis = Vector3.xAxis
	push.SecondaryTangentAxis = Vector3.zAxis
	push.PlaneVelocity = Vector2.new(direction.X, direction.Z) * Staff.dodge.speed
	push.MaxForce = 1e6
	push.Parent = root

	-- Si no tienes a nadie fijado, ruedas mirando hacia donde vas
	LockOn.hold = true
	humanoid.AutoRotate = false
	if not LockOn.Target() then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
	end

	dodgeRemote:FireServer()
	Swing.Roll(character)
	Sfx.Play("dodge", root)

	task.delay(Staff.dodge.duration, function()
		push:Destroy()
		attachment:Destroy()
		LockOn.hold = false
		humanoid.AutoRotate = LockOn.Target() == nil
		if held then
			setRunning(true)
		end
	end)
	return true
end

function Dodge.Start()
	player.CharacterAdded:Connect(function()
		normalSpeed = nil
		held = false
	end)
	Actions.Bind("Rodar", function(_, state)
		if state == Enum.UserInputState.Begin then
			held = true
			if not roll() then
				setRunning(true) -- no se pudo rodar (en el aire o muy seguido): solo corre
			end
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			held = false
			setRunning(false)
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonB)
end

return Dodge
