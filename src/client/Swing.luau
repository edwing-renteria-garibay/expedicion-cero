-- Las animaciones del bastón y de rodar, hechas con código (sin subir animaciones a Roblox).
--
-- Un golpe mueve el hombro derecho del personaje (su Motor6D) y la soldadura del bastón:
--   1. preparación: el brazo va rápido a la pose de inicio
--   2. barrido: el brazo pasa a la pose final y el bastón deja una estela
--   3. regreso: el brazo vuelve a su lugar
-- Cada pose es un giro del brazo: "yaw" (hacia los lados, + = izquierda) y "pitch" (hacia
-- arriba: 0 = colgando, 90 = al frente, 180 = arriba de la cabeza).
--
-- Cada cliente anima a todos los personajes (el suyo al momento; los de otros cuando el
-- servidor avisa con Fx), así se ve suave para todos. Funciona con R15 y R6.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Staff = require(ReplicatedStorage.Shared.Config.Staff)
local StaffModel = require(ReplicatedStorage.Shared.StaffModel)

local Swing = {}

type Pose = { yaw: number, pitch: number }

-- Las poses de cada golpe: de dónde a dónde va el brazo
local POSES: { [any]: { from: Pose, to: Pose } } = {
	[1] = { from = { yaw = -80, pitch = 80 }, to = { yaw = 75, pitch = 95 } }, -- de derecha a izquierda
	[2] = { from = { yaw = 75, pitch = 100 }, to = { yaw = -80, pitch = 80 } }, -- de izquierda a derecha
	[3] = { from = { yaw = 0, pitch = 200 }, to = { yaw = 0, pitch = 55 } }, -- de arriba hacia abajo
	Giro = { from = { yaw = -90, pitch = 90 }, to = { yaw = -90, pitch = 90 } }, -- brazo extendido mientras giras
}

-- Partes de la animación (fracción del tiempo total)
local WINDUP = 0.15
local SWEEP_END = 0.6

-- La pose original de cada articulación, antes de que la movamos
local originals: { [Motor6D]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
-- Para cancelar una animación si empieza otra en la misma articulación
local tokens: { [Motor6D]: number } = setmetatable({}, { __mode = "k" }) :: any

local function shoulderOf(character: Model): Motor6D?
	local upper = character:FindFirstChild("RightUpperArm")
	local joint = upper and upper:FindFirstChild("RightShoulder")
	if not joint then
		local torso = character:FindFirstChild("Torso")
		joint = torso and torso:FindFirstChild("Right Shoulder")
	end
	return if joint and joint:IsA("Motor6D") then joint else nil
end

local function rootJointOf(character: Model): Motor6D?
	local lower = character:FindFirstChild("LowerTorso")
	local joint = lower and lower:FindFirstChild("Root")
	if not joint then
		local root = character:FindFirstChild("HumanoidRootPart")
		joint = root and root:FindFirstChild("RootJoint")
	end
	return if joint and joint:IsA("Motor6D") then joint else nil
end

local function staffOf(character: Model): BasePart?
	return character:FindFirstChild("Baston") :: BasePart?
end

-- Gira la articulación en el espacio del torso, sin moverla de su lugar
local function rotated(original: CFrame, rotation: CFrame): CFrame
	return CFrame.new(original.Position) * rotation * original.Rotation
end

local function ease(t: number): number
	return 1 - (1 - t) * (1 - t)
end

local function lerpPose(a: Pose, b: Pose, t: number): Pose
	return { yaw = a.yaw + (b.yaw - a.yaw) * t, pitch = a.pitch + (b.pitch - a.pitch) * t }
end

local function poseRotation(pose: Pose): CFrame
	return CFrame.Angles(0, math.rad(pose.yaw), 0) * CFrame.Angles(math.rad(pose.pitch), 0, 0)
end

-- Corre fn(t) cada cuadro durante "duration" segundos (t de 0 a 1) y al final done()
local function animate(joint: Motor6D, duration: number, fn: (number) -> (), done: () -> ())
	local token = (tokens[joint] or 0) + 1
	tokens[joint] = token
	local start = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if tokens[joint] ~= token or not joint.Parent then
			connection:Disconnect()
			return
		end
		local t = math.min((os.clock() - start) / duration, 1)
		fn(t)
		if t >= 1 then
			connection:Disconnect()
			done()
		end
	end)
end

-- Un golpe del bastón (kind = 1, 2, 3 o "Giro")
function Swing.Play(character: Model, kind: any)
	local attack = Staff.attacks[kind]
	local poses = POSES[kind]
	local joint = shoulderOf(character)
	if not attack or not poses or not joint then
		return
	end
	local original = originals[joint] or joint.C0
	originals[joint] = original
	local staff = staffOf(character)
	local agarre = staff and staff:FindFirstChild("Agarre") :: Weld?
	local hand = if staff then staff:GetAttribute("Mano") :: CFrame? else nil
	hand = hand or CFrame.new()
	local trail = staff and staff:FindFirstChild("Estela") :: Trail?
	local rest: Pose = { yaw = 0, pitch = 0 }

	animate(joint, attack.duration, function(t)
		local pose: Pose
		local extended: number -- 0 = bastón en reposo, 1 = bastón siguiendo el brazo
		if t < WINDUP then
			local k = ease(t / WINDUP)
			pose = lerpPose(rest, poses.from, k)
			extended = k
		elseif t < SWEEP_END then
			pose = lerpPose(poses.from, poses.to, ease((t - WINDUP) / (SWEEP_END - WINDUP)))
			extended = 1
		else
			local k = ease((t - SWEEP_END) / (1 - SWEEP_END))
			pose = lerpPose(poses.to, rest, k)
			extended = 1 - k
		end
		joint.C0 = rotated(original, poseRotation(pose))
		if agarre then
			agarre.C0 = hand * StaffModel.idle:Lerp(StaffModel.swing, extended)
		end
		if trail then
			trail.Enabled = t >= WINDUP * 0.5 and t < SWEEP_END
		end
	end, function()
		joint.C0 = original
		if agarre then
			agarre.C0 = hand * StaffModel.idle
		end
		if trail then
			trail.Enabled = false
		end
	end)
end

-- Rodar: el cuerpo da una vuelta completa hacia adelante
function Swing.Roll(character: Model)
	local joint = rootJointOf(character)
	if not joint then
		return
	end
	local original = originals[joint] or joint.C0
	originals[joint] = original
	local staff = staffOf(character)
	local trail = staff and staff:FindFirstChild("Estela") :: Trail?
	-- En R15 la articulación está en la cadera: bajamos un poco el cuerpo al girar
	animate(joint, Staff.dodge.duration, function(t)
		local angle = -math.pi * 2 * ease(t)
		local dip = math.sin(t * math.pi) * 1.2
		joint.C0 = CFrame.new(0, -dip, 0) * rotated(original, CFrame.Angles(angle, 0, 0))
		if trail then
			trail.Enabled = true
		end
	end, function()
		joint.C0 = original
		if trail then
			trail.Enabled = false
		end
	end)
end

return Swing
