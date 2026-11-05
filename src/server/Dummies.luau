-- Los muñecos de práctica del campo: un poste con un costal y una cabeza de paja.
--
-- Tienen la etiqueta "Enemy" (como los enemigos de verdad que vienen en la semana 2), así el
-- bastón, fijar objetivo y el escaneo de Chispa funcionan igual con ellos. Tienen 200 de vida;
-- al romperse se caen y se vuelven a armar a los pocos segundos.

local CollectionService = game:GetService("CollectionService")

local Dummies = {}

local HEALTH = 200
local RESPAWN = 4

local STRAW = Color3.fromRGB(232, 196, 104)
local SACK = Color3.fromRGB(196, 150, 96)
local POLE = Color3.fromRGB(120, 80, 50)

local function piece(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.Parent = model
	return p
end

-- Barra de vida sobre la cabeza
local function healthBar(head: BasePart, humanoid: Humanoid)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Vida"
	gui.Size = UDim2.fromOffset(90, 12)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 70
	gui.Parent = head
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	back.BorderSizePixel = 0
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 120, 70)
	fill.BorderSizePixel = 0
	fill.Parent = back
	for _, f in { back, fill } do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = f
	end
	humanoid.HealthChanged:Connect(function(health)
		fill.Size = UDim2.fromScale(math.clamp(health / humanoid.MaxHealth, 0, 1), 1)
	end)
end

local function build(spot: Vector3, onBroken: (Model) -> ()): Model
	local model = Instance.new("Model")
	model.Name = "Muñeco"
	-- Mira hacia la entrada del campo (al norte)
	local base = CFrame.lookAt(spot, spot + Vector3.new(0, 0, -1))
	local root = piece(model, "HumanoidRootPart", Vector3.new(2, 2, 1), base * CFrame.new(0, 4, 0), SACK)
	root.Transparency = 1
	root.CanCollide = false
	piece(model, "Poste", Vector3.new(0.8, 6, 0.8), base * CFrame.new(0, 3, 0), POLE)
	piece(model, "Brazos", Vector3.new(5, 0.6, 0.6), base * CFrame.new(0, 5.2, 0), POLE)
	piece(model, "Costal", Vector3.new(2.6, 3, 1.8), base * CFrame.new(0, 4.4, 0), SACK)
	local head =
		piece(model, "Head", Vector3.new(2, 2, 2), base * CFrame.new(0, 7, 0), STRAW, Enum.PartType.Ball)
	-- Una cara pintada
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = HEALTH
	humanoid.Health = HEALTH
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model
	healthBar(head, humanoid)

	model:SetAttribute("Muneco", true)
	CollectionService:AddTag(model, "Enemy")
	model.Parent = workspace

	humanoid.Died:Connect(function()
		CollectionService:RemoveTag(model, "Enemy")
		onBroken(model)
		-- Se cae: todo menos el centro se suelta
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and p ~= root then
				p.Anchored = false
			end
		end
	end)
	return model
end

function Dummies.Start(spots: { Vector3 }, onBroken: (Model) -> ())
	for _, spot in spots do
		local function respawn()
			local dummy = build(spot, onBroken)
			local humanoid = dummy:FindFirstChildOfClass("Humanoid") :: Humanoid
			humanoid.Died:Once(function()
				task.delay(RESPAWN, function()
					dummy:Destroy()
					respawn()
				end)
			end)
		end
		respawn()
	end
end

return Dummies
