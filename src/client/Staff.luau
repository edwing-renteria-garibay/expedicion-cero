-- El bastón en tu pantalla: clic para golpear, el combo de 3 golpes y el giro cargado.
--
--   * Clic (o R2 en control): golpe. Si vuelves a hacer clic justo al terminar, sigue el
--     combo: golpe 1, golpe 2 y el remate de arriba hacia abajo.
--   * Si haces clic mientras todavía estás golpeando, el siguiente golpe sale solo al terminar.
--   * Mantén el clic: el cristal del bastón brilla cuando el giro está cargado; suelta y das
--     una vuelta completa que pega a todo lo de alrededor.
--   * Golpeas hacia donde mira la cámara, o hacia el enemigo fijado (F).
--
-- Tu pantalla anima el golpe al momento y le avisa al servidor (remote Attack), que decide a
-- quién le pegaste. Los números de cada golpe están en Config/Staff.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Staff = require(ReplicatedStorage.Shared.Config.Staff)
local Actions = require(script.Parent.Actions)
local LockOn = require(script.Parent.LockOn)
local Sfx = require(script.Parent.Sfx)
local Swing = require(script.Parent.Swing)

local attackRemote = ReplicatedStorage.Remotes.Attack :: RemoteEvent
local player = Players.LocalPlayer

local StaffClient = {}

local busyUntil = 0 -- hasta cuándo dura el golpe actual
local lastEnd = 0 -- cuándo terminó (o termina) el último golpe
local step = 0 -- en qué golpe del combo vas
local buffered = false -- hiciste clic mientras golpeabas
local holding = false
local holdStart = 0
local charged = false

local function alive(): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil, nil
	end
	return character, humanoid, root
end

-- Hacia dónde golpear: al enemigo fijado o hacia donde mira la cámara
local function aimDirection(root: BasePart): Vector3
	local target = LockOn.Target()
	local look
	if target then
		look = target.Position - root.Position
	else
		look = workspace.CurrentCamera.CFrame.LookVector
	end
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.1 then
		return root.CFrame.LookVector
	end
	return look.Unit
end

-- El cristal del bastón brilla cuando el giro está cargado
local function glow(on: boolean)
	local character = player.Character
	local staff = character and character:FindFirstChild("Baston")
	local crystal = staff and staff:FindFirstChild("Cristal") :: BasePart?
	if not crystal then
		return
	end
	local light = crystal:FindFirstChildOfClass("PointLight")
	if light then
		light.Brightness = if on then 5 else 1.2
		light.Range = if on then 14 else 8
	end
	crystal.Size = if on then Vector3.new(1, 1.8, 1) else Vector3.new(0.7, 1.3, 0.7)
end

local tryAttack: () -> ()

local function attack(kind: any)
	local character, humanoid, root = alive()
	if not character or not humanoid or not root then
		return
	end
	local info = Staff.attacks[kind]
	local look = aimDirection(root)
	-- Voltea al personaje hacia donde golpea
	root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
	attackRemote:FireServer(kind, look)
	Swing.Play(character, kind)
	Sfx.Play(if kind == "Giro" then "spin" else "swing", root)

	local now = os.clock()
	busyUntil = now + info.duration
	lastEnd = busyUntil

	if kind == "Giro" then
		-- Una vuelta completa
		LockOn.hold = true
		humanoid.AutoRotate = false
		local start = os.clock()
		local base = root.CFrame.Rotation
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local t = math.min((os.clock() - start) / info.duration, 1)
			if not root.Parent then
				connection:Disconnect()
				return
			end
			root.CFrame = CFrame.new(root.Position) * base * CFrame.Angles(0, -math.pi * 2 * t, 0)
			if t >= 1 then
				connection:Disconnect()
				humanoid.AutoRotate = LockOn.Target() == nil
				LockOn.hold = false
			end
		end)
	end

	task.delay(info.duration, function()
		if buffered then
			buffered = false
			tryAttack()
		end
	end)
end

tryAttack = function()
	local now = os.clock()
	if now < busyUntil then
		buffered = true
		return
	end
	if step < 3 and now - lastEnd <= Staff.comboWindow then
		step += 1
	else
		step = 1
	end
	attack(step)
end

local function releaseCharge()
	-- Espera a que termine el golpe que está en curso y luego gira
	local wait = math.max(busyUntil - os.clock(), 0)
	buffered = false
	task.delay(wait, function()
		step = 0
		attack("Giro")
	end)
end

local function onAttackInput(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		if not alive() then
			return Enum.ContextActionResult.Pass
		end
		holding = true
		holdStart = os.clock()
		charged = false
		tryAttack()
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		if holding and charged and state == Enum.UserInputState.End then
			releaseCharge()
		end
		holding = false
		charged = false
		glow(false)
	end
	return Enum.ContextActionResult.Pass -- deja que la cámara siga usando el clic
end

-- ¿Estás golpeando ahora? (para que rodar espere)
function StaffClient.Busy(): boolean
	return os.clock() < busyUntil
end

function StaffClient.Start()
	Actions.Bind("Atacar", onAttackInput, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	RunService.RenderStepped:Connect(function()
		if holding and not charged and os.clock() - holdStart >= Staff.chargeTime then
			charged = true
			glow(true)
			Sfx.Play("charged")
		end
	end)
	player.CharacterAdded:Connect(function()
		holding = false
		charged = false
		buffered = false
		step = 0
		busyUntil = 0
	end)
end

return StaffClient
