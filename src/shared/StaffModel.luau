-- El modelo del bastón de energía y cómo se agarra.
--
-- El servidor lo arma y lo pega a la mano derecha de cada personaje con una soldadura
-- (Weld "Agarre"), así todos lo ven. Cada cliente mueve esa soldadura para animar los golpes
-- (src/client/Swing.luau): en reposo el bastón apunta hacia adelante y arriba; al golpear se
-- extiende siguiendo el brazo.
--
-- Funciona con avatares R15 (RightHand) y R6 (Right Arm).

local StaffModel = {}

local LENGTH = 6
local SHAFT = Color3.fromRGB(120, 78, 160)
local BANDS = Color3.fromRGB(250, 210, 90)
local CRYSTAL = Color3.fromRGB(110, 230, 255)
local GOLD = Color3.fromRGB(255, 205, 70) -- el cristal con el pase VIP

-- Dónde se agarra el bastón (un poco abajo de su centro: sobresale más hacia adelante)
local GRIP = CFrame.new(0, -1.2, 0)

-- Cómo queda en la mano: en reposo (hacia adelante y arriba) y al golpear (siguiendo el brazo)
StaffModel.idle = CFrame.Angles(math.rad(-60), 0, 0)
StaffModel.swing = CFrame.Angles(math.rad(180), 0, 0)

local function piece(
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
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	return p
end

local function weld(to: BasePart, p: BasePart, offset: CFrame)
	p.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = p
	w.Parent = p
	p.Parent = to
end

-- Arma el bastón: una vara con bandas doradas y un cristal brillante en la punta
function StaffModel.Build(): BasePart
	local shaft = piece("Baston", Vector3.new(0.35, LENGTH, 0.35), SHAFT)
	for _, y in { -1.4, 1.6 } do
		weld(shaft, piece("Banda", Vector3.new(0.5, 0.3, 0.5), BANDS), CFrame.new(0, y, 0))
	end
	-- Una horquilla que sostiene el cristal
	for _, side in { -1, 1 } do
		weld(
			shaft,
			piece("Horquilla", Vector3.new(0.2, 1.2, 0.2), BANDS),
			CFrame.new(side * 0.4, LENGTH / 2 + 0.3, 0) * CFrame.Angles(0, 0, math.rad(-20 * side))
		)
	end
	local crystal = piece("Cristal", Vector3.new(0.7, 1.3, 0.7), CRYSTAL, Enum.Material.Neon)
	weld(shaft, crystal, CFrame.new(0, LENGTH / 2 + 0.7, 0) * CFrame.Angles(0, math.rad(45), 0))
	local light = Instance.new("PointLight")
	light.Color = CRYSTAL
	light.Range = 8
	light.Brightness = 1.2
	light.Parent = crystal

	-- La estela que deja al golpear (el cliente la prende)
	local tip = Instance.new("Attachment")
	tip.Name = "Punta"
	tip.Position = Vector3.new(0, LENGTH / 2 + 0.6, 0)
	tip.Parent = shaft
	local base = Instance.new("Attachment")
	base.Name = "Base"
	base.Position = Vector3.new(0, 0, 0)
	base.Parent = shaft
	local trail = Instance.new("Trail")
	trail.Name = "Estela"
	trail.Attachment0 = base
	trail.Attachment1 = tip
	trail.Color = ColorSequence.new(CRYSTAL, Color3.new(1, 1, 1))
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.18
	trail.LightEmission = 0.8
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = shaft
	return shaft
end

-- La mano derecha del personaje (R15 o R6)
function StaffModel.Hand(character: Model): BasePart?
	return (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
end

-- Pega el bastón a la mano derecha
function StaffModel.Attach(character: Model, staff: BasePart)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	local r6 = humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R6
	local hand = character:WaitForChild(if r6 then "Right Arm" else "RightHand", 5)
	if not hand or not hand:IsA("BasePart") then
		staff:Destroy()
		return
	end
	-- En R6 el brazo es largo: la mano está en la punta de abajo
	local handOffset = if hand.Name == "Right Arm" then CFrame.new(0, -1, 0) else CFrame.new()
	local agarre = Instance.new("Weld")
	agarre.Name = "Agarre"
	agarre.Part0 = hand
	agarre.Part1 = staff
	agarre.C0 = handOffset * StaffModel.idle
	agarre.C1 = GRIP
	agarre.Parent = staff
	staff:SetAttribute("Mano", handOffset)
	staff.Parent = character
end

-- Pinta el cristal (y su luz y su estela) de dorado con el pase VIP, o de azul sin él
function StaffModel.Paint(staff: Instance, vip: boolean)
	local color = if vip then GOLD else CRYSTAL
	local crystal = staff:FindFirstChild("Cristal", true)
	if crystal and crystal:IsA("BasePart") then
		crystal.Color = color
		local light = crystal:FindFirstChildOfClass("PointLight")
		if light then
			light.Color = color
		end
	end
	local trail = staff:FindFirstChild("Estela", true)
	if trail and trail:IsA("Trail") then
		trail.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	end
end

return StaffModel
