-- Lo que el servidor avisa por el remote Fx:
--   "Hit"   (posición, daño)   -> chispas y un número de daño que sube y se desvanece
--   "Swing" (personaje, golpe) -> la animación del golpe de OTRO jugador
--   "Dodge" (personaje)        -> la rodada de otro jugador
--   "Zap"   (jugador, posición) -> el rayito de su Chispa
--   "Say"   (frase)            -> Chispa dice algo (Config/Drone)
--   "Hurt"  (de dónde)         -> te pegaron: la pantalla se pone roja un instante
--   "Dodged"                   -> rodaste a tiempo: "¡Esquivado!"
--   "Crystal" / "Heart"        -> recogiste un cristal o un corazón
--   "Chest" (posición, cristales, corazón) -> abriste un cofre
--   "Block" (posición)         -> tu golpe rebotó en un escudo
--   "Pop"   (posición, color)  -> una bola de óxido reventó
--   "Break" (posición, color, tamaño) -> una máquina del Óxido se rompió en pedazos

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Chispa = require(script.Parent.Chispa)
local Drones = require(script.Parent.Drones)
local Sfx = require(script.Parent.Sfx)
local Swing = require(script.Parent.Swing)

local fx = ReplicatedStorage.Remotes.Fx :: RemoteEvent
local player = Players.LocalPlayer

local Fx = {}

local SPARK = Color3.fromRGB(255, 230, 120)

local folder: Folder

local function damageNumber(position: Vector3, amount: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(math.random() * 2 - 1, 2.5, math.random() * 2 - 1)
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(70, 34)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = tostring(math.floor(amount + 0.5))
	label.TextScaled = true
	label.TextColor3 = if amount >= 30 then Color3.fromRGB(255, 150, 60) else Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = anchor.Position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.75, function()
		anchor:Destroy()
	end)
end

local function sparks(position: Vector3, color: Color3?, count: number?)
	for _ = 1, count or 6 do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Material = Enum.Material.Neon
		p.Color = color or SPARK
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.one * 0.4
		p.Position = position
		p.Parent = folder
		local direction = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		local tween = TweenService:Create(p, TweenInfo.new(0.25), {
			Position = position + direction * 3,
			Size = Vector3.one * 0.05,
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			p:Destroy()
		end)
	end
end

-- Un texto que flota sobre una posición y se desvanece
local function floatText(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(140, 30)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { Position = position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(0.95, function()
		anchor:Destroy()
	end)
end

local function myRoot(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Te pegaron: la orilla de la pantalla se pone roja y la cámara tiembla un poco
local flash: Frame
local function hurt()
	flash.BackgroundTransparency = 0.55
	TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	local camera = workspace.CurrentCamera
	task.spawn(function()
		for i = 1, 6 do
			local strength = (6 - i) * 0.06
			camera.CFrame *= CFrame.new((math.random() - 0.5) * strength, (math.random() - 0.5) * strength, 0)
			task.wait()
		end
	end)
end

-- Una máquina se rompe: pedazos de su color salen volando
local function breakApart(position: Vector3, color: Color3, size: number)
	for _ = 1, 8 do
		local p = Instance.new("Part")
		p.Size = Vector3.new(math.random() + 0.4, math.random() + 0.4, math.random() + 0.4) * size
		p.Color = if math.random() < 0.5 then color else Color3.fromRGB(80, 80, 86)
		p.Material = Enum.Material.CorrodedMetal
		p.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		p.CanCollide = true
		p.CanQuery = false
		p.CanTouch = false
		p.Parent = folder
		p.AssemblyLinearVelocity = Vector3.new(
			math.random() - 0.5,
			math.random() * 0.8 + 0.4,
			math.random() - 0.5
		) * 40
		task.delay(2.5, function()
			TweenService:Create(p, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			task.wait(0.5)
			p:Destroy()
		end)
	end
	sparks(position, Color3.fromRGB(255, 150, 60), 10)
end

function Fx.Start()
	folder = Instance.new("Folder")
	folder.Name = "Efectos"
	folder.Parent = workspace

	local gui = Instance.new("ScreenGui")
	gui.Name = "Dano"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 30, 40)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = gui

	-- Al caer, Chispa te dice algo
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			humanoid.Died:Once(function()
				Chispa.Say("Caida")
			end)
		end
	end)

	fx.OnClientEvent:Connect(function(kind: string, a: any, b: any, c: any)
		if kind == "Hit" and typeof(a) == "Vector3" then
			sparks(a)
			damageNumber(a, b)
			Sfx.Play("hit")
		elseif kind == "Swing" and typeof(a) == "Instance" and a:IsA("Model") then
			Swing.Play(a, b)
		elseif kind == "Dodge" and typeof(a) == "Instance" and a:IsA("Model") then
			Swing.Roll(a)
		elseif kind == "Zap" and typeof(a) == "Instance" and a:IsA("Player") then
			Drones.Zap(a, b)
			if a == Players.LocalPlayer then
				Sfx.Play("zap")
			end
		elseif kind == "Say" then
			Chispa.Say(a)
		elseif kind == "Hurt" then
			hurt()
			Sfx.Play("hurt")
		elseif kind == "Dodged" then
			local root = myRoot()
			if root then
				floatText(root.Position + Vector3.new(0, 3, 0), "¡Esquivado!", Color3.fromRGB(120, 255, 160))
			end
		elseif kind == "Crystal" then
			Sfx.Play("crystal")
		elseif kind == "Heart" then
			Sfx.Play("heart")
			local root = myRoot()
			if root then
				floatText(root.Position + Vector3.new(0, 3, 0), "♥", Color3.fromRGB(255, 70, 90))
			end
		elseif kind == "Chest" and typeof(a) == "Vector3" then
			sparks(a + Vector3.new(0, 2, 0), Color3.fromRGB(255, 220, 90), 14)
			Sfx.Play("chest")
			Chispa.Say("Cofre", b)
			if c then
				Chispa.Say("CofreCorazon")
			end
		elseif kind == "Block" and typeof(a) == "Vector3" then
			sparks(a, Color3.fromRGB(200, 230, 255), 8)
			floatText(a + Vector3.new(0, 2, 0), "¡Bloqueado!", Color3.fromRGB(200, 230, 255))
			Sfx.Play("block")
		elseif kind == "Pop" and typeof(a) == "Vector3" then
			sparks(a, b, 8)
		elseif kind == "Break" and typeof(a) == "Vector3" then
			breakApart(a, b, c or 1)
			Sfx.Play("breakEnemy")
		end
	end)
end

return Fx
