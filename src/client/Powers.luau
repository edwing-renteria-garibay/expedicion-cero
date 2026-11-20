-- Los poderes del bastón en tu pantalla (Config/Powers). Por ahora, el Empuje:
-- E (o L2 en control, o el botón "Empuje" en celular). Solo funciona si ya lo ganaste
-- (atributo "Empuje" del jugador, que pone el servidor al abrir el gran cofre del templo).
--
-- Tu pantalla anima la estocada al momento y le avisa al servidor (remote Power), que mueve
-- bloques, rompe paredes agrietadas y tumba al jefe.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Powers = require(ReplicatedStorage.Shared.Config.Powers)
local Actions = require(script.Parent.Actions)
local LockOn = require(script.Parent.LockOn)
local Sfx = require(script.Parent.Sfx)
local Swing = require(script.Parent.Swing)

local powerRemote = ReplicatedStorage.Remotes.Power :: RemoteEvent
local player = Players.LocalPlayer

local PowersClient = {}

local last = -math.huge

local function push()
	if not player:GetAttribute("Empuje") then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	local now = os.clock()
	if now - last < Powers.Empuje.cooldown then
		return
	end
	last = now
	-- Hacia el enemigo fijado o hacia donde mira la cámara
	local target = LockOn.Target()
	local look = if target then target.Position - root.Position else workspace.CurrentCamera.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	look = if look.Magnitude > 0.1 then look.Unit else root.CFrame.LookVector
	root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
	powerRemote:FireServer("Empuje", look)
	Swing.Play(character, "Empuje")
	Sfx.Play("push", root)
end

-- ¿Ya está listo otra vez? (de 0 a 1, para el botón de celular)
function PowersClient.Ready(): number
	return math.clamp((os.clock() - last) / Powers.Empuje.cooldown, 0, 1)
end

function PowersClient.Start()
	Actions.Bind("Empuje", function(_, state)
		if state == Enum.UserInputState.Begin then
			push()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonL2)
end

return PowersClient
